import SwiftSyntax
import SwiftSyntaxParser

enum Parsing {
    static func parse(_ text: String) throws -> SourceFileSyntax {
        try SyntaxParser.parse(source: text)
    }

    static func parse<T: SyntaxProtocol>(_ text: String, _ element: KeyPath<SourceFileSyntax, T>) throws -> T {
        let file = try parse(text)

        return file[keyPath: element]
    }
}
