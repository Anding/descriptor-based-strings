1 31 LSHIFT	CONSTANT MSB							\ define for the width of a CELL
BEGIN-STRUCTURE $.string							\ structure of an individual string descriptor
	FIELD: $.addr									\ pointer to the character buffer
	FIELD: $.len									\ highest bit = 0
	FIELD: $.size									\ highest bit of size = 1 for permenant 0 for temporary
	FIELD: $.start									\ highest bit = 0
END-STRUCTURE

989 CONSTANT err.NoFreeStrings						\ some error codes

variable $.data	0 $.data !							\ see $intialize
variable $.free										\ number of free descriptors

: $initialize ( N --)
\ create N free descriptors
\ $.data points to the first free descriptor, or = 0 if there is none
\ the $.addr field points to the next free descriptor or = 0 if there are none
	dup $.free !							( N)			\ save the number of free descriptors
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
	-1 $.free +!							\ update the number of free descriptors
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

: $perm ( s$ -- s$ flag)
\ return true for a permenant string, false otherwise
	dup $.size @
	MSB and 0= 0=
;

: $drop ( s$ --)
\ allow string management to recycle a the descriptor of a temporary string
\ The character data itself is not deallocated
\ $drop is different to drop: with drop, the descriptor s$ remains valid and is not recycled
	$perm IF 
		drop												\ do not recycle permanent strings
	ELSE									( s$)
		dup $.string erase					( s$)			\ 'spoil' the string to discourage inadvertent reuse
		dup $.data @ swap !					( s$)			\ $.addr now points to the address of the next free descriptor
		$.data !											\ $.data now points to this (free) descriptor
	1 $.free +!												\ update the number of free descriptors		
	THEN
;

: $nip ( s$ x -- x)
\ companion to $drop, for convenience
	swap $drop
;

\ Temporary string descriptors are recycled when consumed by a word; permenant string descriptors are not
\ Consuming and recycling the descriptor of a temporary string does not affect / deallocate the character data itself

: $s ( s$ -- s$ c-addr u)
\ provide a legacy reference to a string
	>R
	R@ $.addr @ R@ $.start @ +		( c-addr R:s$)
	R@ $.len @						( c-addr u R:s$)
	R> rot rot
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

: $start ( s$ -- s$ n)
\ return the position of the first character in the buffer
	dup $.start @
;

: $addr ( s$ -- s$ addr)
\ return the address of the start of the string buffer
	dup $.addr @
;

: $dup ( s$ -- s$ r$)
\ Copy the string descriptor s$ to a new string descriptor r$
\ Both $s and $r are on the parameter stack
\ Both $s and $r reference the same character data in memory, but can take different cuts
\ $dup is different to dup: with dup, if s$ is subsequently modified, r$ is modified too
\ permenant strings are duplicated to permenant strings
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

: $prune ( s$ x y -- s$)
\ Modify s$ by taking a substring skipping x characters from the start and y characters from the end
\ x and y are permitted to be negative if the string buffer contains additional characters on the start and end of the string
\ boundaries are checked and overpruning simply results in a null string
	>R >R $len			( s$ len R:y x )
	R@ -				( s$ len' R:y x)
	R> swap				( s$ a len' R:y)
	R> -				( s$ a n)
	$sub
;

: $write ( s$ c-addr u -- s$)
\ write the text characters from c-addr u to s$ as an append and return the augmented string
\ if necessary, the write is truncated to fit within size
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
	$write							( s$ R:r$)								\ append r$ to the end of s$
	R> $drop																\ recycle r$
;

: $= ( s$ r$ -- s$ r$ flag)
\ Compare the character strings s$ and r$ and return true if they are equal
\ Note, this compares the characters in the buffer, not the descriptors
	over over $.len @ swap $.len @ dup rot <>	( s$ r$ len flag)
	IF drop false exit THEN						( s$ r$ len)				\ check if different lengths	
	?dup 0= IF true exit THEN					( s$ r$ len)				\ check if both zero length
	>R over over dup $.addr @ swap $.start @ +	( s$ r$ s$ r-addr R:len) 
	swap dup $.addr @ swap $.start @ + R>		( s$ r$ s-addr r-addr len)
	0 DO
		over over c@ swap c@ <>
		IF unloop drop drop false exit THEN										\ different character at this position
		1+ swap 1+ swap							( s$ r$ s-addr' r-addr') 
	LOOP
	drop drop true
;				
		
: $rem ( s$ a n -- s$)
\ Remove n characters from s$ starting at position a
\ Following characters within the character buffer are moved as necessary
\ $rem updates the character buffer!
	rot >R
	over R@ $.len @	swap - min					( a n' R:s$)					\ validate n against the remaining length
	dup R@ $.len dup @ rot - swap !				( a n' R:s$)					\ update len
	swap R@ $.addr @ +							( n dest R:s$)					\ prepare dest and src for MOVE
	over over +									( n dest src R:s$)
	swap rot									( src dest n R:s$)
	move										( R:s$)
	R>											( s$)
;

: $ins ( s$ a c-addr u -- s$)
\ Copy the text characters from c-addr u into s$ at position a
\ Following characters within the character buffer are moved as necessary
\ The length of the string is always truncated to fit within size
	2swap swap >R swap							( c-addr a u R:s$)
	R@ $.size @ R@ $.len @ - R@ $.start @ - min ( c-addr a u' R:s$)				\ validate u against remaining capacity
	over R@ $.len @ swap -						( c-addr a u n R:s$)			\ no. of character to move to make space
	over R@ $.len dup @ rot + swap !			( c-addr a u n R:s$)			\ update len
	rot R@ $.addr @ +							( c-addr u n src R:s$)
	>R over R@ +								( c-addr u n dest R:s$ src)
	R@ swap rot									( c=addr u src dest n R:s$ src)
	move										( c-addr u R:s$ src)			\ make space - ready to insert
	R> swap										( c-addr src u R:s$)
	move										( r:s$)							\ insert
	R>											( s$)
;

