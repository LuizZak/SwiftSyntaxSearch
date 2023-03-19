/// Protocol for string matchers.
public protocol StringMatcherType {
    /// Returns `true` if a given input string matches this string matcher's
    /// parameters.
    func matches(_ value: String) -> Bool
}
