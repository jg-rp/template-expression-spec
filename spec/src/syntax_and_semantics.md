# Syntax and Semantics

TODO: overview

The grammar is written using **Parsing Expression Grammar (PEG)** semantics following the notation introduced by Bryan Ford. Rule definitions and operators follow Ford-style PEG notation (`<-`, `/`, `*`, `+`, `?`, `!`, `&`). Literal syntax, escape sequences, and bounded repetition follow the conventions of Pest (parser generator).

```
Expression ← TernaryExpr

B ← " " / "\t" / "\r" / "\n"    // Whitespace
S ← B*                          // Optional whitespace
C ← IdentifierChar              // Alias for any name character
```
