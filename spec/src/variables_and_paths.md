## Variables and Paths

### Syntax

A variable consists of a "root segment" followed by zero or more segments that make up a "path" to a value.

Segments can be in bracket notation, `[<selector>]`, or shorthand notation, `.some_name`. Shorthand notation is only available for names that are valid identifiers.

Both single and double quoted names are allowed in bracket notation.

The last segment of a path can be a predicate - a total Boolean function registered with the environment.

```peg
Variable     ← VariableRoot Path?
VariableRoot ← Identifier /
               "[" S StringLiteral S "]"

Path         ← (S Segment)+ Predicate?
Segment      ← "." Identifier /
               "[" S Expression S "]"
Predicate    ← "." IdentifierFirst IdentifierChar "?"
```

### Semantics

Variable resolution is a sequential process where each part of the path (the **Selector**) is resolved against the value produced by the preceding part.

To determine if a selector can be applied, the language distinguishes between two categories of values:

- **Structural Values:** Values that can contain other values. This includes $Array$, $Object$, and $Drop$ that implements a lookup protocol.

- **Non-Structural Values:** Scalar or terminal values that do not support internal navigation. This includes $Strings$, $Number$, $Boolean$, $Null$, and $Nothing$.

#### The Resolution Chain

1. **The Variable Root:** Resolution starts by looking up the `VariableRoot` in the current execution context.
2. **Segment Traversal:** For each subsequent `Segment` (Dot or Bracket):
   - If the current value is **Structural**, the engine attempts to resolve the selector against it (e.g., looking up a key in an Object or an index in an Array). If selector lookup fails (key not found, index out of bounds or non string/integer selector), the segment resolves to `Nothing`.
   - If the current value is **Non-Structural**, the segment resolves to `Nothing`.

3. **Path Termination:**
   - **Standard Path:** If the variable does not end in a predicate, the final value of the last segment is the result of the expression. If any segment in the chain resolved to `Nothing`, the entire variable expression resolves to `Nothing`.
   - **Predicate Path:** If the variable ends in a `Predicate`, the predicate is invoked using the result of the preceding segment as its input.

#### Predicates and Nothing

Unlike standard segments, **Predicates** are specifically designed to handle the absence of a value.

- A predicate is _always_ invoked, even if the preceding path resolution resulted in `Nothing`.
- The predicate receives the current `RuntimeValue` (which may be `Nothing`) and MUST return a $Boolean$ value.
- This allows a path like `user.profile.defined?` to return `false` rather than `Nothing` if `user.profile` does not exist.

**Examples**

Given a context: `{"user": {"tags": ["admin"]}}`

| Expression             | Evaluation | Notes                                                                            |
| ---------------------- | ---------- | -------------------------------------------------------------------------------- |
| `user.tags[0]`         | `"admin"`  | Path through structural values (Object -> Array).                                |
| `user.id`              | `Nothing`  | `user` is structural, but `id` is missing.                                       |
| `user.id.type`         | `Nothing`  | `user.id` is `Nothing` (non-structural), so `.type` resolves to `Nothing`.       |
| `user.tags.array?`     | `true`     | Predicate invoked on a valid Array.                                              |
| `user.id.defined?`     | `false`    | `user.id` is `Nothing`. The predicate handles `Nothing` and returns `false`.     |
| `["missing"].defined?` | `false`    | The root is missing (`Nothing`), but the predicate still evaluates to a Boolean. |

#### Predicates {#sec:predicates}

A predicate is an optional trailing path segment of the form `.predicate?`. Predicates are syntactically distinct from shorthand name segments in that they must end in a question mark `?` and they must be the last segment of a path.

Note that `?` is not a valid character for a shorthand name segment. Should a template author need to reference a value by a key containing `?`, they must use bracketed syntax `some["thing?"]`.

All predicates are total over `RuntimeValue` and MUST return `Boolean`.

$$
Predicate : RuntimeValue → Boolean
$$

For any predicate $.p?$ and accompanying abstract function $IsP$, $x.p?$ is semantically equivalent to $IsP(x)$.

#### IsBlank(x)

`IsBlank` returns `true` for null-like empty textual or collection values. Note that `Nothing` is distinct from `Null` and is not considered blank.

$$
IsBlank(x) =
  x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false

blank?(Nothing) = false
empty?(Nothing) = false
$$

The absence of a value (`Nothing`) is not considered blank.

#### IsEmpty(x)

`IsEmpty` is `true` for values that are empty collections or empty strings. As with `IsBlank`, `Nothing` is not considered empty.

$$
IsEmpty(x) =
  x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
$$

The absence of a value (`Nothing`) is not considered empty.

$$
IsEmpty(x) =
    x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
$$

#### IsDefined(x)

`IsDefined` distinguishes present values from the absence `Nothing`.

$$
IsDefined(Nothing) → false
Otherwise → true
$$

#### IsString(x)

$$
IsString(x) =
  x is String → true
  otherwise   → false
$$

#### IsNull(x)

$$
IsNull(x) =
  x is Null → true
  otherwise → false
$$

#### IsNumber(x)

$$
IsNumber(x) =
  x is Number → true
  otherwise   → false
$$

#### IsBoolean(x)

$$
IsBoolean(x) =
  x is Boolean → true
  otherwise    → false
$$

#### IsArray(x)

$$
IsArray(x) =
  x is Array → true
  otherwise  → false
$$

#### IsObject(x)

$$
IsObject(x) =
  x is Object → true
  otherwise   → false
$$
