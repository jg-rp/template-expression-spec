# A Unified Expression Grammar for Template Languages

This project defines a unified, implementation‑independent expression language for Liquid-style templates.

The specification focuses strictly on the internal mechanics of expressions. Notably, this document does not define the surrounding tag architecture (such as the specific implementation of `{% if %}` or `{% for %}`) nor does it provide a "standard library" of filters.

## Notable Differences to Shopify/Liquid

- Arithmetic operators (`+`, `-`, `*`, `/`, `%`) are supported directly in expressions. Arithmetic operators DO NOT default to zero when numeric coercion fails. Instead they evaluate to `Nothing`, and arithmetic expressions (along with their matching filters) evaluate to `Nothing` if either operand is `Nothing`, or when an operation is undefined (such as division or modulo by zero).

- Logical operator precedence (`and` and `or`) has changed. The spec requires `and` to bind tighter than `or` and evaluation to happen from left to right. Parentheses may be used for grouping: `not (a and b)`

- Filters are no longer restricted by contextual parsing rules. They participate in the unified expression grammar and can appear anywhere expressions are allowed. The pipe operator (`|`) is treated as a standard expression operator with deterministic behavior.

- Python-style conditional expressions are supported:

  ```
  value if condition else alternative
  ```

  Ternary expressions are fully composable and follow defined precedence rules. They may be nested and combined with filters, arithmetic, and logical operators.

- Array and object literals are supported:

  ```
  [1, 2, 3]
  { "name": user.name }
  ```

  A spread operator (`...`) allows composition of structures:

  ```
  [...items, 4]
  { ...defaults, "enabled": true }
  ```

  This enables template authors to construct collections immutably, without manipulating render context data.

- Filters can accept anonymous expressions as arguments. Anonymous expressions capture their lexical environment and allow filters to apply custom logic such as mapping or sorting to data structures.

- The special `x == empty` and `x == blank` constructs have been replaced with `x.empty?` and `x.blank?` predicates. Other predicates defined in the spec include `defined?` and `array?`.

- Value-returning operations such as `x.size`, `x.first` and `x.last` are expressed via filters and indexing.

- Both `:` and `=` are allowed in filter keyword argument syntax when separating a key from a value.

## Notable Differences to Liquid2

- All array literals must be surrounded by square brackets. Square brackets where optional in some cases in Liquid2.

- The tail filter operator `||` has been removed. Now parentheses should be used to apply the filter operator `|` to the desired sub expression.

## Deliberations

### Array and Variable Disambiguation

We use a trailing comma to syntactically differentiate array literals with a single string literal from a variable using bracketed syntax. `["some thing"]` is a variable where the variable name contains whitespace (or other reserved characters). `["some thing",]` is an array.

An alternative would be to use a JSONPath-style root selector, `$`. `$` would be implicit for unambiguous expressions, but required to disambiguate single element array literals and variables. `title == $.title == $["title"]`. `["title"]` is an array.

The former/current solution was chosen to avoid introducing a new symbol (`$`) and for backwards compatibility with Shopify/liquid.

### Overloaded Arithmetic Operators

An early draft of this spec included support for array and string repetition and concatenation using `*` and `+`. This was rejected to mitigate excessively large strings and arrays being generated programmatically by malicious template authors using `*`.

### `liquid` Tags

This specification does not play well with `{% liquid %}` tags, which are traditionally newline terminated. We would need to duplicate the grammar with a different definition of `S`.

### The Coalesce Operator

The ability for template authors to differentiate between missing data and `false`, `0`, `""` and `null` (or `nil`, `None`, `undefined`, etc.) is considered essential. The longhand solution is `x if x.defined? else y`. The equivalent coalesce expression is `x orElse y`.

We've considered using `??` or `otherwise` instead of `orElse` for the coalesce operator, and considered removing the operator altogether.
