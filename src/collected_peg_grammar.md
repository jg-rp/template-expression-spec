# A. Collected PEG Grammar {.unnumbered}

```peg
Expression              ← TernaryExpr
             
B                       ← " " / "\t" / "\r" / "\n"    // Whitespace
S                       ← B*                          // Optional whitespace
C                       ← IdentifierChar              // Alias for any name character

Literal                 ← NumberLiteral /
                          StringLiteral /
                          BooleanLiteral /
                          NullLiteral /
                          ArrayLiteral /
                          ObjectLiteral /
                          RangeLiteral

NullLiteral             ← ("null" / "nil") !C

BooleanLiteral          ← ("true" / "false") !C

NumberLiteral           ← Integer Fraction? Exponent? !C
Integer                 ← "0" / [1-9] [0-9]*
Fraction                ← "." [0-9]+
Exponent                ← [eE] [+-]? [0-9]+

StringLiteral           ← DoubleQuoted / SingleQuoted
         
DoubleQuoted            ← "\"" (Interpolation / DoubleEscaped / Unescaped / "'")* "\""
SingleQuoted            ← "'"  (Interpolation / SingleEscaped / Unescaped / "\"")* "'"
         
Interpolation           ← "${" Expression "}"
         
DoubleEscaped           ← "\\" ( "\"" / Escapable )
SingleEscaped           ← "\\" ( "'" / Escapable )
         
Unescaped               ← LiteralDollar / SourceChar
LiteralDollar           ← "$" ! "{"
         
Escapable               ← "b" / "f" / "n" / "r" / "t" / "/" / "\\" / ("u" ~ HexChar) / "${"
HexChar                 ← NonSurrogate / HighSurrogate "\\u" LowSurrogate
HighSurrogate           ← [Dd] [AaBb89] [0-9A-Fa-f]{2}
LowSurrogate            ← [Dd] [CcDdEeFf] [0-9A-Fa-f]{2}
NonSurrogate            ← [AaBbCcEeFf0-9] [0-9A-Fa-f]{3} /
                          [Dd] [0-7] [0-9A-Fa-f]{2}
         
SourceChar              ← " " /
                          "!" /
                          "#" /
                          "%" /
                          "&" /
                          [\u0028-\u0058] /
                          [\u005D-\uD7FF] /
                          [\uE000-\u0010FFFF]

ArrayLiteral            ← "[" S (ArrayItem (S "," S ArrayItem)*)? S ","? S "]"
ArrayItem               ← SpreadExpr / Expression
SpreadExpr              ← "..." Expression

ObjectLiteral           ← "{" S (ObjectItem (S "," S ObjectItem)*)? S ","? S "}"
ObjectItem              ← SpreadExpr / KeyValuePair
KeyValuePair            ← ObjectKey S ":" S Expression
ObjectKey               ← Identifier / QuotedName
QuotedName              ← ( "\"" DoubleQuotedName "\"" ) / ( "'" SingleQuotedName "'" )

QuotedName              ← DoubleQuotedName / SingleQuotedName
     
DoubleQuotedName        ← "\"" ( DoubleEscapedName / NameSourceChar / "'")* "\""
SingleQuotedName        ← "'"  ( SingleEscapedName / NameSourceChar / "\"")* "'"
     
DoubleEscapedName       ← "\\" ( "\"" / EscapableNameChar )
SingleEscapedName       ← "\\" ( "'" / EscapableNameChar )
     
EscapableNameChar       ← "b" / "f" / "n" / "r" / "t" / "/" / "\\" / ("u" ~ HexChar)
     
NameSourceChar          ← " " /
                          "!" /
                          "#" /
                          "$" /
                          "%" /
                          "&" /
                          [\u0028-\u0058] /
                          [\u005D-\uD7FF] /
                          [\uE000-\u0010FFFF]

RangeLiteral            ← "(" S Expression S ".." S Expression S ")"

Identifier              ← IdentifierFirst IdentifierChar* !"?"
IdentifierFirst         ← [a-zA-Z_] / [\u{80}-\u{D7FF}] / [\u{E000}-\u{10FFFF}]
IdentifierChar          ← IdentifierFirst / [0-9]

Variable                ← VariableRoot Path?
VariableRoot            ← Identifier /
                          "[" S StringLiteral S "]"
           
Path                    ← (S Segment)+ Predicate?
Segment                 ← "." Identifier /
                          "[" S Expression S "]"
Predicate               ← "." IdentifierFirst IdentifierChar "?"

TernaryExpression       ← CoalesceExpression ( "if" !C CoalesceExpression "else" !C CoalesceExpression )?

CoalesceExpression      ← OrExpression ( S "orElse" !C S OrExpression )*

OrExpression            ← AndExpression ( S "or" !C S AndExpression )*
AndExpression           ← PrefixExpression ( S "and" !C S PrefixExpression )*
PrefixExpression        ← NotExpression / TestExpression
NotExpression           ← "not" !C S PrefixExpression

TestExpression          ← PipeExpression ( S TestOperator S PipeExpression )?
TestOperator            ← "==" / "!=" / "<=" / ">=" / "<" / ">" / ("in" !C) / ("contains" !C)

TestExpression          ← PipeExpression ( S TestOperator S PipeExpression )?
TestOperator            ← "==" / "!=" / "<=" / ">=" / "<" / ">" / ("in" !C) / ("contains" !C)

PipeExpression          ← ArithmeticExpression ( S "|" S FilterInvocation )*
FilterInvocation        ← Identifier ( S ":" S ArgumentList )?
ArgumentList            ← Argument ( S "," S Argument )*
Argument                ← LambdaExpression / KeywordArgument / ArgumentExpression
KeywordArgument         ← Identifier S ( "=" / ":" ) S ( LambdaExpression / ArgumentExpression )
LambdaExpression        ← LambdaArguments S "=>" S ArgumentExpression
LambdaArguments         ← Identifier / ( "(" S ( Identifier ( S "," S Identifier )* )? S ")" )
ArgumentExpression      ← ArithmeticExpression

ArithmeticExpression    ← AddExpression
AddExpression           ← MulExpression ( S ( "+" / "-" ) S MulExpression )*
MulExpression           ← UnaryExpression ( S ( "*" / "/" / "%" ) S UnaryExpression )*
UnaryExpression         ← NegExpression / PosExpression / PrimaryExpression
NegExpression           ← "-" UnaryExpression
PosExpression           ← "+" UnaryExpression

PrimaryExpression       ← Variable / Literal / ParenthesizedExpression
ParenthesizedExpression ← "(" S Expression S ")" Path?

```
