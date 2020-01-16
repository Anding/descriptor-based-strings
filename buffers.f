\ extend the strings library to provide memory buffer library
\ requires strings.f

: $buffer ( n -- s$)
\ allocate a buffer of n bytes and return the descriptor as a handle
\ buffers are permenant strings 
	dup allocate THROW						( n addr)
	swap 0 swap -1 $make					( s$)
;

: $debuffer ( s$ --)
\ deallocate the buffer associated with string s$
\ although buffers are permenant strings, deallocate the descriptor
	$addr free drop							( s$)
	dup $.size 0 swap !						( s$) 							\ force a temporary string
	$drop
;

: $copy ( s$ -- s$ r$)
\ Call allocate to obtain sufficient memory, then copy the character data
\ referenced by s$ into a fresh buffer and return a new descriptor r$
\ if s$ references a sub-string, only that portion is copied
\ r$ is a permenant string
	>R
	R@ $.addr @ R@ $.start @ +		( c-addr R:s$)
	R@ $.len @						( c-addr u R:s$)						\ locate the character data in s$
	dup $buffer						( c-addr u r$ R:s$)
	-rot $write						( r$ R:s$)
	R>								( r$ s$)
;	

: $map ( fileid -- s$)
\ memory map a file to a buffer and return the descriptor
	( obtain the file size	) 				( fileid size)				
	dup $buffer >R							( fileid size R:s$)
	R@ $addr @ nip swap rot					( addr n fileid R:s$)
	( read 0= THROW	)						( R: s$)
	R>										( s$)
;

: $demap ( s$ fileid -- s$)
\ save the contents of the string to fileid
	>R swap $s R>								( s$ addr n fileid)
	( write 0= THROW )
;

