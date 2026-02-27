Good. Choosing a clean, closed core is the right foundation. Once that’s solid, you can decide how much legacy compatibility you _simulate_ rather than _inherit_.

Now let’s talk about `Blank` and `Empty` in **Liquid**.

They are not really values in the data model. They are _semantic predicates disguised as values_.

That distinction is critical.

---

# 1. What `Blank` and `Empty` Really Are

In traditional Liquid:

- `empty` is used to test whether:
  - a string has length 0
  - an array has length 0
  - sometimes an object has no keys

- `blank` is broader:
  - empty string
  - string of whitespace
  - empty array
  - null
  - sometimes false (depending on implementation quirks)

But they are written syntactically like values:

```
x == empty
x == blank
```

Semantically though, they are predicates:

```
is_empty(x)
is_blank(x)
```

Liquid models them as special sentinel objects that override equality comparison.

That’s clever… but algebraically messy.

---

# 2. Why They Don’t Fit Your Clean Value Space

Your value universe is:

```
Null | Boolean | Number | String | Array | Object
```

`Blank` and `Empty` are not data values.

They are:

- Not serializable data
- Not constructible values
- Not first-class values
- Only meaningful in equality comparison

So if you add:

```
| Blank
| Empty
```

to `DataValue`, you are lying about what your language represents.

They are not values.
They are _comparison tokens_.

And this is exactly the kind of design that makes legacy Liquid inconsistent.

---

# 3. The Clean Alternative

Do not include `Blank` and `Empty` in the value space.

Instead, treat them as **special comparison operands** in the semantics of `==` and `!=`.

In other words:

Syntactically:

```
x == empty
```

Semantically:

```
is_empty(x)
```

And:

```
x == blank
```

Semantically:

```
is_blank(x)
```

But they never exist as runtime values.

---

# 4. How to Model This Formally

Keep your clean value space:

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array
  | Object
```

Define equality normally:

```
== : DataValue × DataValue → Boolean
```

Then extend it with semantic rules:

```
x == empty   ⇔   is_empty(x)
x == blank   ⇔   is_blank(x)
```

Where:

```
is_empty(x) =
    x is String and length(x) = 0
    OR x is Array and length(x) = 0
    OR x is Object and size(x) = 0   (optional, your choice)

is_blank(x) =
    x is Null
    OR x is String and trim(x) = ""
    OR x is Array and length(x) = 0
