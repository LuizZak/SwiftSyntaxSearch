import XCTest

@testable import SwiftSyntaxSearch

class StringMatcherTests: XCTestCase {
    func testExact() {
        let sut = StringMatcher.exact("a text")

        XCTAssertTrue(sut.matches("a text"))
        XCTAssertFalse(sut.matches(""))
        XCTAssertFalse(sut.matches("A Text"))
        XCTAssertFalse(sut.matches("a string containing a text with prefix and suffix"))
        XCTAssertFalse(sut.matches("a text with suffix"))
        XCTAssertFalse(sut.matches("prefix and then a text"))
    }
    
    func testContains() {
        let sut = StringMatcher.contains("a text")

        XCTAssertTrue(sut.matches("a text"))
        XCTAssertFalse(sut.matches(""))
        XCTAssertFalse(sut.matches("A Text"))
        XCTAssertTrue(sut.matches("a string containing a text with prefix and suffix"))
        XCTAssertTrue(sut.matches("a text with suffix"))
        XCTAssertTrue(sut.matches("prefix and then a text"))
    }
    
    func testPrefix() {
        let sut = StringMatcher.prefix("a text")

        XCTAssertTrue(sut.matches("a text"))
        XCTAssertFalse(sut.matches(""))
        XCTAssertFalse(sut.matches("A Text"))
        XCTAssertFalse(sut.matches("a string containing a text with prefix and suffix"))
        XCTAssertTrue(sut.matches("a text with suffix"))
        XCTAssertFalse(sut.matches("prefix and then a text"))
    }
    
    func testSuffix() {
        let sut = StringMatcher.suffix("a text")

        XCTAssertTrue(sut.matches("a text"))
        XCTAssertFalse(sut.matches(""))
        XCTAssertFalse(sut.matches("A Text"))
        XCTAssertFalse(sut.matches("a string containing a text with prefix and suffix"))
        XCTAssertFalse(sut.matches("a text with suffix"))
        XCTAssertTrue(sut.matches("prefix and then a text"))
    }
}
