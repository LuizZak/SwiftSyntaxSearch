import XCTest
import SwiftSyntax

@testable import SwiftSyntaxSearch

class SyntaxSearchTermTests: XCTestCase {
    func testAnyChild() throws {
        let file = try Parsing.parse("""
            class AClass {
                init() {
                    var decl: Int = 0
                }
                func member() {
                }
            }
            """)

        let sut = SyntaxSearchTerm<Syntax>
            .anyChildRecursive(
                IntegerLiteralExprSyntax
                    .search
                    .init()
                    .add(\.digits, "0")
            )

        XCTAssertTrue(sut.matches(file))
        XCTAssertTrue(sut.matches(
            file.statements
                .findRecursive(SyntaxSearchTerm<InitializerDeclSyntax>())
            )
        )
        XCTAssertFalse(sut.matches(
            file.statements
                .findRecursive(SyntaxSearchTerm<FunctionDeclSyntax>())
            )
        )
    }

    func testNot() {
        let syntax = emptySyntax()

        let sut = SyntaxSearchTerm<Syntax>.any

        XCTAssertTrue(sut.matches(syntax))
        XCTAssertFalse(sut.not.matches(syntax))
    }

    func testOr() {
        let syntax = emptySyntax()

        let allTrue =
            SyntaxSearchTerm<Syntax>.or([
                .any,
                .any,
            ])
        let oneTrue =
            SyntaxSearchTerm<Syntax>.or([
                .any,
                .none,
            ])
        let noneTrue =
            SyntaxSearchTerm<Syntax>.or([
                .none,
                .none,
            ])
        let empty = SyntaxSearchTerm<Syntax>.or([])

        XCTAssertTrue(allTrue.matches(syntax))
        XCTAssertTrue(oneTrue.matches(syntax))
        XCTAssertFalse(noneTrue.matches(syntax))
        XCTAssertFalse(empty.matches(syntax))
    }

    func testAnd() {
        let syntax = emptySyntax()

        let allTrue =
            SyntaxSearchTerm<Syntax>.and([
                .any,
                .any,
            ])
        let oneTrue =
            SyntaxSearchTerm<Syntax>.and([
                .any,
                .none,
            ])
        let noneTrue =
            SyntaxSearchTerm<Syntax>.and([
                .none,
                .none,
            ])
        let empty = SyntaxSearchTerm<Syntax>.and([])

        XCTAssertTrue(allTrue.matches(syntax))
        XCTAssertFalse(oneTrue.matches(syntax))
        XCTAssertFalse(noneTrue.matches(syntax))
        XCTAssertFalse(empty.matches(syntax))
    }

    func testFindRecursive() throws {
        let file = try Parsing.parse("""
            class AClass {
                init() {
                    var decl: Int = 0
                }
                func member() {
                }
            }
            """)
        
        XCTAssertNotNil(file.findRecursive(SyntaxSearchTerm<FunctionDeclSyntax>.any))
        XCTAssertNil(file.findRecursive(SyntaxSearchTerm<EnumDeclSyntax>.any))
    }

    func testFindAllBreadthFirst() throws {
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
        
        let sut = SyntaxSearchTerm<IntegerLiteralExprSyntax>.any

        let result = file.findAllBreadthFirst(sut)

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.map({ $0.digits.text }), [
             "3", "1", "0", "2",
        ])
    }

    func testFindAllDepthFirst() throws {
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
        
        let sut = SyntaxSearchTerm<IntegerLiteralExprSyntax>.any

        let result = file.findAllDepthFirst(sut)

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result.map({ $0.digits.text }), [
            "0", "1", "2", "3",
        ])
    }
}

private func emptySyntax() -> Syntax {
    IntegerLiteralExprSyntax { builder in
        builder.useDigits(SyntaxFactory.makeIntegerLiteral("0"))
    }.asSyntax
}
