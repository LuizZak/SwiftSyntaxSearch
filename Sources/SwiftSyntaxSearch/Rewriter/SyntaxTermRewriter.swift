import SwiftSyntax

class SyntaxTermRewriter<T: SyntaxProtocol>: SyntaxRewriter {
    let replacer: SyntaxReplacer<T>

    init(replacer: SyntaxReplacer<T>) {
        self.replacer = replacer
    }

    override func visitAny(_ node: Syntax) -> Syntax? {
        return replacer.matchAndReplace(node).map(Syntax.init)
    }
}
