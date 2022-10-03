import SwiftSyntax

/// Struct that can be used to perform search and removal of syntax nodes across
/// complex SwiftSyntax `SyntaxProtocol` trees.
public struct SyntaxRemover<T: SyntaxProtocol> {
    public let searchTerm: SyntaxSearchTerm<T>

    public init(searchTerm: SyntaxSearchTerm<T>) {
        self.searchTerm = searchTerm
    }

    /// If the given note matches the search term associated with this syntax
    /// replacer, the replacer closure is invoked to suggest a replacement
    /// syntax node.
    public func matchAndRemove(_ node: T) -> T? {
        guard let node = Syntax(node).as(T.self) else { return nil }
        guard searchTerm.matches(node) else { return nil }

        return node.removingAll(self)
    }
}

public extension SyntaxProtocol {
    /// Finds and replaces all syntax nodes that match a specified syntax
    /// replacer's search term with its `replacer` result.
    func removingAll<T>(_ search: SyntaxRemover<T>) -> Self {
        var entries: [SyntaxTermRemover.Entry] = []

        for node in self.findAllBreadthFirst(search.searchTerm) {
            // Traverse the parents until a suitable `SyntaxCollection` is found
            guard let (collection, child) = node.firstCollectionParent() else {
                continue
            }

            entries.append((collection.id, child.indexInParent))
        }

        guard !entries.isEmpty else {
            return self
        }

        let rewriter = SyntaxTermRemover(toRemove: entries)

        return rewriter.visit(Syntax(self)).as(Self.self) ?? self
    }

    private func firstCollectionParent() -> (any SyntaxProtocol, child: SyntaxProtocol)? {
        var node: SyntaxProtocol = self
        while let parent = node.parent {
            if parent.isCollection {
                return (parent, node)
            }

            node = parent
        }

        return nil
    }
}
