\ incorporate the regular expression matcher into the strings library
\ requires strings.f and regex.f (or a derivative)

: $regex ( s$ r$ -- a$ b$ s$ TRUE | FALSE)
\ Search for regex r$ in string s$ if the regexp is found, a$ is the
\ substring before the first match, b$ is the first match
\ s$ (modified) is the rest of the string and the TOS is true;
\ otherwise return false and preserve s$ unmodified
\ r$ is $drop'ed (recycled unless defined to be a permenent string)
\ a$, b$ and s$ all reference portions of the same character data in memory
\ See Ertl EF2013
	swap over over >R >R				( r$ s$ R:s$ r$)
	$s									( r$ s-addr s-n R:r$ s$)
	rot $s								( s-addr s-n r-addr r-n R:r$ s$)		\ traditional representations
	match 								( first len TRUE | FALSE R:r$ s$)
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
		R> drop																	\ preserve s$
		false
	THEN
;

: $parse ( s$ r$ -- b$ s$ TRUE | FALSE)
\ Search for regex r$ at the start of string s$ ignoring whitespaces if the regexp is found
\ b$ is the first match
\ s$ (modified) is the rest of the string and the TOS is true;
\ otherwise return false and preserve s$ unmodified
\ r$ is $drop'ed (recycled unless defined to be a permenent string)
\ b$ and s$ all reference portions of the same character data in memory
	swap over over >R >R				( r$ s$ R:s$ r$)
	$s									( r$ s-addr s-n R:r$ s$)
	rot $s								( s-addr s-n r-addr r-n R:r$ s$)		\ traditional representations
	parse-match 								( first len TRUE | FALSE R:r$ s$)
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
		R> R> R> drop swap true			( b$ s$ true)
	ELSE																		\ no match
		R> $drop 																\ recycle r$ (unless permenent)
		R> drop																	\ preserve s$
		false
	THEN
;