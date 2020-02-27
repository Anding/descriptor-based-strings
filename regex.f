\ This code originated as a direct port of a C program written in 1998 by Rob Pike and Brian Kernighan
\ http://www.cs.princeton.edu/courses/archive/spr09/cos333/beautiful.html

: case? ( x1 x2 -- x1 ff | tf )  over = dup IF nip THEN ;

DEFER matchreps
DEFER matchc

\ During regular expression matching there is information about two strings located on the data stack:
\
\ 1. the text to match the regular expression against, given by addrT and uT
\ 2. the regular expression, given by addrR and uR
\
\     ( addrT uT addrR uR )
\
\ Many words work on these items, modify but do not consume them.


\ Define predicates that analyze characters
\ ------------------------------------------------------

: Regexrep? ( c -- flag )
\ one of the regular expression repetition characters?
    dup '*' = 			\ c* zero or more c's
    over '+' = or  		\ c+ one or more c's
    swap '?' = or  		\ c? zero or one c's (i.e. optional c)
;

: whitespace= ( c -- flag)
\ return true if c is a whitespace, or false otherwise
    dup bl =  over 10 = or  over 13 = or  swap 9 = or \ space, newline, cr, tab
;

\ Define words that manipulate or inspect the text
\ ------------------------------------------------------

: 'Text ( addrT uT addR uR -- addrT uT addR uR addrT )
	2over drop ;

: TextC ( addrT ut addrR uR -- addrT ut addrR uR c )
\ get first character of text and preserve the stack
     'Text c@
;

: Text? ( addrT uT addrR uR -- addrT uT addrR uR flag )
\ preserve the stack and indicate if Text has character
    2over nip ;

: advanceText ( addrT uT addrR uR -- addrT uT addrR uR)
\ advance the text by 1 character and preserve the stack
	2>R 1 - swap 1+ swap  2R>
;

: Text=c? ( addrT uT addrR uR c -- addrT uT addrR uR FLAG)
\ preserve the stack and indicate if Text matches literal character c
\ if c = . then any character will match
\ we are entitled to assume that uT >0
	'.' case? IF true EXIT THEN    \ pattern '.' matches any character
	>R	TextC  R> =					( ... FLAG )
;

