import std/[
  streams, # We read the file data from a stream
  strutils # This is so we can do things like checking if a string is an int
]

import ./misc
import ./exceptions

type TokenType* = enum
  # Arithmatic Operators
  Plus     # Addition
  Times    # Multiplication
  Subtract # Subtraction
  Divide   # Division
  Modulo   # Modulus
  Exponent # Exponents

  # Relational Operators
  Assign       # Assignment
  Equality     # Equality
  Inequality   # Inequality
  GreaterThan  # Greater Than
  LesserThan   # Lesser Than
  GreaterEqual # Greater Than or Equal To
  LesserEqual  # Lesser Than or Equal To

  # Logical Operators
  And # And
  Or  # Or
  Not # Not

  # Misc Operators
  Concat # ..
  Hash # `#`, also rename `Hash` to something better

  # Types
  String  # Strings like `"Hello World!"`
  Integer # Internally, floats and integers are different, to the Lua code
  Float   # though, they're treated as the same
  True    # Figure out why it uses true and false to represent booleans
  False   # instead of individual types

  # Misc
  LParen     # Open paren `(`
  RParen     # Close paren `)`
  Comma      # Comma for splitting arguments
  Identifier # Identifiers include names such as `print` or `var1`
  EndOfFile  # EOF


type Token* = object
  typ*: TokenType
  text*: string
  startPos*: int

proc newToken(typ: TokenType, text: string, startPos: int): Token =
  result = Token(typ: typ, text: text, startPos: startPos)

proc newToken(typ: TokenType, text: char, startPos: int): Token =
  result = Token(typ: typ, text: $text, startPos: startPos)

proc `$`*(token: Token): string =
  result = "(typ: " & $token.typ & ", text: " & quoted(token.text)
  result &= ", startPos: " & $token.startPos & ")"

# Generic lex function that takes a string
proc lex(code: string, curPos: var int): seq[Token] =
  # Internal pos
  var intPos = 0

  # Internal pos is used for navigating the code while curPos is used for
  # keeping track of where a token starts
  template increment() =
    intPos += 1
    curPos += 1

  while intPos < code.len-1:
    # Use the internal pos because it may be a line of code only
    # (from a stream)
    let lookahead = code[intPos]
    # The token start pos
    let startPos = curPos

    # Operators
    if lookahead == '+':
      result.add newToken(Plus, lookahead, startPos)
      increment()
    elif lookahead == '*':
      result.add newToken(Times, lookahead, startPos)
      increment()
    elif lookahead == '-':
      result.add newToken(Subtract, lookahead, startPos)
      increment()
    elif lookahead == '/':
      result.add newToken(Divide, lookahead, startPos)
      increment()
    elif lookahead == '%':
      result.add newToken(Modulo, lookahead, startPos)
      increment()
    elif lookahead == '^':
      result.add newToken(Exponent, lookahead, startPos)
      increment()

    # Misc
    elif lookahead == '(':
      result.add newToken(LParen, lookahead, startPos)
      increment()
    elif lookahead == ')':
      result.add newToken(RParen, lookahead, startPos)
      increment()

    elif lookahead == ',':
      result.add newToken(Comma, lookahead, startPos)
      increment()

    # If it's whitespace, ignore
    elif lookahead.isEmptyOrWhitespace:
      increment()

    # Collect the digits together into one number
    elif lookahead.isDigit:
      # Create the lexmeme
      var lexeme = $lookahead
      #increment()

      while intPos < code.len-1:
        increment()
        # If it isn't a valid identifier, disallow it
        if not code[intPos].isDigit or code[intPos] != '.':
          raise newException(LexingError,
            "The number " & lexeme.quoted & " at position " & $startPos & " couldn't be constructed!")

        # Break the loop when there's a whitespace
        elif code[intPos].isEmptyOrWhitespace:
          break

        # Add the value to the lexeme
        lexeme &= code[intPos]

      # Check how many times '.' occurs in the string
      let dotCount = lexeme.count('.')
      if dotCount == 0:
        # Add a token with the type integer (internal use only)
        result.add newToken(Integer, lexeme, startPos)
      elif dotCount == 1:
        # Add a token with the type float (internal use only)
        result.add newToken(Float, lexeme, startPos)
      else:
        # If the lexeme contains more than one '.', it's invalid!
        raise newException(LexingError,
          "The number '" & lexeme & "' at position " & $startPos & " is invalid!")

    # All identifiers begin with alphabetic characters
    elif lookahead.isAlphaAscii:
      # Create the lexeme
      var lexeme = $lookahead
      #increment()

      while intPos < code.len-1:
        increment()
        # Break the loop when there's a character we should break for
        if code[intPos].isBreakageChar:
          break

        # It can now be alphanumeric in identifiers
        elif not code[intPos].isAlphaNumeric:
          raise newException(LexingError,
            "The identifier " & lexeme.quoted & " at position " & $startPos & " couldn't be constructed!")

        # Add the value to the lexeme
        lexeme &= code[intPos]

      case lexeme
        of "true":
          result.add newToken(True, lexeme, startPos)
        of "false":
          result.add newToken(False, lexeme, startPos)
        else:
          result.add newToken(Identifier, lexeme, startPos)

    elif lookahead == '"':
      # The beginning of the lexeme
      increment()
      var lexeme = $code[intPos]

      while intPos < code.len-1:
        increment()

        if code[intPos] == '"':
          break

        lexeme &= code[intPos]

      increment()
      result.add newToken(String, lexeme.quoted, startPos)

    else:
      raise newException(LexingError,
        "Unknown character '" & code[intPos] & "' from position " & $curPos)



# TODO: Make it so we accept a stream instead of/as well as a string
proc lexStellar*(code: string): seq[Token] =
  # The current position of the lexer
  var curPos = 0

  result = code.lex(curPos)
  result.add newToken(EndOfFile, "<EOF>", curPos)
