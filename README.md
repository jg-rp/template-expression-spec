# A Unified Expression Grammar for Template Languages

This project defines a unified, implementation‑independent expression language for Liquid-style templates.

The specification focuses strictly on the internal mechanics of expressions. Notably, this document does not define the surrounding tag architecture (such as the specific implementation of `{% if %}` or `{% for %}`) nor does it provide a "standard library" of filters.

## Links

- HTML formatted spec: https://jg-rp.github.io/template-expression-spec/

## Status

Draft - specification in progress. Feedback and test cases are welcome.

Ruby code in this project's `lib` folder was/is used for testing grammar rules during spec development. It is NOT production ready.

## Tests

Test cases in the `test` folder do not yet give 100% coverage. Pull requests are welcome.

Although the spec doesn't define any standard filter implementations, we have defined some "mock" filters for testing purposes, which are currently undocumented.

## License

The project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