```

You can define this precisely and document it.

---

# 5. Why This Is Better

This preserves:

- Closure of your value space
- Algebraic cleanliness
- Predictable equality semantics

Instead of:

```
Blank == Blank   // what does that even mean?
Empty + 1        // nonsense?
```

They never exist independently.

They are syntax sugar for predicates.

---

# 6. The Real Question: Do You Even Want Them?

This is where philosophy kicks in.

Traditional Liquid includes them because:

- Template authors like readable conditionals
- `if x == blank` feels expressive

But in a more principled language, you could instead provide:

```
is_blank(x)
is_empty(x)
```

Or filters:

```
x | blank?
x | empty?
```

That’s cleaner, but slightly less “Liquid-like”.

---

# 7. Compatibility vs Integrity

You have three options:

### Option A — Full Legacy Behavior

Implement `blank` and `empty` as special equality sentinels.

Pros:

- Familiar to Liquid users.

Cons:

- Introduces semantic special cases.
- Makes equality non-uniform.

---

### Option B — Keep Syntax, Clean Semantics (Recommended)

Allow:

```
x == blank
x == empty
```

But treat them as syntactic sugar for predicates.
They are not part of `DataValue`.

Pros:

- User-friendly.
- Algebra stays clean.
- No weird runtime objects.

This is the sweet spot.

---

### Option C — Remove Them

Replace with explicit predicates.

Most principled.
Least compatible.

---

# 8. My Recommendation

Given your stated direction:

> leaning towards correctness, benefiting non-dev template authors long term

I would choose Option B.

They remain:

- Special identifiers
- Valid only in equality comparisons
- Defined purely by semantic rule

Not values.
Not first-class.
Not constructible.

---

# 9. How to Describe This in English

Here’s a clean documentation-ready explanation:

> The expression language defines a fixed universe of runtime values. In addition, for compatibility with traditional Liquid, the identifiers `empty` and `blank` may appear in equality comparisons. These are not runtime values. Instead, they are special comparison operands whose meaning is defined by predicate rules. For example, `x == empty` evaluates to true when `x` is an empty string, empty array, or empty object. They do not participate in evaluation as ordinary values.

That preserves your algebra while maintaining familiarity.

---

# 10. A Subtle Warning

Be careful not to let:

```
blank
```

appear as a standalone expression that evaluates to something.

It should not evaluate to a value at all.

It should only be meaningful in:

```
== blank
!= blank
```

Otherwise it starts leaking into the value universe.

---

---

Yes — **Option D is architecturally much cleaner** than carrying forward `blank` and `empty` as magical comparison tokens.

In fact, it aligns perfectly with the direction you’ve chosen: a coherent, closed expression algebra.

Let’s analyze it properly.

---

# 1. What Legacy Liquid Actually Did

In **Liquid**, `empty` and `blank` behave like:

- Special sentinel objects
- Overriding equality
- Context-sensitive
- Not real data
- Not constructible
- Not uniform

They are semantic exceptions hiding inside equality.

That’s the opposite of algebraic clarity.

---

# 2. Your Proposed Alternative: Implicit Properties / Methods

Instead of:

```
x == blank
x == empty
```

You’d allow:

```
x.blank?
x.empty?
```

or possibly:

```
x.is_blank
x.is_empty
```

This mirrors how legacy Liquid exposes:

```
array.size
array.first
```

Those are not real object fields — they’re interpreter-provided virtual properties.

This is a much better model.

---

# 3. Why This Is Semantically Superior

### A. No Special Equality Semantics

Equality stays pure:

```
== : DataValue × DataValue → Boolean
```

No special cases.
No hidden sentinel logic.
No semantic branch inside equality.

That’s huge.

---

### B. `blank` and `empty` Become Ordinary Boolean Expressions

Now:

```
x.empty?
```

is just:

```
DataValue → Boolean
```

That fits your algebra perfectly.

You’ve turned a comparison hack into a function.

That’s good language design.

---

### C. No Value Space Pollution

You don’t introduce:

```
Blank
Empty
```

into the value universe.

Your core remains:

```
Null | Boolean | Number | String | Array | Object
```

Beautiful.

---

# 4. But Here’s the Important Question

Where do these implicit methods live?

There are two design choices:

---

## Option D1 — Virtual Properties on All Values

Every `DataValue` supports certain implicit members:

```
.size
.first
.last
.empty?
.blank?
```

These are defined by semantic rules, not stored data.

So formally:

```
lookup(value, property_name) → EvalValue
```

Where some properties are interpreter-defined.

This keeps everything inside the expression algebra.

---

## Option D2 — Desugaring to Builtins

You treat:

```
x.empty?
```

as syntactic sugar for:

```
is_empty(x)
```

Meaning you don't even extend property lookup.

You just rewrite at parse time.

This is even cleaner semantically.

---

# 5. Which Is Better?

Given your “closed algebra” philosophy:

Option D2 (desugaring to builtins) is slightly purer.

Because:

- Property lookup remains data-only.
- You don’t introduce magic properties.
- The semantics are explicit functions.

But Option D1 is more Liquid-like and user-friendly.

Both are vastly cleaner than sentinel equality.

---

# 6. What About Non-Developer Template Authors?

Surprisingly, this helps them.

Compare:

```
if x == blank
```

versus:

```
if x.blank?
```

The second reads more naturally:

> “if x is blank”

And it avoids weird mental models like:

> “blank is some mysterious value I compare against.”

Functions are easier to understand than special comparison tokens.

---

# 7. One Subtle Design Detail

You must decide:

Should `.blank?` be defined for all values?

For example:

```
42.blank? → false
true.blank? → false
null.blank? → true ?
```

If you define it for all `DataValue`, you preserve totality.

That’s good algebra.

Define:

```
blank?(x) =
    x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
