import SwiftSyntax

public extension KeyPath where Root: SyntaxProtocol {
    func matches(_ matcher: SyntaxSearchTerm<Value>) -> SyntaxSearchTerm<Root> where Value: SyntaxProtocol {
        SyntaxSearchTerm<Root>.child(self, matches: matcher)
    }

    func matches<V: SyntaxProtocol>(_ matcher: SyntaxSearchTerm<V>) -> SyntaxSearchTerm<Root> where Value == V? {
        SyntaxSearchTerm<Root>.child(self, matches: matcher)
    }

    func matches<V: SyntaxProtocol>(as type: V.Type, _ matcher: SyntaxSearchTerm<V>) -> SyntaxSearchTerm<Root> where Value: SyntaxProtocol {
        SyntaxSearchTerm<Root>.child(self, castTo: V.self, matches: matcher)
    }

    func matches<V: SyntaxProtocol, W: SyntaxProtocol>(as type: V.Type, _ matcher: SyntaxSearchTerm<V>) -> SyntaxSearchTerm<Root> where Value == W? {
        SyntaxSearchTerm<Root>.child(self, castTo: V.self, matches: matcher)
    }
}

public extension KeyPath where Root: SyntaxProtocol, Value == TokenSyntax {
    static func == (lhs: KeyPath, rhs: StringMatcher) -> SyntaxSearchTerm<Root> {
        SyntaxSearchTerm<Root>.token(lhs, matches: rhs)
    }
}
