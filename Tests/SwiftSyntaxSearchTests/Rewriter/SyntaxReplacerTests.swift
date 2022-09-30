import XCTest
import SwiftSyntax

@testable import SwiftSyntaxSearch

class SyntaxReplacerTests: XCTestCase {
    func testAnyChild() throws {
        let file = try Parsing.parse("""
            class AClass {
                init() {
                    var decl: Int = 0
                }
                func member(_ param: Int = 1) {
                    var decl: Int = 2
                }
            }

            let global = 3
            """)

        let sut =
            SyntaxReplacer<IntegerLiteralExprSyntax>(searchTerm:
                .or([
                    .token(\.digits, matches: "0"),
                    .token(\.digits, matches: "2"),
                ])
            ) { node in
                node.withDigits(
                    SyntaxFactory.makeIntegerLiteral("50_" + node.digits.text)
                )
            }
        
        let result = file.replacingAll(sut)
        XCTAssertEqual(result.description, """
            class AClass {
                init() {
                    var decl: Int = 50_0
                }
                func member(_ param: Int = 1) {
                    var decl: Int = 50_2
                }
            }

            let global = 3
            """)
    }
}
