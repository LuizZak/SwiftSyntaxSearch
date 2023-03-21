import SwiftSyntax

/// Struct that can be used to perform searches and pattern-matching across complex
/// SwiftSyntax `SyntaxProtocol` trees.
public struct SyntaxSearchTerm<T: SyntaxProtocol> {
    internal var _conditions: [WrappedCondition] = []
    
    internal init(condition: @escaping (SyntaxProtocol?) -> Bool) {
        self.init(_conditions: [
            .init(closure: condition)
        ])
    }

    /// Initializes an empty matcher.
    ///
    /// Empty matchers match true for any value that is passed in, as long as
    /// their type matches `T`.
    public init() {
        self.init(_conditions: [])
    }

    internal init(_conditions: [WrappedCondition]) {
        self._conditions = _conditions
    }

    /// Returns whether a given syntax protocol type is of type `T`, and all
    /// conditions associated with this search term are fulfilled.
    public func matches(_ syntax: SyntaxProtocol?) -> Bool {
        guard let syntax = syntax?.asSyntax, syntax.is(T.self) else {
            return false
        }

        return _conditions.allSatisfy { $0.matches(syntax) }
    }

    /// Appends the list of conditions from another search term into this term,
    /// returning a new syntax search term that matches when both underlying search
    /// terms match.
    public func and(_ other: Self) -> Self {
        Self.init(_conditions: _conditions + other._conditions)
    }

