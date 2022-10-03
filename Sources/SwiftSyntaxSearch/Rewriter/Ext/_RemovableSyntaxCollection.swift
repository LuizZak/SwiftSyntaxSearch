import SwiftSyntax

/// Internal protocol for `SyntaxCollection` types that implement `removing(childAt:)`.
protocol _RemovableSyntaxCollection: SyntaxCollection {
    var isEmpty: Bool { get }
    
    func removing(childAt index: Int) -> Self

    /// Returns `true` if a child at a given index can be removed from this
    /// syntax collection while maintaining the validity of the syntax tree.
    ///
    /// Default implementation returns `true` and must be implemented in specialized
    /// types that can form 
    func canRemove(childAt index: Int) -> Bool
}

extension _RemovableSyntaxCollection {
    func canRemove(childAt index: Int) -> Bool {
        true
    }
}