: Text=\c? ( addrT uT addrR uR c -- addrT uT addrR uR FLAG)
\ preserve the stack and indicate if Text matches quote or special character c
\ we are entitled to assume that uT >0
	>R 2>R over c@					( addrT uT x R:c uR addrR)
	2R> rot R>						( addrT uT addrR uR x c)
	'd' case? IF  '0' '9' 1+  within  EXIT THEN			\ \d matches any decimal digit, equiv. to [0-9]
	'b' case? IF  '0' '1' 1+  within  EXIT THEN			\ \b matches any binary digit
	'h' case? IF 										\ \h matches any hexadecimal digit, case insensitive
			      dup '0' '9' 1+ within >R			( addrT ut addrR uR x R:flag)
			      dup 'A' 'F' 1+  within >R
			      'a' 'f' 1+  within
			      R> R> or or
		      EXIT THEN
	't' case? IF  9 = EXIT THEN							\ \t matches a tab (ASCII 9)
	'n' case? IF 10 = EXIT THEN							\ \n matches linefeed (ASCII 10)
	'r' case? IF 13 = EXIT THEN 						\ \r matches carriage return (ASCII 13)
	's' case? IF whitespace= EXIT THEN					\ \s matches any whitespace character
	'S' case? IF whitespace= 0= EXIT THEN				\ \S matches any non-whitespace character
	= 				 					( addrT ut addrR uR flag c)	\ treat any other character as itself (conserve the case parameter
;

\ character flags and masks
BASE @ 2 BASE !
0000000001111111 Constant #character
0000000100000000 Constant #special
0000001000000000 Constant #negated
's' #special or  Constant #special-s
BASE !

: Textc? ( addrT uT addrR uR c -- addrT uT addrR uR FLAG)
\ preserve the stack and indicate if Text matches character
	>R Text? 0= IF R> drop false EXIT THEN R>		\ no characters implies no match
	dup #character and 							( addrT uT addrR uR c bits0..6 )  \ split into the raw character and flags
	swap #special #negated or and 				( addrT uT addrR uR c bits0..6 bits8..9 )
	       0 case? IF Text=c?    EXIT THEN					\ unflagged literal character			
	#special case? IF Text=\c?   EXIT THEN					\ quote\special character
    #negated case? IF Text=c? 0= EXIT THEN					\ negated literal character
    			   IF Text=\c? 0= EXIT THEN					\ negated special character
	2drop FALSE		  										\ unsupported flag
;

\ Define words that manipulate or inspect the regular expression
\ ------------------------------------------------------

: RegexLen ( addrR uR -- addR uR f )
\ get length of regular expression and preserve stack
    dup
;

: RegexC ( addrR uR -- addrR uR c )
\ get first character of regular expression and preserve the stack
    over c@
;

: advanceRegex ( addrR uR -- addrR uR)
\ advance the regular expression by 1 character and preserve the stack
	1 - swap 1+ swap
;

\ uncomment these lines to support the REGEX characters '$'
\ : Regex$? ( addrR uR -- addrR uR FLAG)
\ \ preserve the stack and indicate if Regex is terminating in $
\ 	RegexC '$' =					( ... FLAG1 )			\ regexp is $
\ 	over 1 = 						( ... FLAG1 FLAG2)		\ regexp is 1 character in length
\ 	and
\ ;


\ Define words that analyze the regular expression, possible skipping inspected characters
\ ------------------------------------------------------

: ?Regexrep ( addrR uR -- addrR' uR' c )
\ indicate if Regex is repition requirement
\ the requirement is encoded in c, 0 if no repetition else repetition character
	RegexC
	dup Regexrep? IF >R advanceRegex R> EXIT THEN \ repetition character
	drop 0				\ no repetitions
;

: getRegexC ( addrT uT addrR uR -- addrT uT addrR uR c )
\ get the next character from Regex
\ quote or special characters preceeded by \ have a flag bit set (#special or)
\ negation characters preceeded by ~ have a flag bit set (#negated or)
	RegexLen 1 >
	IF	\ there is another character to follow - check for a special or negated
		RegexC '\' =	IF advanceRegex RegexC >R advanceRegex R> #special or EXIT THEN \ this is a special\quote character
		RegexC '~' =	IF advanceRegex RegexC dup '\' = IF drop advanceRegex RegexC >R advanceRegex R> #special #negated or or EXIT THEN
							>R advanceRegex R> #negated or EXIT THEN \ this is a negated character
	THEN \ neither special nor negated
	RegexC >R advanceRegex R> 					( addrT uT addrR uR c )
;


\ Define the pattern macthing
\ -----------------------------------

: matchhere ( addrT uT addrR uR -- addrN TRUE | addrT uT addrR uR FALSE)
\ search for regexp (addrR uR) at the start of text (addrT uT)
\ return the first character after the match (addrN) and TRUE
\ or FALSE and preserve the stack if there is no match here

	\ check the exit conditions first
	RegexLen 0= IF 2drop drop true EXIT THEN					\ a null Regex string means it has been fully matched!
	
\ 	uncomment these lines to support the REGEX characters '$'
\ 	Regex$? IF 													\ check for end-of-string match
\ 		Text? IF false EXIT THEN
\ 		2drop drop true EXIT
\ 	THEN

	\ perform the appropriate ongoing match
	getRegexC  >R  								( ... R:c)		\ obtain the next character of Regex and save it out of the way
	?Regexrep ?dup IF R> swap matchreps EXIT THEN				\ check if this is a repititon match
	R> matchc  													\ or a simple character match
;

:noname ( addrT uT addrR uR c -- addrN TRUE | addrT uT addrR uR FALSE )
\ search for character c at the beginning of text, if successful continue the match
	Textc?	IF advanceText matchhere EXIT THEN
	false
; is matchc

\ Define handling of pattern repetitions
\ --------------------------------------

: countreps ( addrT uT addrR uR c -- addrT uT addrR uR n)
\ count the number of repitions of c at the beginning of Text
\ consume Text of the repetitions
	0 >R >R							( addrT uT addrR uR R:n c)
	BEGIN														\ match 0 or more instances of c
		Text?
	WHILE
		R@ Textc?
	WHILE
		R> R> 1+ >R >R											\ matched, so increment the counter
		advanceText											\ and advance the text one character
	REPEAT THEN
	R> drop	R>						( addrT uT addrR uR n)
;

:noname ( addrT uT addrR uR c t -- addrN TRUE | addrT uT addrR uR FALSE )
\ search for repetitions of character c at the beginning of text, if successful continue the match
\ t encodes the requirement on repetitions
	>R								( addrT uT addrR uR c R:t)
	countreps 						( addrT uT addrR uR n R:t)
	R>
	'*' case? IF drop true      ELSE   \ c* zero or more c's
	'+' case? IF 0 >            ELSE   \ c+ one or more c's
	'?' case? IF 2 <            ELSE   \ c? zero or one c's (i.e. optional c)
	drop false THEN THEN THEN    	   \ should never be reached
	IF matchhere ELSE false THEN
; IS matchreps

\ matchreps and matchc reference each other need to be built with vectored execution


: anchored-match? ( addrT uT addrR uR -- addrT uT addrR uR addr0 FALSE | addrN addr0 TRUE )
   'Text >R 	 						( R:addr0)			\ save address zero of Text
\   advanceRegex
   RegexC '^' =  IF
    	advanceRegex
		#special-s countreps								\ overlook succeeding whitespaces
		R> + >R												\ move the corresp
   THEN
   matchhere 							( ... addrN TRUE | FALSE R:addr0)
   R> swap ;
 
\ : anchored-whitespace-match? ( addrT uT addrR uR -- addrT uT addrR uR addr0 start FALSE | addrN addr0 start TRUE )
\     'Text >R 	 							( R:addr0)				\ save address zero of Text
\ 	advanceRegex
\ 	#special-s countreps R> over >R + >R  	( ... R:addr0 start)	\ count 0 or more whitespaces
\ 	matchhere
\     R> R> rot ;

: match ( addrT uT addrR uR -- first len TRUE | FALSE )
\ search for regexp (addrR uR) anywhere in text (addrT uT)
\ return the position of the start of the match, the length of the match, and TRUE
\ or FALSE if there is no match

\ uncomment these lines to support the REGEX characters '^' and '!'
\     RegexC '^' = IF												\ look for an anchored match at the start of Text
\     	anchored-match?						( addrT uT addrR uR -- addrT uT addrR uR addr0 FALSE | addrN addr0 TRUE )
\ 		IF - 0 swap true EXIT THEN				  		 		    \ calculate length and start, exit true
\ 		drop 2drop 2drop false EXIT									\ if no match here, then no match at all
\ 	THEN
\ 
\ 	RegexC '!' = IF													\ look for an anchored match and whitepaces
\ 		anchored-whitespace-match?
\ 		IF >R - R> swap true EXIT THEN 								\ calculate length and start, exit true
\ 		drop drop 2drop 2drop false EXIT							\ if no match here, then no match at all
\ 	THEN

	'Text >R 	 							( addrT uT addrR uR R:addr0)	\ save address zero of Text
	BEGIN									( ... R:addr0)
		'Text >R  				            ( ... R:addr0 addrT)			\ save the present text address
		2dup 2>R 						    ( ... R:addr0 addrT addrR uR) 	\ save the full regex
		matchhere							( ... addrN TRUE | addrT uT addrR uR FALSE R: addr0 addrT addrR uR)
		IF 2R> 2drop R@ - R> R> - swap true EXIT							\ calculate length and start, exit true
		ELSE 2drop 2R> R> drop THEN			( ... R:addr0)					\ restore full regex - ready to try again
		Text?								( addrT uT addrR uR flag R:addr0)
	WHILE																	\ while we have some text to search, proceed
		advanceText
	REPEAT
	2drop 2drop R> drop	false												\ Text exhausted before a match was found
;

: initial-match ( addrT uT addrR uR -- first len TRUE | FALSE )
\ search for regexp at the start of the text, if TRUE len will always be 0
    	anchored-match?						( addrT uT addrR uR -- addrT uT addrR uR addr0 FALSE | addrN addr0 TRUE )
		IF - 0 swap true EXIT THEN				  		 \ calculate length and start, exit true
		drop 2drop 2drop false 							 \ if no match here, then no match at all	
;

: parse-match ( addrT uT addrR uR -- first len TRUE | FALSE )
\ search for regexp at the start of the text
\ with special conditions: 
\ (1) ignore leading whitespaces
\ (2) there must be a whitespace or end-of-string immediately following the match
    2over 2over 'Text >R 	 				( ... R:addr0)		\ save address zero of Text
	#special-s countreps R> over >R + >R  	( ... R:first start)\ pass through 0 or more whitespaces
	matchhere								( ... addrN TRUE | addrT uT addrR uR FALSE R: first start )
    R> R> rot								( ... addrN addr0 start TRUE | addrT uT addrR uR addr0 start FALSE )
    IF														\ matched ok, now check for a following whitespace or end of text
    	>R - R> swap 2dup >R >R				( addrT uT addrR uR first len R:len first)
    	+ -rot >R >R	dup >R				( addrT uT next R:len first uR addrR next)
    	- dup
    	IF										\ more text ok, now check for a following whitespace
    		swap R> + swap R> R> 			( addrT' uT' addrR uR R:len first)
    		#special-s countreps			( addrT' uT' addrR addrT count R:len first)
    		IF													\ following white space ok
    			2drop 2drop R> R> true 						
    		ELSE												\ no following whitespace
    			2drop 2drop R> R> drop drop false 			
    		THEN
    	ELSE													\ end of text (no need for a whitespace)
    		2drop R> drop R> R> 2drop R> R> true 			
    	THEN
    ELSE 														\ no match											
		drop drop 2drop 2drop 2drop 2drop false 
	THEN				
;