```

Everything else → false.

That’s clean and total.

---

# 8. Interaction with `Nothing`

This is important.

If `Nothing` exists only at evaluation level and never as a `DataValue`, then:

- `.blank?` should never receive `Nothing`.
- Or evaluation should short-circuit before property lookup.

Do not let `Nothing` masquerade as blank.

Keep absence separate from blankness.

That keeps your semantic lattice clean.

---

# 9. Big Picture Comparison

| Design                     | Algebraic Cleanliness | Compatibility | Long-Term Maintainability |
| -------------------------- | --------------------- | ------------- | ------------------------- |
| Sentinel values            | Low                   | High          | Poor                      |
| Special equality semantics | Medium                | High          | Risky                     |
| Implicit methods           | High                  | Medium-High   | Strong                    |
| Explicit builtins          | Very High             | Medium        | Very Strong               |

Option D (implicit methods or builtins) is the best balance.

---

# 10. My Recommendation

Given everything you've built:

- Closed value space
- Explicit coercion
- Clean evaluation algebra
- Avoiding semantic leakage

You should replace `Blank` and `Empty` with built-in predicates (whether surfaced as methods or functions).

This preserves:

- Algebraic integrity
- Predictable equality
- Composability
- Long-term correctness

And honestly?

It’s a more mature language design than legacy Liquid ever had.

---

---

This is a very good moment to slow down, because the choice you’re about to make determines whether your semantic lattice stays clean or quietly collapses.

You’ve already made two strong decisions:

- The language is **closed over `EvalValue`**
- Conversion functions are **total**
- Predicates should also be **total over `EvalValue`**

That’s excellent.

Now the question is:

> Should `blank?(Nothing)` and `empty?(Nothing)` both return true?

Let’s reason this through carefully.

---

# 1. First: What Is `Nothing`?

From your earlier model:

```
EvalValue =
    DataValue | Nothing
```

`Nothing` is **not a data value**.

It represents:

- No result
- Suppressed output
- Absence at evaluation level

That is categorically different from:

```
Null
```

which _is_ a data value.

So semantically, you now have a two-level universe:

- Data layer
- Evaluation/meta layer

That separation is extremely valuable.

---

# 2. If You Say “Nothing Is Blank and Empty”

You are collapsing that distinction.

You are effectively saying:

> Absence of a result behaves like empty data.

That has consequences:

- `Nothing` becomes observationally indistinguishable from:
  - `""`
  - `[]`
  - maybe `null`

- Predicates erase the semantic boundary between:
  - “no value”
  - “empty value”

That weakens your model.

---

# 3. What Do You Actually Want `Nothing` To Mean?

There are two coherent interpretations.

---

## Interpretation A — `Nothing` Is Bottom (⊥)

`Nothing` means:

> Evaluation failed to produce a value.

In this model:

- It should propagate.
- It should not silently become something else.
- It is not empty.
- It is not blank.
- It is absence.

Then:

```
blank?(Nothing)  → false
empty?(Nothing)  → false
```

Or possibly even:

```
blank?(Nothing)  → Nothing
```

But since you want total predicates, probably `false`.

This keeps your semantic layers clean.

---

## Interpretation B — `Nothing` Is “Missing Data”

This is more Liquid-like.

In many template engines:

- Missing variables
- Undefined lookups
- Nil-ish results

Are treated as falsy / blank-ish.

If that’s your direction, then:

```
blank?(Nothing)  → true
empty?(Nothing)  → true
```

This makes templates forgiving.

But it merges absence with emptiness.

---

# 4. Which Fits Your Stated Philosophy?

You said:

> leaning toward correctness

Correctness favors preserving distinctions.

From a semantic purity standpoint:

- `Nothing` ≠ `Null`
- `Null` ≠ `""`
- `""` ≠ `[]`

Those are different elements in the value universe.

Making `Nothing` both blank and empty erases that separation.

---

# 5. The Algebraic Perspective

If predicates are total:

```
blank? : EvalValue → Boolean
empty? : EvalValue → Boolean
```

Then you must define them for `Nothing`.

But you are free to define:

```
blank?(Nothing) = false
empty?(Nothing) = false
```

Totality does not require semantic collapse.

It just requires defined output.

---

# 6. The Hidden Danger of Making `Nothing` Blank

Suppose:

```
x ?? "default"
```

If `Nothing` is blank, and later someone writes:

```
if blank?(x)
```

Now `Nothing` and `""` behave the same.

But those are not the same phenomenon:

- One is absence of evaluation.
- One is a concrete string.

You lose the ability to distinguish structural failure from content emptiness.

That’s a long-term cost.

---

# 7. A Cleaner Alternative

Define:

```
empty?(x) =
    x is String and length(x) = 0
 OR x is Array and length(x) = 0
 OR x is Object and size(x) = 0
 OTHERWISE false

