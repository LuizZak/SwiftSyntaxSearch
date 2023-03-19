public extension SyntaxSearchTerm {
    /// Matches iff all of the provided matchers match.
    ///
    /// Empty matcher list results in no matches, like `Self.none`.
    static func && (lhs: Self, rhs: Self) -> Self {
        lhs.and(rhs)
    }
}
