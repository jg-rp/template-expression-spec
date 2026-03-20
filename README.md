# A Unified Expression Grammar for Template Languages

This project defines a unified, implementation‑independent expression language for Liquid-style templates.

The specification focuses strictly on the internal mechanics of expressions. Notably, this document does not define the surrounding tag architecture (such as the specific implementation of `{% if %}` or `{% for %}`) nor does it provide a "standard library" of filters.

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
