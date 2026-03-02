## Variable Resolution and Paths

Variable resolution is the process of mapping identifiers and access paths to a `RuntimeValue` within a given environment. In keeping with the total evaluation model, path resolution is designed to be infallible; a path that cannot be resolved due to missing keys or null parents simply evaluates to `Nothing` rather than halting the template render.

### 1. Root Identifiers

Resolution begins with a bare `name`, which the engine looks up in the current local or global execution context.

- **Names**: A name must start with an alphabetic character or underscore and may contain alphanumeric characters or high-range Unicode scalar values.
- **Environment Lookup**: If the name exists in the environment, its associated `RuntimeValue` is returned; otherwise, the result is `Nothing`.

### 2. The Path Chain (Segments)

Complex data structures are navigated using a sequence of segments, which can be either dotted or bracketed.

- **Dotted Access (`.name`)**: This is a shorthand for property access or object key lookup. For example, `user.profile` treats `profile` as a key to be retrieved from the `user` object.
- **Bracketed Selectors (`[expr]`)**: This allows for dynamic resolution where the key or index is determined by evaluating an inner expression.
- If the selector evaluates to a `String`, it acts as an object key lookup.
- If the selector evaluates to a `Number` (via `ToNumber`), it acts as an array index.

- **Total Access**: Accessing an out-of-range index on an array or a missing key on an object returns `Nothing`.

### 3. Predicates (`.p?`)

Predicates are a specialized, syntactically distinct form of property access used to query the state or type of a value.

- **Trailing Only**: A predicate must be the final segment of a path; it is defined by a name followed immediately by a question mark `?`.
- **Strict Boolean Return**: Unlike standard segments, predicates are total over all `RuntimeValue` types and MUST return a `Boolean`.
- **Built-in Logic**: The language provides several standard predicates, such as `.blank?`, `.empty?`, and `.defined?`, which evaluate the structural properties of the preceding value.

### 4. Total Evaluation and Propagation

The resolution of a path is a linear "chain" where `Nothing` acts as a terminal state.

- **Short-Circuiting**: If any intermediate segment in a path (e.g., the `b` in `a.b.c`) yields `Nothing`, the engine stops further resolution and the entire path evaluates to `Nothing`.
- **Null Safety**: This propagation ensures that developers do not need to wrap every segment in conditional checks; the path `enterprise.department.manager.name` is safe even if `department` is missing.

---