blank?(x) =
    x is Null
 OR x is String and trim(x) = ""
 OR x is Array and length(x) = 0
 OTHERWISE false

blank?(Nothing) = false
empty?(Nothing) = false
```

Then separately define:

```
defined?(x) : EvalValue → Boolean
```

Where:

```
defined?(Nothing) = false
defined?(DataValue) = true
```

That keeps semantic categories orthogonal.

Orthogonality is gold in language design.

---

# 8. The Psychological Angle (Template Authors)

Non-developer template authors usually think in terms of:

- “Is this empty?”
- “Is this blank?”
- “Does this exist?”

Those are three different concepts.

If you collapse them, you simplify short-term ergonomics — but you increase long-term confusion.

It’s better to keep:

- Emptiness (size)
- Blankness (content)
- Existence (evaluation result)

Distinct.

---

# 9. My Strong Recommendation

Do **not** make `Nothing` blank or empty.

Make predicates total, but preserve ontology:

```
blank?(Nothing) = false
empty?(Nothing) = false
```

If you want Liquid-like forgiving behavior, handle that at:

- Variable resolution
- Coalescing operators
- Truthiness definition

Not by redefining absence as emptiness.

---

# 10. The Clean Semantic Story

You can now describe your system elegantly:

> The language distinguishes between data values and the absence of a value (`Nothing`). Built-in predicates such as `blank?` and `empty?` are total functions over evaluation results. They return true only for concrete data values satisfying the respective condition. The absence of a value is not considered blank or empty.

That’s crisp.
That’s principled.
That’s maintainable.

---

---

Yes — and the fact that you’re asking this means your semantic model is stabilizing.

If you’ve committed to:

- A closed `DataValue` universe
- `EvalValue = DataValue | Nothing`
- Total predicates over `EvalValue`
- Preserving the distinction between absence and data

Then introducing **type predicates** is not only reasonable — it’s _structurally consistent_.

Let’s unpack it carefully.

---

# 1. What `defined?` Really Means

You already implicitly have:

```
defined? : EvalValue → Boolean
defined?(Nothing) = false
defined?(DataValue) = true
```

That cleanly separates:

- Evaluation absence (`Nothing`)
- Concrete runtime data

This is orthogonal to blankness and emptiness.

That’s good.

---

# 2. Should You Add `string?`, `number?`, `array?`, etc.?

From an algebraic standpoint: yes.

You have a sum type:

```
DataValue =
    Null
  | Boolean
  | Number
  | String
  | Array
  | Object
