/// Matches strings, either partially, fully or by prefix-/suffix-
public enum StringMatcher: Equatable, CustomStringConvertible {
    /// Matches `term` exactly.
    case exact(String)

    /// Matches `*term*`, case sensitive.
    case contains(String)

    /// Matches `term*`, case sensitive.
    case prefix(String)

    /// Matches `*term`, case sensitive.
    case suffix(String)

    public func matches(_ str: String) -> Bool {
        switch self {
        case .exact(let exp):
            return str == exp

        case .contains(let exp):
            return str.contains(exp)

        case .prefix(let exp):
            return str.hasPrefix(exp)

        case .suffix(let exp):
            return str.hasSuffix(exp)
        }
    }

    public var description: String {
        switch self {
        case .exact(let exp):
            return exp

        case .contains(let exp):
            return "*\(exp)*"

        case .prefix(let exp):
            return "\(exp)*"

        case .suffix(let exp):
            return "*\(exp)"
        }
    }
}

extension StringMatcher: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .exact(value)
    }
}
