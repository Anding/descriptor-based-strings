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
	R>										( r$ s$)
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

