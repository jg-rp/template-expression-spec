Your current **membership operator** section has a lot of branching because it treats:

- `Array`
- `Sequence`
- `Object`
- `String`
- `Drop`
- fallback coercion

as separate cases. Once `ToIterable` exists, you can collapse the **collection logic** to a single rule and keep only the genuinely special cases (`Drop` protocol, `Object`, `String`).

The key idea is:

> If something behaves like a sequence, normalize it with `ToIterable` and iterate.

Below is a **clean spec-style rewrite** that fits your document and removes the explicit `Array`/`Sequence` handling.

---

# Membership Operators

Membership tests (`contains` and `in`) determine whether a value appears
within a container.

Both operators return a `Boolean`.

- `element in container`
- `container contains element`

These forms are semantically equivalent with operands reversed.

Evaluation proceeds as follows.

---

## Membership Evaluation

Given a membership test:

```
element in container
```

evaluation proceeds as follows.

### 1. Drop Membership Protocol

If `container` is a `Drop` that implements the **Membership** protocol:

```
Contains(container, element) → Boolean | Nothing
```

then:

- If the result is `Boolean`, return that value.
- If the result is `Nothing`, continue evaluation using the following
  rules.

---

### 2. String Membership

If:

```
container is String
AND element is String
```

then membership tests **substring inclusion**.

Return `true` if `element` occurs within `container`, otherwise `false`.

---

### 3. Object Membership

If `container` is an `Object`, membership tests for the existence of a
key.

Evaluation proceeds as:

```
key = ToString(element)
```

Return `true` if `key` exists in the object, otherwise `false`.

---

### 4. Iterable Membership

Otherwise the container is treated as a sequence.

Normalize it using:

```
iterable = ToIterable(container)
```

Then iterate the sequence:

```
it = iterable.iterate()

repeat:
    v = it.next()
    if v is Nothing:
        return false

    if v == element:
        return true
```

---

## Semantics

This algorithm ensures that:

- Arrays behave as sequences.
- Drops implementing the **Sequence** protocol participate without
  materialization.
- Ranges and other lazy sequences work naturally.
- Scalars behave as single-element sequences via `ToIterable`.

Examples:

```
3 in [1,2,3]        → true
3 in (1..5)         → true
5 in 5              → true
"a" in "cat"        → true
"name" in {name:1}  → true
```

---

# Why this version is better

### 1. Removes type duplication

Your current rule had:

```
Array or Sequence
```

Now it's simply:

```
ToIterable(container)
```

which automatically covers:

- arrays
- lazy ranges
- sequence drops
- scalars

---

### 2. Centralizes iteration semantics

All iteration in the language now goes through:

```
ToIterable
```

which keeps the spec internally consistent.

---

### 3. Preserves Drop protocol priority

The `Contains` protocol still **overrides everything**, which is
important for things like:

```
product.tags contains "sale"
```

without forcing iteration.

---

### 4. Works naturally with future filters

Any filter that internally checks membership can use the **same logic**.

---

## Optional micro-simplification (nice but not required)

You can actually collapse **rules 2–4** further by treating strings and
objects as iterables too (strings → characters, objects → keys).

However that slightly changes semantics and might surprise template
authors, so your current explicit rules are safer.

---

If you'd like, I can also show you a **very elegant spec invariant involving `ToIterable`, `ToArray`, and `Sequence`** that can replace several explanatory paragraphs in the range section and make the document more formally consistent.
