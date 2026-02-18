X.X Type System for Liquid Expressions

Liquid tags are composed of a tag name and zero or more expressions. Additional tag-specific keywords and punctuation contribute to tag syntax and semantics.

The output statement takes a single expression and renders it to the output buffer.

Historically, expression syntax and semantics have been a free-for-all in Liquid tags.

Here we formally define an expression language that all tags must use.

X.X.1 Value Universe

Value types are split into _data values_ and _Nothing_. User data and developer-controlled global data are of type _DataValue_. The special _Nothing_ type indicates the absence of a value and is distinct from `Null` (or implementation-specific `nil` and `undefined`).

```
DataValue =
    Null
  | Boolean
  | Integer
  | Float
  | String
  | Array<Value>
  | Object<String, Value>

EvalValue =
    DataValue
  | Nothing
```

TODO: `Range` does not exist at runtime. `(a..b)` evaluates to `Array<Integer>`.

TODO: Drops are coerced to primitive values using drop coercion methods.

TODO: The value domain is closed and finite.

X.X.1.1 The Null Type

TODO:

X.X.1.2 The Boolean Type

TODO:

X.X.1.3 The Integer Type

TODO:

X.X.1.4 The Float Type

TODO:

X.X.1.5 The String Type

TODO:

X.X.1.6 The Array Type

TODO:

X.X.1.7 The Object Type

TODO:

X.X.1.8 The Special Nothing Type

TODO:

X.X.1.2 Total Evaluation

Evaluation never fails. Every syntactically valid expression evaluates to a value and does not raise an error at render time.

```
⟦ e ⟧ : Environment → EvalValue
```

For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

That is, every operator and filter must be implemented as a total function over `EvalValue`.

X.X.1.3 Type Coercion

TODO:

X.X.1.4 Filters

TODO:

X.X.1.3 Drops

TODO:
