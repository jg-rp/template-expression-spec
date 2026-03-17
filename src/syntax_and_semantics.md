# Syntax and Semantics

TODO: overview

The grammar is written using **Parsing Expression Grammar (PEG)** semantics following the notation introduced by Bryan Ford. Rule definitions and operators follow Ford-style PEG notation (`<-`, `/`, `*`, `+`, `?`, `!`, `&`). Literal syntax, escape sequences, and bounded repetition follow the conventions of Pest (parser generator).

TODO: intro sentence

```peg
Expression ← TernaryExpr

B          ← " " / "\t" / "\r" / "\n"    // Whitespace
S          ← B*                          // Optional whitespace
C          ← IdentifierChar              // Alias for any name character
```

TODO: Elaborate on Nothing.

Implementations MAY surface evaluation of Nothing as errors, warnings, or diagnostics, but MUST preserve the observable semantics defined by this specification when execution continues.
