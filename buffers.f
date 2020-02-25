\ extend the strings library to provide memory buffer library
\ requires strings.f

: $buffer ( n -- s$)
\ allocate a buffer of n bytes and return the descriptor
\ buffers are permenant strings 
	dup allocate THROW						( n addr)						\ allocate the memory
	swap 0 swap -1 $make					( s$)							\ make a descriptor
;

: $debuffer ( s$ --)
\ deallocate the buffer associated with string s$
\ although buffers are permenant strings, also deallocate the descriptor
	$addr free drop							( s$)
	dup $.size 0 swap !						( s$) 							\ force to be temporary string
	$drop
;

: $copy ( s$ -- s$ r$)
\ allocate to sufficient memory, then copy the character data
\ referenced by s$ into a fresh buffer and return a new descriptor r$
\ if s$ references a sub-string, only that portion is copied
\ r$ is a permenant string
	>R
	R@ $.addr @ R@ $.start @ +				( c-addr R:s$)
	R@ $.len @								( c-addr u R:s$)				\ locate the character data in s$
	dup $buffer								( c-addr u r$ R:s$)
	-rot $write								( r$ R:s$)
	R> swap									( r$ s$)
;	

: $map ( fileid -- s$)
\ memory map a file to a buffer and return the descriptor
	dup file-size THROW drop 				( fileid size)					\ file-size returns a double			
	dup $buffer >R							( fileid size R:s$)				\ allocate a suitable buffer
	R@ $addr nip swap rot					( addr n fileid R:s$)
	read-file THROW							( len R:s$)
	R@ $.len ! R>							( s$)							\ update len									
;

: $demap ( s$ fileid -- s$)
\ save the contents of the string to fileid
	>R $s R>								( s$ addr n fileid)
	write-file THROW						( s$)
;

: $emitw ( s$ x n -- s$, "emit wide")
\ emit the multi-byte charater represented by the least significant n bytes of x 
\ to the end of buffer s$ in little endian format
\ no write occurs if the buffer does not have n bytes of capacity
	rot >R dup R@ $size swap $start swap $len nip 	( x n n size start len R:s$)
	+ swap										( x n n next size R:s$)
	over - rot <								( x n next flag R:s$)			\ next is character after the current last character
	IF drop drop drop R> exit THEN				( x n next R:s$)				\ insufficient capacity
	swap dup R@ $.len +! swap	 				( x n next R:s$)				\ update len
	R@ $.addr @ + swap							( x addr n R:s$)
	0 DO
		over over swap 255 and swap c! 			( x addr R:s$)
		1+ swap 8 rshift swap					( x' addr' R:s$)
	LOOP
	drop drop R>								( s$)
;

: $emit ( s$ c -- s$)
\ emit the byte-sized character c to the end of buffer s$
\ if the buffer is already full then no write occurs
	1 $emitw
;
