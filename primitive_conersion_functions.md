We’ll define:

1. The **Value domain**
2. Primitive **total conversion functions**
3. The formal semantics of the `+` operator

Everything will be:

- Total (no runtime type errors)
- Deterministic
- Immutable
- Explicitly ordered

---

# 1. Value Domain

Let `Value` be the disjoint union:

```
Value =
    Null
  | Boolean
  | Integer
  | Float
  | String
  | Array<Value>
  | Object
```

`Range` does not exist at runtime. `(a..b)` evaluates to `Array<Integer>`.

All values are immutable.

---

# 2. Primitive Conversion Functions

These are total functions:

```
ToBoolean : Value → Boolean
ToNumber  : Value → Number   (Integer | Float)
ToString  : Value → String
ToArray   : Value → Array<Value>
```

Each must be deterministic and never throw.

---

## 2.1 ToBoolean(x)

| Input Type | Result        |
| ---------- | ------------- |
| Null       | false         |
| Boolean    | identity      |
| Integer    | x ≠ 0         |
| Float      | x ≠ 0.0       |
| String     | length(x) > 0 |
| Array      | length(x) > 0 |
| Object     | true          |

No special cases for `"0"` or `"false"`.

---

## 2.2 ToNumber(x)

Returns either Integer or Float.

| Input Type | Result                                |
| ---------- | ------------------------------------- |
| Integer    | identity                              |
| Float      | identity                              |
| Boolean    | true → 1, false → 0                   |
| Null       | 0                                     |
| String     | parse numeric literal; if invalid → 0 |
| Array      | length(x)                             |
| Object     | 0                                     |

### String Parsing Rules

- Trim ASCII whitespace.
- Accept decimal integers and floats.
- Reject hex, scientific notation (unless explicitly supported).
- Invalid parse → 0.
- `"3"` → Integer(3)
- `"3.0"` → Float(3.0)
- `"abc"` → 0

Parsing must not throw.

---

## 2.3 ToString(x)

| Input Type | Result                                       |
| ---------- | -------------------------------------------- |
| String     | identity                                     |
| Integer    | decimal representation                       |
| Float      | canonical decimal                            |
| Boolean    | `"true"` or `"false"`                        |
| Null       | `""`                                         |
| Array      | join(ToString(e), ",")                       |
| Object     | implementation-defined stable representation |

This function must not mutate arrays during join.

---

## 2.4 ToArray(x)

| Input Type      | Result   |
| --------------- | -------- |
| Array           | identity |
| Null            | []       |
| Any other value | [x]      |

This guarantees Array coercion is always defined.

---

# 3. Operator Definition: `+`

We now define:

```
Add : Value × Value → Value
```

This function is total.

---

## 3.1 Resolution Algorithm

Given operands `a` and `b`, evaluation proceeds in this exact order:

---

### Step 1 — Array Domain

If either operand is Array:

```
Return Concat(ToArray(a), ToArray(b))
```

Where:

```
Concat : Array<Value> × Array<Value> → Array<Value>
```

- Produces a new array.
- Does not mutate inputs.

Examples:

```
[1,2] + [3]        → [1,2,3]
[1,2] + 3          → [1,2,3]
3 + [4,5]          → [3,4,5]
null + [1]         → [1]
```

This rule has highest priority.

---

### Step 2 — String Domain

Else if either operand is String:

```
Return ToString(a) ⧺ ToString(b)
```

Where `⧺` is string concatenation.

Examples:

```
"hi" + 5     → "hi5"
5 + "hi"     → "5hi"
null + "x"   → "x"
```

---

### Step 3 — Numeric Domain

Else:

```
Let n1 = ToNumber(a)
Let n2 = ToNumber(b)

If either n1 or n2 is Float:
    return Float(n1 + n2)
Else:
    return Integer(n1 + n2)
```

Examples:

```
2 + 3        → 5
2 + 3.5      → 5.5
true + 3     → 4
null + 7     → 7
false + null → 0
```

---

## 3.2 Properties

- `+` is associative within domain (numeric, string, array).
- `+` is commutative only in numeric domain.
- `+` never throws.
- `+` never mutates operands.
- `+` always returns a new value if Array or String.

---

# 4. Observations About Priority

The precedence order is:

```
Array
  ↓
String
  ↓
Numeric
```

This is not a type promotion lattice.

It is an **operator dispatch priority**.

This ensures:

```
[1] + "2" → ["2"? No.]
```

Actually:

Since Array rule triggers first:

```
[1] + "2"
→ Concat([1], ["2"])
→ [1, "2"]
```

Because ToArray("2") → ["2"].

That is consistent and structural.

---

# 5. Why This Is Spec-Grade

We have:

- Fully total conversion functions.
- Ordered resolution algorithm.
- Explicit immutability.
- No ambiguous coercion.
- No reliance on implicit “widening intuition”.

This is the same structural style used in ECMAScript operator definitions, but simplified for a templating domain.

---