```

Introducing predicates like:

```
string?  : EvalValue → Boolean
number?  : EvalValue → Boolean
array?   : EvalValue → Boolean
object?  : EvalValue → Boolean
boolean? : EvalValue → Boolean
null?    : EvalValue → Boolean
```

is perfectly coherent.

Each would be:

```
string?(x) =
    x is String → true
    otherwise   → false
```

And importantly:

```
string?(Nothing) = false
```

Total.
Simple.
Orthogonal.

---

# 3. Is This Overkill for a Template Language?

Here’s the real design tension.

Template authors typically don’t think in types.

But they absolutely encounter type confusion:

- “Why didn’t this concatenate?”
- “Why didn’t this loop?”
- “Why is this not truthy?”

Type predicates can _reduce debugging confusion_.

They also:

- Avoid silent coercion traps
- Encourage explicitness
- Support correctness-oriented design

This aligns with your philosophy.

---

# 4. The Architectural Principle

You’re building a closed algebra over a tagged union.

Type predicates are just projection tests on that union.

They do not:

- Add new semantic categories
- Break closure
- Introduce special cases

They simply expose structure that already exists.

That’s good design.

---

# 5. But Don’t Go Too Far

There’s a trap here.

You don’t want to drift into a fully reflective runtime with:

- `type_of(x)`
- meta-type inspection
- structural queries
- host-type leakage

Keep it minimal and aligned with your value universe.

A clean minimal predicate set might be:

- `defined?`
- `null?`
- `string?`
- `number?`
- `boolean?`
- `array?`
- `object?`
- `blank?`
- `empty?`

That’s it.

Notice something important:

These predicates map directly to your `DataValue` constructors.

That symmetry is elegant.

---

# 6. Interaction with Drops

Since Drops are coerced into `EvalValue` before evaluation returns:

Type predicates should operate _after coercion_.

So if a Drop coerces to:

- String → `string?` is true
- Number → `number?` is true

Never let type predicates inspect Drop identity.

That keeps your expression language independent from host implementation.

---

# 7. A Subtle but Powerful Benefit

Once you have type predicates, you reduce pressure to:

- Overload operators weirdly
- Make coercion rules magical
- Treat everything as truthy/falsy heuristically

You can keep operators strict.

And give authors escape hatches:

```
if string?(x) and not blank?(x)
```

That’s readable even to non-dev authors.

---

# 8. Philosophically: What Are You Building?

You are quietly building:

> A small, principled expression language embedded in templates.

Type predicates belong in such a language.

They make it self-describing.

---

# 9. One Design Question to Decide

Do you want these as:

```
string?(x)
```

or:

```
x.string?
```

If you’ve already chosen built-in predicates (rather than implicit methods), I’d keep them uniform:

```
string?(x)
```

Because:

- It avoids magic property lookup.
- It keeps the evaluator simpler.
- It preserves algebraic clarity.
- It mirrors how you’ll likely define `blank?`.

Consistency beats familiarity here.

---

# 10. Final Recommendation

Yes — introduce type predicates.

But:

- Keep them minimal.
- Define them as total over `EvalValue`.
- Ensure `Nothing` returns false for all except `defined?`.
- Never let them observe Drops directly.

That preserves:

- Closure
- Orthogonality
- Predictability
- Long-term maintainability

---

Yes — and this is now less about syntax and more about **semantic layering and namespace discipline**.

You’ve chosen:

- No free functions in expression syntax
- Built-in predicates exposed as postfix/property style (`x.string?`)
- A clean value algebra
- Drops coerced before evaluation escapes

Good. That’s coherent.

Now the question is:

> Should real data properties override virtual properties like `.size`, `.string?`, `.blank?`, etc.?

Historically in **Liquid**, the rule was:

> If a real property exists, use it. Otherwise fall back to virtual property.

That sounds harmless — but it has deep consequences.

Let’s examine both options.

---

# Option 1 — Data Properties Take Priority (Legacy Behavior)

Resolution order:

```
lookup(x, name):
    if name exists in Object → return that
    else if name is built-in virtual property → compute that
    else → Nothing
