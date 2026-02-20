# X. Expressions

Here we formally define an expression language that all template tags and the output statement must use.

## X.1 Overview

TODO:

TODO: Filters are allowed everywhere.

TODO: All values are immutable.

### X.1.1 Syntax

TODO:

```
Expr         ::= PipeExpr

PipeExpr     ::= CoalesceExpr
               | PipeExpr "|" Filter

CoalesceExpr ::= OrExpr
               | CoalesceExpr "??" OrExpr

OrExpr       ::= AndExpr
               | OrExpr "or" AndExpr

AndExpr      ::= CompareExpr
               | AndExpr "and" CompareExpr

CompareExpr  ::= AddExpr
               | AddExpr ("==" | "!=" | "<" | "<=", ">", ">=") AddExpr

AddExpr      ::= MulExpr
               | AddExpr ("+" | "-") MulExpr

MulExpr      ::= PrefixExpr
               | MulExpr ("*" | "/" | "%") PrefixExpr

PrefixExpr   ::= Primary
               | "not" PrefixExpr

Primary      ::= Literal
               | Variable
               | Primary "." Identifier
               | Primary "[" Expr "]"
               | "(" Expr ")"
```

### X.1.2 Semantics

Evaluation never fails. Every syntactically valid expression evaluates to a value and does not raise an error at render time.

```
⟦ e ⟧ : Environment → EvalValue
```

For every expression `e` and environment `ρ`:

```
⟦ e ⟧(ρ) ∈ EvalValue
```

That is, every operator and filter must be implemented as a total function over `EvalValue`.

## X.2 Data Types and Values

### X.2.1 Syntax

TODO: Move literals here?

### X.2.2 Semantics

Value types are split into _data values_ and _Nothing_. User data and developer-controlled global data are of type _DataValue_. The special _Nothing_ type indicates the absence of a value and is distinct from `Null` (or implementation-specific `nil` and `undefined`).

```
DataValue =
    Null
  | Boolean
  | Integer
  | Float
  | String
  | Array<DataValue>
  | Object<String, DataValue>

EvalValue =
    DataValue
  | Nothing

ArgValue =
    EvalValue
  | Lambda
```

TODO: `Range` does not exist at runtime. `(a..b)` evaluates to `Array<Integer>`.

TODO: Drops are coerced to primitive values using drop coercion methods.

TODO: The value domain is closed and finite.

#### X.2.2.1. The Null Type

TODO:

#### X.2.2.2. The Boolean Type

TODO:

#### X.2.2.3. The Integer Type

TODO:

#### X.2.2.4. The Float Type

TODO:

#### X.2.2.5. The String Type

TODO:

#### X.2.2.6. The Array Type

TODO:

#### X.2.2.7. The Object Type

TODO:

#### X.2.2.8. The Special Nothing Type

TODO:

Nothing can originate from:

- Missing variable
- Missing property
- Invalid operator usage
- Invalid conversion
- Explicit filter return

## X.3. Type Coercion

TODO: Primitive conversion functions

All conversion functions are total:

```
ToNumber : EvalValue → EvalValue
ToString : EvalValue → EvalValue
ToBoolean : EvalValue → EvalValue
```

## X.4 Literals

TODO:

#### X.4.2.1 Null Literal

TODO:

#### X.4.2.2 Boolean Literals

TODO:

#### X.4.2.3 Integer Literals

TODO:

#### X.4.2.4 Float Literals

TODO:

#### X.4.2.5 String Literals

TODO:

#### X.4.2.5 Array Literals

TODO:

#### X.4.2.5 Object Literals

TODO:

## X.5 Operators

TODO:

## X.6 Filters

TODO:

### X.6.1 Syntax

TODO:

```
Filter          ::= Identifier
                  | Identifier ":" ArgumentList

ArgumentList    ::= Argument ("," Argument)*

Argument        ::= Expr
                  | KeywordArgument

KeywordArgument ::= Identifier ("=" | ":") Expr
```

This yields:

- `a + b | f` → `(a + b) | f`
- `a and b | f` → `(a and b) | f`
- `a | f | g` → `((a | f) | g)`
- `x | f: (a + b)`
- `x | f: y | g` → `(x | f: y) | g`

Expression:

```
x | f: a, b, c
```

Desugars semantically to:

```
ApplyFilter(f, x, [a, b, c])
```

Nested case:

```
x | f: (y | g)
```

Desugars to:

```
ApplyFilter(
  f,
  x,
  [ ApplyFilter(g, y, []) ]
)
```

Filter arguments are full expressions.

### X.6.2 Semantics

A filter is a **named total function** registered in the environment.

```
FilterEnv : Identifier → FilterFunction
```

Where:

```
FilterFunction : EvalValue × List<ArgValue> → EvalValue
```

## X.7 Drops (Extension Types)

TODO:
