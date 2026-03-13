## 2. PEG syntax (the de-facto standard)

For **PEG-based languages**, the closest thing to a standard syntax is the notation introduced in:

- Parsing Expression Grammars: A Recognition-Based Syntactic Foundation by Bryan Ford.

This notation is now used by most PEG tools and papers.

Typical PEG notation:

```
Expression  <- Term (("+" / "-") Term)*
Term        <- Factor (("*" / "/") Factor)*
Factor      <- Number / "(" Expression ")"
Number      <- [0-9]+
```

Core operators:

| Syntax   | Meaning            |
| -------- | ------------------ |
| `A <- B` | rule definition    |
| `A B`    | sequence           |
| `A / B`  | **ordered choice** |
| `A*`     | zero or more       |
| `A+`     | one or more        |
| `A?`     | optional           |
| `!A`     | negative lookahead |
| `&A`     | positive lookahead |
| `.`      | any character      |
| `[abc]`  | character class    |

This syntax appears in tools like:

- PEG.js
- LPeg
- Peggy
- Mouse PEG parser generator

```
NullLiteral ← ("null" / "nil") !IdentifierPart
```

> The grammar is written using **Parsing Expression Grammar (PEG)** semantics following the notation introduced by Bryan Ford.
> Rule definitions and operators follow Ford-style PEG notation (`<-`, `/`, `*`, `+`, `?`, `!`, `&`).
> Literal syntax, escape sequences, and bounded repetition follow the conventions of Pest (parser generator).
