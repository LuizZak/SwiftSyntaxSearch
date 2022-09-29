import SwiftSyntax

public struct SyntaxSearchTerm<T: SyntaxProtocol> {
    fileprivate var _conditions: [WrappedCondition] = []
    
    fileprivate init(condition: @escaping (T) -> Bool) {
        self.init(_conditions: [
            .init(closure: condition)
        ])
    }

    public init() {
        self.init(_conditions: [])
    }

    fileprivate init(_conditions: [SyntaxSearchTerm<T>.WrappedCondition]) {
        self._conditions = _conditions
    }

    public func matches(_ syntax: SyntaxProtocol?) -> Bool {
        guard let syntax = syntax?.asSyntax.as(T.self) else {
            return false
        }

        return _conditions.allSatisfy { $0.matches(syntax) }
    }

    public func add(_ keyPath: KeyPath<T, TokenSyntax?>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            if let text = $0[keyPath: keyPath]?.text {
                return matcher.matches(text)
            }

            return false
        }
        
        copy._conditions.append(condition)

        return copy
    }

    public func add(_ keyPath: KeyPath<T, TokenSyntax>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath].text)
        }
        
        copy._conditions.append(condition)

        return copy
    }

    public func addSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U?>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    public func addSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    public func anyChild<U: SyntaxProtocol>(_ matches: SyntaxSearchTerm<U>) -> Self {
        .init { s in
            return s.contains(matches)
        }
    }

    fileprivate struct WrappedCondition {
        private let _closure: (T) -> Bool

        init(closure: @escaping (T) -> Bool) {
            self._closure = closure
        }

        func matches(_ syntax: T) -> Bool {
            _closure(syntax)
        }
    }
}

public extension SyntaxSearchTerm {
    /// Matches no syntax item.
    static var none: Self {
        .init(condition: { _ in false })
    }

    /// Matches any syntax items.
    static var any: Self {
        .init(condition: { _ in true })
    }

    /// Recursively searches a syntax tree looking for the first syntax object
    /// that matches a given search term.
    ///
    /// Search is performed in breadth-first order.
    static func anyChildRecursive<U: SyntaxProtocol>(_ matches: SyntaxSearchTerm<U>) -> Self {
        .init { s in
            return s.contains(matches)
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
}

public extension SyntaxSearchTerm where T: SyntaxCollection {
    static var isEmpty: Self {
        .init(condition: { $0.count == 0 })
    }

    static func count(is expected: Int) -> Self {
        Self {
            $0.count == expected
        }
    }

    static func allSatisfy(_ matcher: SyntaxSearchTerm<T.Element>) -> Self where T.Element: SyntaxProtocol {
        .init(condition: {
            $0.allSatisfy(matcher.matches)
        })
    }

    static func allSatisfy(_ condition: @escaping (T) -> Bool) -> Self where T.Element: SyntaxProtocol {
        .init(condition: condition)
    }
}

public extension SyntaxProtocol {
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

// MARK: - Concrete helper extensions

public extension SyntaxSearchTerm where T == IdentifierPatternSyntax {
    static func `is`(_ text: StringMatcher) -> Self {
        .init().add(\.identifier, text)
    }
}

public extension SyntaxProtocol {
    static var search: SyntaxSearchTerm<Self>.Type {
        SyntaxSearchTerm<Self>.self
    }
}
