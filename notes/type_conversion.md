## Type Conversion

In a language built on the principle of total evaluation, type conversion acts as the "glue" that allows disparate data types to interact without causing runtime crashes. Every conversion in this specification is deterministic and total—if a value cannot be transformed into the requested type, the system returns a defined fallback or the `Nothing` state rather than halting execution.

### 1. The Concept of Truthiness (`ToBoolean`)

The language adopts a model of **Structural Truthiness**. Unlike some languages that rely on strict boolean types, this system evaluates the "substance" of a value. A value is considered truthy if it represents a non-zero, non-empty, and non-null presence.

- **Absence**: `Null` and `Nothing` are always `false`.

- **Numbers**: Any number not equal to zero ($0$ or $0.0$) is `true`.

- **Collections**: Strings, Arrays, and Objects are `true` only if their length or size is greater than zero.

- **Drops**: These utilize the `boolean` context hint; if the Drop's `ToLiquid` implementation returns `Nothing`, it is treated as `false`.

This uniform approach ensures that template logic like `if user.items` behaves intuitively across different data structures.

---

### 2. Numeric Coercion (`ToNumber`)

Arithmetic operations and numeric comparisons rely on the `ToNumber` abstract operation. This function attempts to extract a mathematical value (Integer or Decimal) from any `RuntimeValue`.

- **Strings**: The system attempts to parse the string as a numeric literal. If the string is not a valid number, it results in `Nothing`.

- **Booleans**: To facilitate certain logic patterns, `true` is coerced to $1$ and `false` to $0$.

- **Drops**: Coerced using the `numeric` hint.

- **Incompatibles**: Arrays, Objects, `Null`, and `Nothing` yield `Nothing`.

Because arithmetic operators propagate `Nothing`, a single invalid number in a complex calculation like `5 + (price * "invalid")` will safely resolve to `Nothing` rather than an error.

---

### 3. String Representation (`ToString`)

The `ToString` operation is the most frequently used conversion, as it governs how values are rendered in the final template output.

- **Primitives**: Integers and Floats use standard decimal representations; Booleans result in `"true"` or `"false"`.

- **Empty States**: Both `Null` and `Nothing` are rendered as empty strings (`""`).

- **Complex Types**: To provide helpful debugging and data serialization, Arrays and Objects are converted into JSON-formatted strings.

- **Drops**: These utilize the `render` or `string` hints to determine their textual output.

---

### 4. Array Normalization (`ToArray`)

The `ToArray` operation is primarily used by the `for` tag and sequence-aware filters to ensure a consistent iterable interface.

- **Promotion**: If a single value (like a String or Number) is passed to a context requiring an array, it is wrapped in a single-element array: `[x]`.

- **Empty Iterables**: `Null` and `Nothing` resolve to an empty array `[]`.

- **Sequence Protocol**: If a `Drop` implements the `Sequence` protocol, `ToArray` utilizes its iteration logic to produce a standard array.

---

### Conversion Summary Table

| Input Type             | `ToBoolean` | `ToNumber`         | `ToString`         | `ToArray` |
| ---------------------- | ----------- | ------------------ | ------------------ | --------- |
| **Nothing / Null**     | `false`     | `Nothing`          | `""`               | `[]`      |
| **Boolean**            | Identity    | `1` or `0`         | `"true"`/`"false"` | `[x]`     |
| **Number (non-zero)**  | `true`      | Identity           | String value       | `[x]`     |
| **String (non-empty)** | `true`      | Parse or `Nothing` | Identity           | `[x]`     |
| **Array (non-empty)**  | `true`      | `Nothing`          | JSON String        | Identity  |
