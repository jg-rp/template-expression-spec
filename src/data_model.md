# Type System for Template Expressions

The expression language operates on a data model that is conceptually "JSON-like". Every expression, when evaluated, resolves to a value belonging to one of the fundamental types defined in this section.

The core types - `Null`, `Boolean`, `Number`, `String`, `Array`, and `Object` - map directly to JSON types. Any valid JSON document can be represented naturally within this expression language.

All values in the data model are immutable. Operations that appear to "modify" a value (such as filter applications) always return a new value.

To allow templates to interact with complex application logic, the language supports "Drops". These are opaque extension types provided by the host environment that can implement specific protocols for iteration, property access, or equality.

## Values

$DataValue$ defines all possible kinds of value that can exist inside the template data model.

$$
\begin{aligned}
DataValue = \;& Null \\
  | \;& Boolean \\
  | \;& Number \\
  | \;& String \\
  | \;& Array\langle DataValue \rangle \\
  | \;& Object\langle String \to DataValue \rangle \\
\end{aligned}
$$

$RuntimeValue$ describes the result of evaluating an expression. Note that $DataValue$ is the subset of $RuntimeValue$ that does not contain $Drop$ or $Nothing$.

$$
\begin{aligned}
RuntimeValue = \;& DataValue \\
  | \;& Array\langle RuntimeValue \rangle \\
  | \;& Object\langle String \to RuntimeValue \rangle \\
  | \;& Drop \\
  | \;& Nothing
\end{aligned}
$$

$Nothing$ represents the absence of a value produced during evaluation and is distinct from $Null$ (or implementation-specific `nil`, `None`, `undefined` etc.).

## Numeric Types {#sec:numeric_types}

$Number$ represents a decimal numeric value with arbitrary precision and exact decimal semantics.

Implementations MUST perform numeric operations using a decimal arithmetic model. Binary floating-point (e.g., IEEE-754 double) MUST NOT be used as the semantic numeric model.

An implementation MAY use binary floating-point internally, but observable behavior MUST match exact decimal arithmetic.

Integer values are a subset of `Number`. A number is considered an integer when its decimal representation has no fractional component.

### Decimal Arithmetic Model

The language defines numbers using base-10 decimal semantics:

- Exact representation of finite decimal literals.
- Exact addition, subtraction, and multiplication.
- Exact division when representable as a finite decimal.
- Deterministic rounding when required.

This ensures:

```
0.1 + 0.2 == 0.3   → true
```

in all conforming implementations.

Implementations MUST NOT introduce binary floating-point rounding artifacts.

Example (required behavior):

```
0.1 + 0.2
```

MUST evaluate to a number equal to decimal `0.3`.

It MUST NOT produce:

```
0.30000000000000004
```

### Division Semantics

Division may produce a non-terminating decimal expansion.

Example:

```
1 / 3
```

TODO: Loosen precision requirements

Implementations MUST use decimal division with a minimum precision of 28 decimal digits and MUST round using round-half-even (banker’s rounding), unless a higher precision is supported.

The precision used MUST be consistent within an evaluation.

### Numeric Equality

Numeric equality is mathematical equality after decimal normalization.

Examples:

```
1 == 1.0        → true
0.30 == 0.3     → true
```

### String Conversion

$ToString(Number)$ MUST produce a canonical decimal representation:

- No scientific notation.
- No unnecessary trailing zeros.
- No trailing decimal point.

TODO: true division  
TODO: no decimal point when operands are integers and result is whole

Examples:

```
1       → "1"
1.0     → "1"
0.300   → "0.3"
1000    → "1000"
```

## Iterables

Some evaluation algorithms operate on _iterable_ values. An $Iterable$ is either an $Array$ or $Sequence$:

$$
Iterable = Array\langle RuntimeValue \rangle | Sequence
$$

Where $Sequence$ is a $Drop$ implementing the Sequence protocol.

Array and sequence drops MUST behave identically with respect to iteration semantics.

## Data Type Summary

| Type         | Description                                               | JSON Equivalent |
| ------------ | --------------------------------------------------------- | --------------- |
| **Nothing**  | Represents the absence of a data value.                   | N/A             |
| **Null**     | Represents a deliberate "empty" data value.               | `null`          |
| **Boolean**  | Logical `true` or `false`.                                | `true`, `false` |
| **Number**   | An exact decimal representation (see @sec:numeric_types). | `number`        |
| **String**   | A sequence of Unicode characters.                         | `string`        |
| **Array**    | An ordered list of values.                                | `array`         |
| **Object**   | A collection of key-value pairs (where keys are Strings). | `object`        |
| **Drop**     | A host-provided extension type.                           | N/A             |
| **Iterable** | An array, or drop implementing the sequence protocol      | N/A             |
