# descriptor-based-strings
A Forth strings package based on the on the technique of array slices.  First presented at EuroForth 2018

Our strings are descriptors that references a contiguous buffer with character data (1 char = 1 byte).
String descriptors are kept on the parameter stack and are a single cell stack items.
Strings are many-to-one: multiple string descriptors may reference the same character data in different 'cuts'.

The repository also includes a capable regular expression matcher in less than 200 lines of Forth code, including comments.
(The regex can be used with traditional `c-addr n` strings as well as our descriptor based strings).   
The regex falvor is Perl-like and the following syntax is supported

```
	| ^  | - beginning of a string (expected at the start of the regular expression)
	| ^^ | - beginning of a string and succeeding whitespaces (expected at the start of the regular expression)	
	| $  | - end of a string (expected at the end of the regular expression)
	| .  | - any character (including newline)
	| \  | - quote or special (precede a metacharacter with \ to let it stand for itself)
	| a* | - zero or more a's (a may be a quote or special character prefixed with \)
	| a+ | - one or more a's
	| a? | - zero or one a's (i.e. optional a)
	| ~a | - any character that is not a (i.e. except for a)
	| \t | - tab
	| \n | - linefeed
	| \r | - carriage return
	| \s | - any whitespace
	| \S | - any non-whitespace
	| \d | - any decimal digit
	| \h | - any hexadecimal digit - case insensitive
```

At present \ and ~ are not combinable (e.g. ~\d is not supported)

The regex code originated as a direct port of a C program written in 1998 by Rob Pike and Brian Kernighan
http://www.cs.princeton.edu/courses/archive/spr09/cos333/beautiful.html