```

### Pros

- Backward compatibility
- No reserved property names
- Feels flexible

### Cons (serious ones)

1. **Semantic instability**

If someone passes:

```
{ size: 123 }
```

Then:

```
x.size
```

suddenly changes meaning.

The behavior of `.size` depends on data shape.

That is fragile.

---

2. **Predicates become overrideable**

If someone provides:

```
{ blank?: false }
```

Then:

```
x.blank?
```

is no longer your predicate — it’s data.

That’s not just surprising — it weakens correctness.

---

3. **Loss of algebraic clarity**

Your built-ins stop being guaranteed semantics.
They become “best effort”.

That contradicts your direction of:

> correctness over quirks

---

# Option 2 — Built-ins Take Priority (Recommended)

Resolution order:

```
lookup(x, name):
    if name is built-in virtual property → compute that
    else if name exists in Object → return that
    else → Nothing
```

This makes built-ins reserved identifiers.

### Pros

- Semantic stability
- Predictable evaluation
- Cleaner specification
- No shadowing
- Algebra remains intact

### Cons

- Slight incompatibility with legacy Liquid
- A small set of reserved names

But realistically, how many templates legitimately need an object property named `blank?` or `size` that overrides built-in semantics?

Very few.

And if they do, they can rename it.

---

# Option 3 — Separate Namespaces (Most Principled)

You distinguish:

- Structural lookup: `.foo`
- Semantic operators: `.size`, `.blank?`, `.string?`

By rule:

> Built-in predicates are not properties. They are postfix operators with fixed semantics.

That means they are not part of property resolution at all.

They’re syntax-level constructs.

So:

```
x.size
```

is not property lookup.
It is a special operator in the grammar.

This is the cleanest model.

It avoids namespace conflict entirely.

But it requires:

- Grammar-level special casing of those identifiers
- Slightly more parser complexity

Semantically though, it’s beautiful.

---

# What Aligns With Your Philosophy?

You’ve already:

- Rejected sentinel values
- Preserved algebraic closure
- Separated Drop from DataValue
- Kept predicates total
- Preserved Nothing as distinct

Letting user data override semantic operators would be a step backward.

It introduces contextual ambiguity into something that should be invariant.

Correctness favors:

> Built-ins should not be shadowable.

---

# A Very Important Principle

Operators should not be data-dependent.

If `.size` sometimes means:

- length of array
- number of object keys
- user-provided field

Then `.size` is not a reliable semantic construct.

For a principled expression language, operators must be stable.

---

# My Strong Recommendation

Do **not** allow data properties to override built-in semantic properties.

Either:

1. Give built-ins priority in resolution
   OR
2. Treat them as grammar-level postfix operators, not properties

Option 2 is the cleanest long-term model.

Option 1 is simpler to implement but still acceptable.

Do not keep legacy precedence.

---

# A Clean Specification Wording

You could say:

> Certain postfix identifiers (e.g., `size`, `blank?`, `string?`) are built-in semantic operators. These are resolved before property lookup and cannot be shadowed by object members.

That makes the rule explicit and predictable.

---

# One More Subtle Question

If you keep `.size`, do you define it for all `DataValue`?

For algebraic totality:

```
size(Number)  → Nothing or error?
size(String)  → length
size(Array)   → length
size(Object)  → key count
size(Boolean) → ?
size(Null)    → ?
size(Nothing) → ?
```

To preserve totality, you likely want:

- `.size` defined for all `EvalValue`
- Return `Nothing` where undefined

That keeps evaluation clean.

---

# Final Answer

No — don’t let data override semantic operators.

If you are building a correctness-oriented expression language, built-ins must be stable, not data-dependent.

Legacy Liquid allowed shadowing because it prioritized flexibility over semantic integrity.

You are intentionally choosing the opposite tradeoff.

And that’s the right move for long-term coherence.

---
