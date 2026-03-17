## Identifiers

Identifiers are the names used to reference variables, properties, filters, and keyword arguments.

### Syntax

An identifier MUST start with an alphabetic character (a-z, A-Z), an underscore (`_`), or a supported non-ASCII Unicode character. It cannot start with a digit.

After the first character, identifiers may contain any combination of alphanumeric characters, underscores, and supported Unicode ranges.

```peg
Identifier      ← IdentifierFirst IdentifierChar* !"?"
IdentifierFirst ← [a-zA-Z_] / [\u{80}-\u{D7FF}] / [\u{E000}-\u{10FFFF}]
IdentifierChar  ← IdentifierFirst / [0-9]
```

Note: The negative lookahead `!"?"` ensures that an identifier is not immediately followed by a question mark. This reserves that specific syntactic pattern for **Predicates** (see @sec:predicates).

### Semantics

Identifiers are strictly case-sensitive. `myVariable` and `myvariable` are treated as two distinct identifiers.

A sequence of characters that would otherwise be a valid identifier is NOT considered an `Identifier` if it is followed by a `?`. Such sequences are instead parsed as part of a `Predicate`. Note that `?` is not a valid identifier character.

### Examples

| Identifier  | Validity    | Notes                                                      |
| ----------- | ----------- | ---------------------------------------------------------- |
| `user_name` | Valid       | Standard snake_case identifier.                            |
| `_secret`   | Valid       | Starts with an underscore.                                 |
| `item2`     | Valid       | Contains a digit (but not at the start).                   |
| `dâtâ`      | Valid       | Contains non-ASCII Unicode characters.                     |
| `2fast`     | **Invalid** | Cannot start with a digit.                                 |
| `is_valid?` | **Invalid** | Matches the syntax for a **Predicate**, not an Identifier. |
