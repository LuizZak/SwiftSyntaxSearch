import XCTest
import SwiftSyntax

@testable import SwiftSyntaxSearch

class SyntaxRemoverTests: XCTestCase {
    func testRemovingAll() throws {
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
            SyntaxRemover<IntegerLiteralExprSyntax>(searchTerm:
                .or([
                    .token(\.digits, matches: "0"),
                    .token(\.digits, matches: "2"),
                ])
            )
        
        let result = file.removingAll(sut)
        XCTAssertEqual(result.description, """
            class AClass {
                init() {
                    var 
                }
                func member(_ param: Int = 1) {
                    var 
                }
            }

            let global = 3
            """)
    }
}
