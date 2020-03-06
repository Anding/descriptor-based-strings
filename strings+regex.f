\ incorporate the regular expression matcher into the strings library
\ requires strings.f and regex.f (or a derivative)

: $match ( s$ r$ -- a$ b$ s$ TRUE | s$ FALSE)
\ Search for regex r$ in string s$ if the regexp is found, a$ is the
\ substring before the first match, b$ is the first match
\ s$ (modified) is the rest of the string and the TOS is true;
\ otherwise return false and preserve s$ unmodified
\ r$ is $drop'ed (recycled unless defined to be a permenent string)
\ a$, b$ and s$ all reference portions of the same character data in memory
\ See Ertl EF2013
	swap over over >R >R				( r$ s$ R:s$ r$)
	$s rot drop							( r$ s-addr s-n R:s$ r$)
	rot $s rot drop						( s-addr s-n r-addr r-n R:s$ r$)		\ traditional representations
	match 								( first len TRUE | FALSE R:s$ r$)
	IF																			\ match found
		R> $drop						( first len R:s$)						\ recycle r$ (unless permenent)
		over							( first len a-len R:s$)					\ compute length of substring before the first match
		R@ $dup	nip						( first len a-len a$ R:s$) 				\ make a duplicate of s$
		0 rot $sub						( first len a$ R:s$)					\ take the a$ substring
		R> swap >R >R					( first len R:a$ s$)
		over over						( first len first len R:a$ s$)
		R@ $dup nip						( first len first len b$ R:a$ s$)		\ make a duplicate of s$
		rot rot $sub					( first len b$ R:a$ s$)					\ take the b$ substring
		R> R> rot >R >R	>R				( first len R:b$ a$ s$)
		+								( next R:b$ a$ s$)						\ next is the next free character after the match
		R@ $len							( next s$ total R:b$ a$ s$)				\ total is the original string length
		rot swap over					( s$ next total next R:b$ a$ s$)
		- $sub drop						( R:b$ a$ s$)							\ take the s$ remainder substring
		R> R> R> rot true				( a$ b$ s$ true)
	ELSE																		\ no match
		R> $drop 																\ recycle r$ (unless permenent)
		R> 																		\ preserve s$
		false
	THEN
;

: $parse ( s$ r$ -- b$ s$ TRUE | s$ FALSE)
\ search for regexp b$ at the start of the text
\ with special conditions: 
\ (1) ignore leading whitespaces
\ (2) there must be a whitespace or end-of-string immediately following the match
	swap over over >R >R				( r$ s$ R:s$ r$)
	$s rot drop							( r$ s-addr s-n R:s$ r$)
	rot $s rot drop						( s-addr s-n r-addr r-n R:s$ r$)		\ traditional representations
	parse-match 						( first len TRUE | FALSE R:s$ r$)
	IF																			\ match found
		R> $drop						( first len R:s$)						\ recycle r$ (unless permenent)
		over over						( first len first len R:s$)
		R@ $dup nip						( first len first len b$ R:s$)			\ make a duplicate of s$
		rot rot $sub					( first len b$ R:s$)					\ take the b$ substring
		R> swap >R >R					( first len R:b$ s$)
		+								( next R:b$ s$)							\ next is the next free character after the match
		R@ $len							( next s$ total R:b$ s$)				\ total is the original string length
		rot swap over					( s$ next total next R:b$ s$)
		- $sub drop						( R:b$ s$)								\ take the s$ remainder substring
		R> R> swap true					( b$ s$ true)
	ELSE																		\ no match
		R> $drop 																\ recycle r$ (unless permenent)
		R> 																		\ preserve s$
		false
	THEN
;

: $trim ( s$ -- s$)
\ remove leading whitespaces from s$ by taking a substring to skip them
	$s s" \s+" initial-match			( s$ first len TRUE | s$ FALSE )
	IF nip 0 $prune THEN				( s$)
;

: $word ( s$ -- s$ b$)
\ parse s$, forth-style, extracting the first word b$ delimited by whitespaces
\ s$ (modified) is the rest of the string
\ return an empty string if no match is found
	$trim 
	$dup >R								( s$ R:b$)							
	$s s" \S+" initial-match			( s$ first len TRUE | s$ FALSE R:b$)
	IF
		2dup >R >R						( s$ first len R:b$ len first)
		+ 0 $prune						( s$ R: b$ len first)				\ the rest of the string
		R> R> R> -rot $sub				( s$ b$)							\ the word
	ELSE
		R> 0 0 $sub				( s$ b$)	\ b$ is an empty string
	THEN
;

: $replace ( s$ r$ t$ -- s$ true | s$ false)
\ search for regex r$ in s$ and if found replace the match with t$ and return true
\ if no match is found then return false
	>R over >R swap						( r$ s$ R:t$ s$)
	$s rot drop							( r$ s-addr s-n R:t$ s$)
	rot $s rot drop						( s-addr s-n r-addr r-n R:t$ s$)		\ traditional representations
	match 								( first len TRUE R:t$ s$ | FALSE R:t$ s$)
	IF 																			\ match found
		over swap R> -rot				( first s$ first len R:t$)
		$rem							( first s$ R:t$)
		swap R@ $s rot drop				( s$ first c-addr n R:t$)
		$ins							( s$ R:t$)
		R> $drop true					( s$ true)
	ELSE
		R> R> drop false
	THEN
;