    /// Returns a copy of this search term with a new `and` condition added.
    public func and(_ keyPath: KeyPath<T, String>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            guard let node = $0?.castTo(T.self) else { return false }

            return matcher.matches(node[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added.
    public func and(_ keyPath: KeyPath<T, String?>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            guard let node = $0?.castTo(T.self) else { return false }

            guard let text = node[keyPath: keyPath] else {
                return false
            }

            return matcher.matches(text)
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added.
    public func and(_ keyPath: KeyPath<T, TokenSyntax>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            guard let node = $0?.castTo(T.self) else { return false }

            return matcher.matches(node[keyPath: keyPath].text)
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added.
    public func and(_ keyPath: KeyPath<T, TokenSyntax?>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            guard let node = $0?.castTo(T.self) else { return false }

            if let text = node[keyPath: keyPath]?.text {
                return matcher.matches(text)
            }

            return false
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added that
    /// matches deeper into the syntax tree.
    public func andSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            let node = $0?.castTo(T.self)

            return matcher.matches(node?[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added that
    /// matches deeper into the syntax tree.
    public func andSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U?>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            let node = $0?.castTo(T.self)

            return matcher.matches(node?[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added that
    /// matches the parent of the syntax object that is matched by this search
    /// term.
    public func andParent<U: SyntaxProtocol>(_ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            let node = $0?.castTo(T.self)

            return matcher.matches(node?.parent)
        }
        
        copy._conditions.append(condition)

        return copy
    }

    /// Returns a copy of this search term with a new `and` condition added that
    /// matches if any ancestor of the syntax object that is matched by this
    /// search term matches `matcher`.
    ///
    /// Search is done from the node's parent until it hits the root of the syntax
    /// tree.
    public func andAnyAncestor<U: SyntaxProtocol>(_ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            let node = $0?.castTo(T.self)

            var parent = node?.parent
            while let p = parent {
                if matcher.matches(p) {
                    return true
                }

                parent = p.parent
            }

            return false
        }
        
        copy._conditions.append(condition)

        return copy
    }
}

internal struct WrappedCondition {
    private let _closure: (SyntaxProtocol?) -> Bool

    init(closure: @escaping (SyntaxProtocol?) -> Bool) {
        self._closure = closure
    }

    func matches(_ syntax: SyntaxProtocol?) -> Bool {
        _closure(syntax)
    }
}

public extension SyntaxSearchTerm {
    /// Matches no syntax item.
    static var none: Self {
        .init(condition: { _ in false })
    }

    /// Matches any syntax item.
    static var any: Self {
        .init(condition: { node in node?.castTo(T.self) != nil })
    }

    /// Matches `nil` syntax nodes.
    static var isNil: Self {
        .init(condition: { node in node == nil })
    }

    /// Matches non-`nil` syntax nodes.
    static var isNonNil: Self {
        .init(condition: { node in node != nil })
    }

    /// Recursively searches a syntax tree looking for the first syntax object
    /// that matches a given search term.
    ///
    /// Search is performed in breadth-first order.
    static func anyChildRecursive<U: SyntaxProtocol>(_ matches: SyntaxSearchTerm<U>) -> Self {
        .init { s in
            return s?.contains(matches) ?? false
        }
    }

    /// Matches if any of the provided matchers match.
    ///
    /// Empty matcher list results in no matches, like `Self.none`.
    static func or(_ matchers: [Self]) -> Self {
        if matchers.isEmpty {
            return .none
        }

        return .init { syntax in
            matchers.contains { $0.matches(syntax) }
        }
    }

    /// Matches iff all of the provided matchers match.
    ///
    /// Empty matcher list results in no matches, like `Self.none`.
    static func and(_ matchers: [Self]) -> Self {
        if matchers.isEmpty {
            return .none
        }

        return .init { syntax in
            matchers.allSatisfy { $0.matches(syntax) }
        }
    }

    /// Inverts the result of this matcher.
    var not: Self {
        .init(condition: { !self.matches($0) })
    }

    /// Returns a new matcher that matches a string at a given keypath with a
    /// specified string matcher.
    static func string(_ keyPath: KeyPath<T, String>, matches matcher: StringMatcher) -> Self {
        .init().and(keyPath, matcher)
    }

    /// Returns a new matcher that matches a string at a given keypath with a
    /// specified string matcher.
    static func string(_ keyPath: KeyPath<T, String?>, matches matcher: StringMatcher) -> Self {
        .init().and(keyPath, matcher)
    }

    /// Returns a new matcher that matches a token at a given keypath with a
    /// specified string matcher.
    static func token(_ keyPath: KeyPath<T, TokenSyntax>, matches matcher: StringMatcher) -> Self {
        .init().and(keyPath, matcher)
    }

    /// Returns a new matcher that matches a token at a given keypath with a
    /// specified string matcher.
    ///
    /// If the token is `nil`, the matcher returns false.
    static func token(_ keyPath: KeyPath<T, TokenSyntax?>, matches matcher: StringMatcher) -> Self {
        .init().and(keyPath, matcher)
    }

    /// Returns a new matcher that matches a child at a given keypath with a
    /// specified matcher.
    ///
    /// If the child is `nil`, the matcher returns false.
    static func child<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U>, matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andSub(keyPath, matcher)
    }

    /// Returns a new matcher that matches a child at a given keypath with a
    /// specified matcher.
    ///
    /// If the child is `nil`, the matcher returns false.
    static func child<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U?>, matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andSub(keyPath, matcher)
    }

    /// Returns a new matcher that matches a child at a given keypath with a
    /// specified matcher, casting the node to a specified type before performing
    /// the matching.
    static func child<U: SyntaxProtocol, W: SyntaxProtocol>(_ keyPath: KeyPath<T, W>, castTo type: U.Type, matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andSub(keyPath, .init(condition: { syntax in
            matcher.matches(syntax?.asSyntax.as(U.self))
        }))
    }

    /// Returns a new matcher that matches a child at a given keypath with a
    /// specified matcher, casting the node to a specified type before performing
    /// the matching.
    static func child<U: SyntaxProtocol, W: SyntaxProtocol>(_ keyPath: KeyPath<T, W?>, castTo type: U.Type, matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andSub(keyPath, .init(condition: { syntax in
            matcher.matches(syntax?.asSyntax.as(U.self))
        }))
    }

    /// Returns a new matcher that matches a node by matching its parent with a
    /// specified matcher.
    ///
    /// If the parent is `nil`, the matcher returns false.
    static func parent<U: SyntaxProtocol>(matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andParent(matcher)
    }

    /// Returns a new matcher that matches a node by matching its ancestors with
    /// a specified matcher. The matcher recursively traverses the syntax tree
    /// until the root is reached, and returns `true` on the first ancestor that
    /// matches `matcher`.
    ///
    /// If the parent is `nil`, the matcher returns false.
    static func anyAncestor<U: SyntaxProtocol>(matches matcher: SyntaxSearchTerm<U>) -> Self {
        .init().andAnyAncestor(matcher)
    }

    /// Returns a copy of this matcher with an extra matching requirement for
    /// a child at a given keypath with a specified matcher.
    func child<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U>, matches matcher: SyntaxSearchTerm<U>) -> Self {
        andSub(keyPath, matcher)
    }

    /// Returns a copy of this matcher with an extra matching requirement for
    /// a child at a given keypath with a specified matcher.
    func child<U: SyntaxProtocol, W: SyntaxProtocol>(_ keyPath: KeyPath<T, W>, castTo type: U.Type, matches matcher: SyntaxSearchTerm<U>) -> Self {
        andSub(keyPath, .init(condition: { syntax in
            matcher.matches(syntax?.asSyntax.as(U.self))
        }))
    }

    /// Returns a copy of this matcher with an extra matching requirement for
    /// a child at a given keypath with a specified matcher.
    func child<U: SyntaxProtocol, W: SyntaxProtocol>(_ keyPath: KeyPath<T, W?>, castTo type: U.Type, matches matcher: SyntaxSearchTerm<U>) -> Self {
        andSub(keyPath, .init(condition: { syntax in
            matcher.matches(syntax?.asSyntax.as(U.self))
        }))
    }
}

public extension SyntaxSearchTerm where T: SyntaxCollection {
    static var isEmpty: Self {
        .init(condition: { $0?.castTo(T.self)?.count == 0 })
    }

    static func count(is expected: Int) -> Self {
        Self {
            $0?.castTo(T.self)?.count == expected
        }
    }

    static func allSatisfy(_ matcher: SyntaxSearchTerm<T.Element>) -> Self where T.Element: SyntaxProtocol {
        .init(condition: {
            $0?.castTo(T.self)?.allSatisfy(matcher.matches) ?? false
        })
    }

    static func allSatisfy(_ condition: @escaping (SyntaxProtocol?) -> Bool) -> Self where T.Element: SyntaxProtocol {
        .init(condition: condition)
    }
}

public extension SyntaxProtocol {
    internal func castTo<T: SyntaxProtocol>(_ type: T.Type = T.self) -> T? {
        Syntax(self).as(type)
    }

    /// Returns `true` if any child syntax node within this syntax object matches
    /// the given search term.
    ///
    /// Lookup is done in breadth-first order.
    func contains<U>(_ search: SyntaxSearchTerm<U>) -> Bool {
        findRecursive(search) != nil
    }

    /// Returns the first syntax descendant from this syntax object that matches
    /// a given search term.
    ///
    /// Lookup is done in breadth-first order.
    func findRecursive<U>(_ search: SyntaxSearchTerm<U>) -> U? {
        var queue: [SyntaxProtocol] = [self]

        while !queue.isEmpty {
            let next = queue.removeFirst()

            if search.matches(next) {
                return Syntax(next).as(U.self)
            }

            for child in next.children {
                queue.append(child)
            }
        }

        return nil
    }

    /// Returns all of the syntax descendants from this syntax object that
    /// match a given search term.
    ///
    /// Lookup is done in breadth-first order.
    func findAllBreadthFirst<U>(_ search: SyntaxSearchTerm<U>) -> [U] {
        var result: [U] = []

        var queue: [SyntaxProtocol] = [self]

        while !queue.isEmpty {
            let next = queue.removeFirst()

            if search.matches(next), let cast = Syntax(next).as(U.self) {
                result.append(cast)
            }

            for child in next.children {
                queue.append(child)
            }
        }

        return result
    }

    /// Returns all of the syntax descendants from this syntax object that
    /// match a given search term.
    ///
    /// Lookup is done in depth-first order.
    func findAllDepthFirst<U>(_ search: SyntaxSearchTerm<U>) -> [U] {
        var result: [U] = []

        var stack: [SyntaxProtocol] = [self]

        while let next = stack.popLast() {
            if search.matches(next), let cast = Syntax(next).as(U.self) {
                result.append(cast)
            }

            for child in next.children.reversed() {
                stack.append(child)
            }
        }

        return result
    }
}

public extension SyntaxCollection {
    func firstIndex<U>(matching search: SyntaxSearchTerm<U>) -> Int? where Element: SyntaxProtocol {
        for (i, syntax) in self.enumerated() {
            if search.matches(syntax) {
                return i
            }
        }

        return nil
    }
}

// MARK: - Property/subscript indexers

public extension SyntaxCollection where Self: Collection {
    /// Returns the result of indexing into this syntax collection by offsetting
    /// `self.startIndex` by `index` before indexing into the underlying collection.
    subscript(index index: Int) -> Element {
        let i = self.index(startIndex, offsetBy: index)

        return self[i]
    }
}

// MARK: - Concrete helper extensions

public extension SyntaxSearchTerm where T == IdentifierPatternSyntax {
    static func `is`(_ text: StringMatcher) -> Self {
        T.search.and(\.identifier, text)
    }
}

public extension SyntaxProtocol {
    /// Returns an empty search term for this syntax protocol implementer.
    static var search: SyntaxSearchTerm<Self> {
        SyntaxSearchTerm<Self>()
    }
}
