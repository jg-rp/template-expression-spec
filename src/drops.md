## Extension Types (Drops)

Implementations may expose developer-defined objects known as Drops. A Drop is an object that can be coerced into a data value when required, with the help of a context hint.

$Drop$ is defined as an object implementing $ToLiquid$.

$$
ToLiquid : Drop × ContextHint → RuntimeValue
$$

Where:

$$
ContextHint ∈ { data, numeric, string, boolean, array, object }
$$

With the following constraints:

$$
\begin{aligned}
ToLiquid(drop, data)    \;& → DataValue \\
ToLiquid(drop, boolean) \;& → Boolean | Nothing \\
ToLiquid(drop, numeric) \;& → Number | Nothing \\
ToLiquid(drop, string)  \;& → String | Nothing \\
ToLiquid(drop, array)   \;& → Array\langle RuntimeValue \rangle | Nothing \\
ToLiquid(drop, object)  \;& → Object\langle String \to RuntimeValue \rangle | Nothing \\
\end{aligned}
$$

The result of $ToLiquid(drop, data)$ MUST be a valid $DataValue$ as defined above, meaning it MUST NOT contain $Drop$ at any depth.

The following table shows when each hint applies.

| Context                                      | Hint    |
| -------------------------------------------- | ------- |
| Arithmetic                                   | numeric |
| String concatenation                         | string  |
| Boolean test (`if`, `and`, `or`)             | boolean |
| Comparison                                   | data    |
| Filter arguments (general)                   | data    |
| Array literal spread, eager filter arguments | array   |
| Object literal spread                        | object  |

### Sequence Protocol

A Drop MAY implement the Sequence protocol to facilitate lazy iteration with the `for` tag or sequence aware filters.

$Sequence$ is defined as a $Drop$ that supports the following abstract behavior.

$$
\begin{aligned}
length() \;& \to Number \\
slice(offset, limit, reversed) \;& \to Drop \\
iterate() \;& \to Iterator\langle RuntimeValue \rangle \\
\end{aligned}
$$

Constraints:

- $length()$ MUST reflect the current logical sequence.
- $slice()$ MUST return a Drop implementing the Sequence protocol.
- $iterate()$ MUST yield exactly `length()` elements.

### Equality Protocol

A Drop MAY implement the Equality protocol for interaction with `==` and `!=` operators, without first coercing to a data value.

$Equals$ MUST NOT throw an error.

$$
Equals : Drop × RuntimeValue → Boolean | Nothing
$$

A Drop implements the Equality protocol if it supports:

$$
Equals(x) -> Boolean | Nothing
$$

### Ordering Protocol

A Drop MAY implement the Ordering protocol for interaction with `<`, `>`, `<=`, and `>=` operators, without first coercing to a data value.

$LessThan$ MUST NOT throw and error.

$$
LessThan : Drop × RuntimeValue → Boolean | Nothing
$$

A Drop implements the Ordering protocol if it supports:

$$
LessThan(x) -> Boolean | Nothing
$$

### Membership Protocol

A Drop MAY implement the Membership protocol for interaction with `in` and `contains` operators, without first coercing to a data value.

$Contains$ MUST NOT throw an error.

$$
Contains : Drop × RuntimeValue → Boolean | Nothing
$$

A Drop implements the Membership protocol if it supports:

$$
Contains(x) -> Boolean | Nothing
$$
