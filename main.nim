import std/[
  os, # Using it for getting the command line arguments and checking
      # if files exist
  strutils,
  streams # Using this to read from files
]

import src/[
  lexing
]

# Probably not needed, will remove if redundant
var currently_parsing_files:seq[string]
# So we know if we already parsed a file in a module
var parsed_files:seq[string]

# We only accept one argument, quit if it isn't exactly 1
if paramCount() != 1:
  quit("Stellar only accepts one argument!", 1)

# Just verify if the file exists
var file = paramStr(1)
if not file.fileExists():
  if file.dirExists():
    quit("'" & file & "' is a directory! Must be a file!", 1)
  quit("'" & file & "' doesn't exist!", 1)

# The file that was passed as an argument
var code = readFile(file)

# The part that actually does stuff™
# Now let us lex the file~
var tokens = lexStellar(code)

# Debugging purposes
echo $tokens

# Commented because unimplemented
#[
# Parse the tokens generated from the file and build the ast
var ast = parseStellar(tokens)

# If a file is imported, it should lex that file
# and parse it, continuing until there are no more imports. Cyclic imports
# should not be allowed
# ---------------------
# Initialise the interpreter so multiple instances can be ran in parallel
# if desired by the developer
var interpreter = StellarInterpreter()
# Interpret the AST now!
interpreter.interpret(ast)
]#
