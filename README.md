# SwiftSyntaxSearch

A small experimental library containing generic types for performing search and replacement on Swift Syntax trees.

## Requirements

Swift 5.7

## Searching

From a given syntax tree:

```swift
class AClass {
    init() {
        var decl: Int = 0
    }
    func member1() {
        var decl2: Int = 0
        var decl: Int = 1
    }
    func member2() {
        var decl: Int = 0, decl2: Int = 0
    }
}
```

We can query for all variable declarations whose first pattern binding index binds an identifier `decl` to an initial value of `0` with the following search term:

```swift
let declOf0Search = SyntaxSearchTerm<VariableDeclSyntax>
    .child(
        \VariableDeclSyntax.bindings[index: 0],
        matches:
            (\PatternBindingSyntax.pattern).matches(
                as: IdentifierPatternSyntax.self,
                SyntaxReplacer<IdentifierPatternSyntax>
                    .token(\.identifier, matches: "decl")
            ) &&
            (\PatternBindingSyntax.initializer?.value).matches(
                as: IntegerLiteralExprSyntax.self,
                SyntaxReplacer<IntegerLiteralExprSyntax>
                    .token(\.digits, matches: "0")
            )
    )
```

And search for the syntax tree like so:

```swift
syntax.findAllDepthFirst(declOf0Search)
// Returns syntax nodes:
// var decl: Int = 0
// var decl: Int = 0, decl2: Int = 0
```

## Find and Replace

From a given syntax tree:

```swift
class AClass {
    init() {
        var decl: Int = 0
    }
    func member(_ param: Int = 1) {
        var decl: Int = 2
    }
}

let global = 3
```

We can find and replace all variable declarations that bind an integer of value `0` or `1`, and invoke a closure to construct a replacement to the syntax node:

```swift
let declOf0Or2Replacer =
    SyntaxReplacer<IntegerLiteralExprSyntax>(searchTerm:
        .or([
            SyntaxReplacer<IntegerLiteralExprSyntax>
                .token(\.digits, matches: "0"),
            SyntaxReplacer<IntegerLiteralExprSyntax>
                .token(\.digits, matches: "2"),
        ])
    ) { node in
        node.withDigits(
            SyntaxFactory.makeIntegerLiteral("50_" + node.digits.text)
        )
    }
```

And create a new the syntax tree with the replacements applied like so:

```swift
syntax.replacingAll(declOf0Or2Replacer)
// Prints the new syntax tree:
// class AClass {
//     init() {
//         var decl: Int = 50_0
//     }
//     func member(_ param: Int = 1) {
//         var decl: Int = 50_2
//     }
// }
// 
// let global = 3
```

### Creating search terms

The following syntaxes are available and produce the same result:

```swift
// Keypath-based binding
(\PatternBindingSyntax.pattern).matches(
    as: IdentifierPatternSyntax.self,
    SyntaxSearchTerm<IdentifierPatternSyntax>
        .token(\.identifier, matches: "decl")
)

// Struct creation
SyntaxSearchTerm<PatternBindingSyntax>
    .child(
        // KeyPath<PatternBindingSyntax, T>
        \.pattern,

        // Cast `T` to IdentifierPatternSyntax, and if successful, invokes the matcher, otherwise matching fails.
        castTo: IdentifierPatternSyntax.self,
        
        // Match IdentifierPatternSyntax.identifier (a TokenSyntax) with a given StringMatcher (string literals match with `==`)
        matches:
            SyntaxSearchTerm<IdentifierPatternSyntax>
                .token(\.identifier, matches: "decl")
    )

// Appending to existing search term
let emptySearch = SyntaxSearchTerm<PatternBindingSyntax>()
let declIdentSearch = emptySearch
    .child(
        // KeyPath<PatternBindingSyntax, T>
        \.pattern,

        // Cast `T` to IdentifierPatternSyntax, and if successful, invokes the matcher, otherwise matching fails.
        castTo: IdentifierPatternSyntax.self,

        // Match IdentifierPatternSyntax.identifier (a TokenSyntax) with a given StringMatcher (string literals match with `==`)
        matches:
            SyntaxSearchTerm<IdentifierPatternSyntax>
                .token(\.identifier, matches: "decl")
    )
```

Search terms that inspect tokens can use the shortcut `KeyPath<_, TokenSyntax>.==` to generate token string matches like with `SyntaxSearchTerm.token(\.identifier, matches: "decl")`:

```swift
let declIdentSearch: SyntaxSearchTerm<IdentifierPatternSyntax>
declIdentSearch = \.identifier == "decl" // equivalent to declIdentSearch = .token(\.identifier, matches: "decl")
```

#### StringMatcher

A simple enum-based string matcher that performs matches based on equality, prefix, suffix or string containment. Used by `SyntaxSearchTerm` to perform token-based string equality:

```swift
// StringMatcher.exact
let exact = StringMatcher.exact("a text")

print(exact.matches("a text")) // true
print(exact.matches("")) // false
print(exact.matches("A Text")) // false
print(exact.matches("a string containing a text with prefix and suffix")) // false
print(exact.matches("a text with suffix")) // false
print(exact.matches("prefix and then a text")) // false

// StringMatcher.contains
let contains = StringMatcher.contains("a text")

print(contains.matches("a text")) // true
print(contains.matches("")) // false
print(contains.matches("A Text")) // false
print(contains.matches("a string containing a text with prefix and suffix")) // true
print(contains.matches("a text with suffix")) // true
print(contains.matches("prefix and then a text")) // true

// StringMatcher.prefix
let prefix = StringMatcher.prefix("a text")

print(prefix.matches("a text")) // true
print(prefix.matches("")) // false
print(prefix.matches("A Text")) // false
print(prefix.matches("a string containing a text with prefix and suffix")) // false
print(prefix.matches("a text with suffix")) // true
print(prefix.matches("prefix and then a text")) // false

// StringMatcher.suffix
let suffix = StringMatcher.suffix("a text")

print(suffix.matches("a text")) // true
print(suffix.matches("")) // false
print(suffix.matches("A Text")) // false
print(suffix.matches("a string containing a text with prefix and suffix")) // false
print(suffix.matches("a text with suffix")) // false
print(suffix.matches("prefix and then a text")) // true
```
