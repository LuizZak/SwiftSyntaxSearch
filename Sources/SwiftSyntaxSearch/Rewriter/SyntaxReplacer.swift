import SwiftSyntax

/// Struct that can be used to perform search and replacement of syntax nodes
/// across complex SwiftSyntax `SyntaxProtocol` trees.
public struct SyntaxReplacer<T: SyntaxProtocol> {
    private let replacer: (T) -> T
    
    public let searchTerm: SyntaxSearchTerm<T>

    public init(searchTerm: SyntaxSearchTerm<T>, replacement: T) {
        self.init(searchTerm: searchTerm) { _ in
            replacement
        }
    }

    public init(searchTerm: SyntaxSearchTerm<T>, replacer: @escaping (T) -> T) {
        self.searchTerm = searchTerm
        self.replacer = replacer
    }

    /// If the given note matches the search term associated with this syntax
    /// replacer, the replacer closure is invoked to suggest a replacement
    /// syntax node.
    public func matchAndReplace<U: SyntaxProtocol>(_ node: U) -> T? {
        guard let node = Syntax(node).as(T.self) else { return nil }
        guard searchTerm.matches(node) else { return nil }

        return replacer(node)
    }
}

public extension SyntaxProtocol {
    /// Finds and replaces all syntax nodes that match a specified syntax
    /// replacer's search term with its `replacer` result.
    func replacingAll<T>(_ search: SyntaxReplacer<T>) -> Self {
        let rewriter = SyntaxTermRewriter(replacer: search)

        return rewriter.visit(Syntax(self)).as(Self.self) ?? self
    }
}
