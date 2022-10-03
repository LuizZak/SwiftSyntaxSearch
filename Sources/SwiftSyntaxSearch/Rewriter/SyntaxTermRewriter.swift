import SwiftSyntax

class SyntaxTermRewriter: SyntaxRewriter {
    let replacer: (Syntax) -> Syntax?

    init(replacer: @escaping (Syntax) -> Syntax?) {
        self.replacer = replacer
    }

    override func visitAny(_ node: Syntax) -> Syntax? {
        return replacer(node)
    }
}
