## Terminology

- _Expression_: An expression is the fundamental unit of computation within a Liquid template, representing a sequence of identifiers, literals, and operators that resolves to a value. They appear within output delimiters to render data directly to the page (e.g., `{{ user.name | upcase }}`), inside conditional tags to govern template logic (e.g., `{% if item.price > 100 %}`), and as the data sources for iterations (e.g., `{% for product in collections.frontpage %}`)

  For each of the preceding examples, this tables isolates the expression part of the markup to illustrate some of the places an expression can appear.

  | Markup                                       | Expression              |
  | -------------------------------------------- | ----------------------- |
  | `{{ user.name \| upcase }}`                  | `user.name \| upcase`   |
  | `{% if item.price > 100 %}`                  | `item.price > 100`      |
  | `{% for product in collections.frontpage %}` | `collections.frontpage` |

- _Filter_: TODO:
- _Markup_: TODO:
- _Lambda_: TODO:
