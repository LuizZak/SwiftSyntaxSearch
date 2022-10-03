import SwiftSyntax

class SyntaxTermRemover: SyntaxRewriter {
    typealias Entry = (collectionId: SyntaxIdentifier, index: Int)

    private var toRemove: [Entry]
    private var entriesFound: [Bool]

    init(toRemove: [Entry]) {
        self.toRemove = toRemove
        self.entriesFound = toRemove.map { _ in false }
    }

    override func visitAny(_ node: Syntax) -> Syntax? {
        guard let node = node.asProtocol(SyntaxProtocol.self) as? any _RemovableSyntaxCollection else {
            return nil
        }

        return (checkAndRemove(node)?.asSyntax).map(visit)
    }

    private func checkAndRemove<T: _RemovableSyntaxCollection>(_ node: T) -> T? {
        for (i, (entry, found)) in zip(toRemove, entriesFound).enumerated() where !found && node.id == entry.collectionId {
            print("Found \(i) collection node \(entry.collectionId) to remove child @ \(entry.index)")

            entriesFound[i] = true

            return node.removing(childAt: entry.index)
        }

        return nil
    }

    /*
    override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: TupleExprElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ArrayElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: DictionaryElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: StringLiteralSegmentsSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: DeclNameArgumentListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ExprListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ClosureCaptureItemListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ClosureParamListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: MultipleTrailingClosureElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ObjcNameSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: FunctionParameterListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: IfConfigClauseListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: InheritedTypeListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: MemberDeclListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ModifierListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: AccessPathSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: AccessorListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: PatternBindingListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: EnumCaseElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: IdentifierListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: PrecedenceGroupAttributeListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: PrecedenceGroupNameListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: TokenListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: NonEmptyTokenListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: AttributeListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: SpecializeAttributeSpecListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ObjCSelectorSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: DifferentiabilityParamListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: BackDeployVersionListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: SwitchCaseListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: CatchClauseListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: CaseItemListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: CatchItemListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: ConditionElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: GenericRequirementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: GenericParameterListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: PrimaryAssociatedTypeListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: CompositionTypeElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: TupleTypeElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: GenericArgumentListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: TuplePatternElementListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }

    override func visit(_ node: AvailabilitySpecListSyntax) -> Syntax {
        guard node.id == collectionId else {
            return super.visit(node)
        }

        return super.visit(node.removing(childAt: index))
    }
    */
}
