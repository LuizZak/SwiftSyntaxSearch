import SwiftSyntax

struct SyntaxSearchTerm<T: SyntaxProtocol> {
    fileprivate var _conditions: [WrappedCondition] = []
    
    fileprivate init(condition: @escaping (T) -> Bool) {
        self.init(_conditions: [
            .init(closure: condition)
        ])
    }

    init() {
        self.init(_conditions: [])
    }

    fileprivate init(_conditions: [SyntaxSearchTerm<T>.WrappedCondition]) {
        self._conditions = _conditions
    }

    func matches(_ syntax: SyntaxProtocol?) -> Bool {
        guard let syntax = syntax?.asSyntax.as(T.self) else {
            return false
        }

        return _conditions.allSatisfy { $0.matches(syntax) }
    }

    func add(_ keyPath: KeyPath<T, TokenSyntax?>, _ matcher: StringMatcher) -> Self {
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

    func add(_ keyPath: KeyPath<T, TokenSyntax>, _ matcher: StringMatcher) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath].text)
        }
        
        copy._conditions.append(condition)

        return copy
    }

    func addSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U?>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    func addSub<U: SyntaxProtocol>(_ keyPath: KeyPath<T, U>, _ matcher: SyntaxSearchTerm<U>) -> Self {
        var copy = self
        let condition = WrappedCondition {
            matcher.matches($0[keyPath: keyPath])
        }
        
        copy._conditions.append(condition)

        return copy
    }

    func anyChild<U: SyntaxProtocol>(_ matches: SyntaxSearchTerm<U>) -> Self {
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

extension SyntaxSearchTerm {
    /// Matches no term
    static var none: Self {
        .init(condition: { _ in false })
    }

    /// Matches all terms
    static var all: Self {
        .init(condition: { _ in true })
    }

    /// Inverts the result of this matcher
    var not: Self {
        .init(condition: { !self.matches($0) })
    }

    static func anyChild<U: SyntaxProtocol>(_ matches: SyntaxSearchTerm<U>) -> Self {
        .init { s in
            return s.contains(matches)
        }
    }
}

extension SyntaxSearchTerm where T: SyntaxCollection {
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

extension SyntaxProtocol {
    /// Returns `true` if any child syntax node within this syntax object matches
    /// the given search term.
    ///
    /// Lookup is done in breadth-first order.
    func contains<U>(_ search: SyntaxSearchTerm<U>) -> Bool {
        findRecursive(search) != nil
    }

    /// Returns the first syntax child that matches a given search term.
    ///
    /// Lookup is done in breadth-first order.
    func findRecursive<U>(_ search: SyntaxSearchTerm<U>) -> Syntax? {
        var queue: [SyntaxProtocol] = [self]

        while !queue.isEmpty {
            let next = queue.removeFirst()

            if search.matches(next) {
                return Syntax(next)
            }

            for child in next.children {
                queue.append(child)
            }
        }

        return nil
    }
}

extension SyntaxCollection {
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

extension SyntaxSearchTerm where T == IdentifierPatternSyntax {
    static func `is`(_ text: StringMatcher) -> Self {
        .init().add(\.identifier, text)
    }
}

extension IdentifierPatternSyntax {
    static var search = SyntaxSearchTerm<IdentifierPatternSyntax>.self
}
