from pest import Parser

with open("expression.pest") as fd:
    GRAMMAR = fd.read()

PARSER = Parser.from_grammar(GRAMMAR)

expr = "'Hello \\${you}!'"
pairs = PARSER.parse("expression", expr)

print(pairs.dumps())
