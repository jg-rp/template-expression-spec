# Universal Expression Grammar Semantics

The language defines a closed, context-free expression grammar with total operator availability and deterministic precedence.

---

> The ternary operator binds to the nearest expression. Inside filter arguments, it applies to the argument, not the filter chain.

```
a | plus: 23 if b else c | bar
```

is equivalent to

```
a | plus: (23 if b else c) | bar
```

---

`(a | foo) or b` is allowed, `a | foo or b` is not.

```
user.name | default: "guest" or "anonymous"
```

is equivalent to

```
user.name | default: ("guest" or "anonymous")

```

```
a if b else c | f | g
```

is equivalent to

```
a if b else (c | f | g)
```

---

---

`a | foo if b else c | bar` is equivalent to `(a | foo) if b else (c | bar)`

---
