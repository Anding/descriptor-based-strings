1 31 LSHIFT	CONSTANT MSB							\ define for the width of a CELL
BEGIN-STRUCTURE $.string							\ structure of an individual string descriptor
	FIELD: $.addr									\ pointer to the character buffer
	FIELD: $.len									\ highest bit = 0
	FIELD: $.size									\ highest bit of size = 1 for permenant 0 for temporary
	FIELD: $.start									\ highest bit = 0
END-STRUCTURE

989 CONSTANT err.NoFreeStrings						\ some error codes

variable $.data	0 $.data !							\ see $intialize

: $initialize ( N --)
\ create N free descriptors
\ $.data points to the first free descriptor, or = 0 if there is none
\ the $.addr field points to the next free descriptor or = 0 if there are none
	dup $.string * allocate THROW 			( N addr)		\ allocate space for N descriptor structures
	dup $.data !							( N addr)		\ $.data points to the first free descriptor
	swap 1 DO								( addr)
		dup $.string + dup					( addr addr+ addr+)
		rot !								( addr+)
	LOOP
	drop
;

: $.new ( -- s$)
\ obtain and return the next free string descriptor
	$.data @ ?dup							( addr addr | 0)
	0= IF err.NoFreeStrings THROW THEN		( addr 0 | err.NoFreeStrings)
	dup @ $.data !							\ repoint $.data to the next free descriptor
;

: $make ( c-addr len size flag -- s$)
\ Make a new string descriptor referencing a pre-existing character buffer at c-addr 
\ The character buffer contacts len bytes of valid data, starting at c-addr, 
\ and has total capacity of size bytes.  
\ If size > len then the string has spare capacity to be extended
\ flag = TRUE for a permenant string; FALSE for a temporary string
\ Memory management - the string descriptor belongs to string management
\ which takes care of necessary memory allocation
\ The character buffer is not modified or copied
	$.new									( c-addr len size flag s$)			\ s$ = address of the string descriptor
	rot rot IF MSB ELSE 0 THEN OR			( c-addr len s$ ^size)				\ set the MSB of size if FLAG = true
	over $.size !							( c-addr len s$)					\ remember size
	swap over $.len ! 						( c-addr s$)						\ remember len
	swap over $.addr !						( s$)								\ remember c-addr
	0 over $.start !						( s$)								\ set the start
;

: $drop ( s$ --)
\ allow string management to recycle a the descriptor of a temporary string
\ The character data itself is not deallocated
\ $drop is different to drop: with drop, the descriptor s$ remains valid and is not recycled
	dup $.size @ MSB and IF 
		drop												\ do not recycle permanent strings
	ELSE									( s$)
		dup $.string erase					( s$)			\ 'spoil' the string to discourage inadvertent reuse
		dup $.data @ swap !					( s$)			\ $.addr now points to the address of the next free descriptor
		$.data !											\ $.data now points to this (free) descriptor
	THEN
;

\ Temporary string descriptors are recycled when consumed by a word; permenant string descriptors are not
\ Consuming and recycling the descriptor of a temporary string does not affect / deallocate the character data itself

: $s ( s$ -- c-addr u)
\ provide a legacy reference to a string
	>R
	R@ $.addr @ R@ $.start @ +		( c-addr R:s$)
	R@ $.len @						( c-addr u R:s$)
	R> $drop											\ recycle the descriptor
;

: $len ( s$ -- s$ n)
\ return the length of a string in characters
\ we preserve s$ in the stack effect because to consume it would have been to recycle it, and we assume s$ will be used subsequently
	dup $.len @
;

: $size ( s$ -- s$ n)
\ return the size of the character buffer holding the string
	dup $.size @ 
	MSB invert and										\ ignore the MSB flag
;

: $dup ( s$ -- s$ r$)
\ Copy the string descriptor s$ to a new string descriptor r$
\ Both $s and $r are on the parameter stack
\ Both $s and $r reference the same character data in memory, but can take different cuts
\ $dup is different to dup: with dup, if s$ is subsequently modified, r$ is modified too
	$.new						( s$ r$)
	over over $.string			( s$ r$ s$ r$ n)
	move						( s$ r$)				\ copy the descriptor data
;

