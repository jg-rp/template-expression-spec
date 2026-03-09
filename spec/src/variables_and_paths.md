# Variables and Paths

Variable resolution proceeds as follows:

- A bare `name` is looked up in the current environment (local/context variables). If present, that value is returned.
- If the path contains segments (e.g. `a.b[c].d`), evaluate each selector in sequence. For a dotted segment `.name` perform a lookup as an object key or a property access on the current value; for a bracketed selector `[expr]` evaluate `expr` and use the resulting value as the key or index (strings and numbers are commonly used as keys/indices).
- If an intermediate segment yields `Nothing`, subsequent segments evaluate to `Nothing` and the whole path yields `Nothing`.
- Accessing a missing key on an object yields `Nothing` (not an error).
- Numeric indices on arrays use `ToNumber` for the selector, and out‑of‑range accesses yield `Nothing`.

Implementations SHOULD treat property access on host objects according to a well‑documented resolution order (e.g. keys first, then methods) and MUST avoid raising exceptions during lookup - missing or inaccessible values map to `Nothing`.

## Predicates

A predicate is an optional trailing path segment of the form `.predicate?`. Predicates are syntactically distinct from shorthand name segments in that they must end in a question mark `?` and they must be the last segment of a path.

Note that `?` is not a valid character for a shorthand name segment. Should a template author need to reference a value by a key containing `?`, they must use bracketed syntax `some["thing?"]`.

All predicates are total over `RuntimeValue` and MUST return `Boolean`.

```
Predicate : RuntimeValue → Boolean
```

For any predicate `.p?` and accompanying abstract function `IsP`:

```
x.p?
```

Is semantically equivalent to:

```
IsP(x)
```

## IsBlank(x)

`IsBlank` returns true for null-like empty textual or collection values.
Note that `Nothing` is distinct from `Null` and is not considered blank.

```
IsBlank(x) =
  x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false

blank?(Nothing) = false
empty?(Nothing) = false
```

The absence of a value (`Nothing`) is not considered blank.

## IsEmpty(x)

`IsEmpty` is true for values that are empty collections or empty strings. As
with `IsBlank`, `Nothing` is not considered empty.

```
IsEmpty(x) =
  x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

The absence of a value (`Nothing`) is not considered empty.

```
IsEmpty(x) =
    x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false
```

## IsDefined(x)

`IsDefined` distinguishes present values from the absence `Nothing`.

```
IsDefined(Nothing) → false
Otherwise → true
```

```
IsDefined(Nothing) → false
Otherwise → true
```

## IsString(x)

```
IsString(x) =
  x is String → true
  otherwise   → false
```

```
IsString(x) =
    x is String → true
    otherwise   → false
```

## IsNull(x)

```
IsNull(x) =
  x is Null → true
  otherwise → false
```

```
IsNull(x) =
    x is Null → true
    otherwise → false
```

## IsNumber(x)

```
IsNumber(x) =
  x is Number → true
  otherwise   → false
```

```
IsNumber(x) =
    x is Number → true
    otherwise   → false
```

## IsBoolean(x)

```
IsBoolean(x) =
  x is Boolean → true
  otherwise    → false
```

```
IsBoolean(x) =
    x is Boolean → true
    otherwise    → false
```

## IsArray(x)

```
IsArray(x) =
  x is Array → true
  otherwise  → false
```

```
IsArray(x) =
    x is Array → true
    otherwise  → false
```

## IsObject(x)

```
IsObject(x) =
  x is Object → true
  otherwise   → false
```

```
IsObject(x) =
    x is Object → true
    otherwise   → false
```
