## Variables and Paths

### Syntax

A variable consists of a "root segment" followed by zero or more segments that make up a "path" to a value.

Segments can be in bracket notation, `[<selector>]`, or shorthand notation, `.some_name`. Shorthand notation is only available for names that are valid identifiers.

Both single and double quoted names are allowed in bracket notation.

The last segment of a path may be a predicate (@sec:predicates) - an identifier followed by a question mark `?`.

```peg
Variable     ← VariableRoot Path?
VariableRoot ← Identifier /
               "[" S StringLiteral S "]"

Path         ← (S Segment)+ Predicate?
Segment      ← "." Identifier /
               "[" S Expression S "]"
Predicate    ← "." IdentifierFirst IdentifierChar "?"
```

_Note: An `Identifier` cannot include a `?`. A `Predicate` is syntactically distinguished by its trailing question mark and its position as the terminal segment of a variable path._

### Semantics

Variable resolution is a sequential process where each part of the path (the **Selector**) is resolved against the value produced by the preceding part.

To determine if a selector can be applied, the language distinguishes between two categories of values:

- **Structural Values:** Values that can contain other values. This includes $Array$, $Object$, and $Drop$ that implements a lookup protocol.

- **Non-Structural Values:** Scalar or terminal values that do not support internal navigation. This includes $Strings$, $Number$, $Boolean$, $Null$, and $Nothing$.

#### The Resolution Chain

1. Resolution starts by looking up the `VariableRoot` in the current execution context.
2. For each subsequent `Segment` (Dot or Bracket):
   - If the current value is **Structural**, the engine attempts to resolve the selector against it (e.g., looking up a key in an Object or an index in an Array). If selector lookup fails (key not found, index out of bounds or non string/integer selector), the segment resolves to `Nothing`.
   - If the current value is **Non-Structural**, the segment resolves to `Nothing`.
3. Path Termination:
   - Standard Path: If the variable does not end in a predicate, the final value of the last segment is the result of the expression. If any segment in the chain resolved to `Nothing`, the entire variable expression resolves to `Nothing`.
   - Predicate Path: If the variable ends in a `Predicate`, the predicate is invoked using the result of the preceding segment as its input.

#### Predicates {#sec:predicates}

A predicate is a named function registered with the environment. All predicates are total over $RuntimeValue$ and MUST return $Boolean$.

$$
Predicate : RuntimeValue → Boolean
$$

For any predicate $.p?$ and accompanying abstract function $IsP$, `x.p?` is semantically equivalent to $IsP(x)$.

Unlike standard segments, **Predicates** are specifically designed to handle the absence of a value.

- The predicate is evaluated against the result of the path preceding it. If the path resolution fails at any point, the predicate receives `Nothing` as its input.
- A predicate is _always_ invoked, even if the preceding path resolution resulted in `Nothing`.
- This allows a path like `user.profile.defined?` to return `false` rather than `Nothing` if `user.profile` does not exist.
- If a predicate does not exist in the environment, the result is `false`. Implementations MAY issue a warning or error at parse time in the event of an unknown predicate.

### Predicate Definitions

Here we define abstract predicate functions that are expected to be implemented.

#### blank?

Returns `true` for empty textual or collection values. Note that `Nothing` is distinct from `Null` and is not considered blank.

```
IsBlank(x) =
  x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

The absence of a value (`Nothing`) is not considered blank.

#### empty?

Returns `true` for values that are empty collections or empty strings. As with `IsBlank`, `Nothing` is not considered empty.

```
IsEmpty(x) =
  x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

#### defined?

Returns `true` if the input is any value other than `Nothing`.

```
IsDefined(Nothing) → false
Otherwise → true
```

#### string?

Returns `true` if the input is of type $String$.

```
IsString(x) =
  x is String → true
  otherwise   → false
```

#### null?

Returns `true` if the input is of type $Null$.

```
IsNull(x) =
  x is Null → true
  otherwise → false
```

#### number?

Returns `true` if the input is of type $Number$.

```
IsNumber(x) =
  x is Number → true
  otherwise   → false
```

#### boolean?

Returns `true` if the input is of type $Boolean$.

```
IsBoolean(x) =
  x is Boolean → true
  otherwise    → false
```

#### array?

Returns `true` if the input is of type $Array$.

```
IsArray(x) =
  x is Array → true
  otherwise  → false
```

#### object?

Returns `true` if the input is of type $Object$.

```
IsObject(x) =
  x is Object → true
  otherwise   → false
```

### Examples

Given a context: `{"user": {"tags": ["admin"]}}`

| Expression             | Evaluation | Notes                                                                            |
| ---------------------- | ---------- | -------------------------------------------------------------------------------- |
| `user.tags[0]`         | `"admin"`  | Path through structural values (Object -> Array).                                |
| `user.id`              | `Nothing`  | `user` is structural, but `id` is missing.                                       |
| `user.id.type`         | `Nothing`  | `user.id` is `Nothing` (non-structural), so `.type` resolves to `Nothing`.       |
| `user.tags.array?`     | `true`     | Predicate invoked on a valid Array.                                              |
| `user.id.defined?`     | `false`    | `user.id` is `Nothing`. The predicate handles `Nothing` and returns `false`.     |
| `["missing"].defined?` | `false`    | The root is missing (`Nothing`), but the predicate still evaluates to a Boolean. |

Given a context: `{"user": {"name": " ", "tags": []}}`

| Expression             | Evaluation | Notes                                            |
| ---------------------- | ---------- | ------------------------------------------------ |
| `user.name.blank?`     | `true`     | String is whitespace only.                       |
| `user.name.empty?`     | `false`    | String has length > 0.                           |
| `user.tags.empty?`     | `true`     | Array has length 0.                              |
| `user.id.defined?`     | `false`    | `id` is missing (`Nothing`).                     |
| `user.id.null?`        | `false`    | `Nothing` is not `Null`.                         |
| `user.tags.array?`     | `true`     | Correct type check.                              |
| `["missing"].defined?` | `false`    | Root lookup failed, predicate handles `Nothing`. |