: $sub ( s$ a n -- s$)
\ Modify s$ to reference the substring starting at position a and running for n characters
\ a is calculated as an offset from the current start position, not the start of the buffer
\ a is permitted to be negative. n should be positive
	swap rot >R			( n a  R:s$)
	R@ $.start @ +		( n a' R:s$)					\ compute the new start position
	0 max				( n a' R:s$)					\ in case of negative a, do not recede to before the start of the buffer
	R@ $.size @ MSB invert and
	1- min				( n a' R:s$)					\ in case of positive a, do not advance beyond the last buffer character
	dup R@ $.start !	( n a' R:s$)					\ remember the new start position
	swap 0 max			( a' n R:s$)					\ constrain n to be non-negative
	over +				( a' b R:s$)					\ compute the new end position (actually one character after)
	R@ $.size @ MSB invert and 
	min					( a' b R:s$)					\ constrain the end position to be within the buffer
	swap -				( n' R:s$)						\ recompute len after applying this constraint
	r@ $.len ! R>		( s$)							\ remember the new len
;

: $app ( s$ c-addr u -- s$)
\ Append the text characters from c-addr u to s$ and return the augmented string
\ The length of the string is always truncated to fit within size
	rot >R
	R@ $.size @ MSB invert and	 			( c-addr u size R:s$)
	R@ $.len @ - 							( c-addr u size-len R:s$)
	R@ $.start @ -							( c-addr u v R:s$)				\ compute the spare capacity in s$
	min										( c-addr u' R:s$)				\ limit the append to spare capacity
	R@ $.addr @ R@ $.start @ + R@ $.len @ + swap	( c-addr dest u' R:s$)	\ compute the start destination for the copy
	dup >R 									( c-addr dest u' R:s$ u')
	move									( R:s$ u')
	R> R@ $.len +! R>						( s$)							\ update len
;

: $+ ( s$ r$ -- s$)
\ Append the contents of string r$ to s$ and return s$.
\ The length of the string is always truncated to fit within size
\ 	See Anton Ertl EF2013
\	\ s+ ( c-a1 u1 c-a2 u2 -- c-a3 u3 )
\	dir s" /" file s+ s+ r/o open-file throw
\	Becomes
\	dir s" /" $+ file $+ r/o open-file throw
\	provided that the string dir has sufficient free capacity to append "/<file>/"
	>R
	R@ $.addr @ R@ $.start @ +		( s$ c-addr R:r$)
	R@ $.len @						( s$ c-addr u R:r$)						\ locate the character data in r$
	$app							( s$ R:r$)								\ append r$ to the end of s$
	R> $drop																\ recycle r$
;

: $= ( s$ r$ -- s$ r$ flag)
\ Compare the character strings s$ and r$ and return true if they are equal
\ Note, this compares the characters in the buffer, not the descriptors
	over over $.len @ swap $.len @ dup rot <>
	IF drop false exit THEN						( s$ r$ len)				\ different lengths		
	>R $.addr @ swap $.addr @ R>				( s-addr r-addr len)
	0 DO
		over over c@ swap c@ <>
		IF false exit THEN													\ different character at this position
		1+ swap 1+ swap							( s-addr' r-addr') 
	LOOP
	true
;				
		
: $save ( s$ -- addr)
\ Call allocate to obtain sufficient memory, then copy the character data
\ referenced by s$ into memory as a counted string with cell-width counter
\ at addr.  If s$ references a sub-string, only that portion is copied
	>R
	R@ $.addr @ R@ $.start @ +		( c-addr R:s$)
	R@ $.len @						( c-addr u R:s$)						\ locate the character data in r$
	dup 1 cells + allocate THROW	( c-addr u addr R:s$)					\ allocate sufficient for a cell-counted string
	over over !						( c-addr u addr R:s$)					\ save the character count
	dup >R							( c-addr u addr R:s$ addr)
	1 cells + swap move				( R:s$ addr)							\ copy the character data
	R>								( addr R:s$)
	R> $drop						( addr)
;

: $rem ( s$ a n -- s$)
\ Remove n characters from s$ starting at position a
\ Following characters within the character buffer are moved as necessary
	rot >R
	over R@ $.len @	swap - min					( a n' R:s$)					\ validate n against the remaining length
	dup R@ $.len dup @ rot - swap !				( a n' R:s$)					\ update len
	swap R@ $.addr @ +							( n dest R:s$)					\ prepare dest and src for MOVE
	over over +									( n dest src R:s$)
	swap rot									( src dest n R:s$)
	move										( R:s$)
	R>											( s$)
;

: $ins ( c-addr u s$ a -- s$)
\ Copy the text characters from c-adder u into s$ at position a
\ Following characters within the character buffer are moved as necessary
\ The length of the string is always truncated to fit within size
	swap >R	swap								( c-addr a u R:s$)
	R@ $.size @ R@ $.len @ - min 				( c-addr a u' R:s$)				\ validate u against remaining capacity
	over R@ $.len @ swap -						( c-addr a u n R:s$)			\ no. of character to move to make space
	over R@ $.len dup @ rot + swap !			( c-addr a u' n R:s$)			\ update len
	rot R@ $.addr @ +							( c-addr u n src R:s$)
	>R over R@ +								( c-addr u n dest R:src s$)
	R@ swap rot									( c=addr u src dest n R:src s$)
	move										( c-addr u R:src s$)			\ make space - ready to insert
	R> swap										( c-addr src u R:s$)
	move										( r:s$)							\ insert
	R>											( s$)
;

