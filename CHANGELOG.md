## 2026-07-11

- Promoted `LambdaExpression` to be a `PrimaryExpression`
- Changed `LambdaExpression` to be stateless, not a closure.
- Changed `LambdaExpression` to allow `->` or `=>` to delimit parameters from expression.
- Changed `FilterInvocation` to accept `Variable` as a filter name, not just `Identifier`.

## 2026-03-29

- Changed `Segment` - as found in variable paths - to accept bracketed string literals, integer literals, or nested "queries". Previously any expression was syntactically allowed between square brackets.