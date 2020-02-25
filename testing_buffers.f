include ../simple-tester/simple-tester.fs
include strings.f
include buffers.f

: $dump ( s$ -- s$, dump the memory contents of s$)
	cr $s type
	dup $.string dump
;

: $q ( c-addr n -- s$, make a quick temporary string)
	dup false $make
;

: $T= ( s$ t$ -- flag, test strings for equality and attempt to recycle them)
	$= -rot $drop $drop
;

: open-test-file ( -- wfileid)
	s" testing_buffers_temp.txt" r/w create-file THROW	\ will overwite any preexisting file 
;

cr Tstart

255 $initialize
open-test-file CONSTANT test-file						\ gforth will handle close-file on bye

\ $buffer and $defuffer
T{ 100 $buffer $size swap $debuffer }T 100 ==
T{ 100 $buffer $len swap $debuffer }T 0 ==

\ $copy
T{ s" ABCD" $q $copy $T= }T true ==

\ $map and $demap
T{ s" ABCD" $q test-file $demap $drop }T ==
0 0 test-file reposition-file
T{ test-file $map s" ABCD" $q $T= }T true ==

\ $emitw and emit 
T{ s" ABC  " 3 swap false $make 0x4544 2 $emitw s" ABCDE" $q $T= }T true ==
T{ s" ABC  " 5 swap false $make 0x4544 2 $emitw s" ABC  " $q $T= }T true ==
T{ s" ABC " 3 swap false $make 'D' $emit s" ABCD" $q $T= }T true ==
T{ s" ABC" 3 swap false $make 'D' $emit s" ABC" $q $T= }T true ==

\ $ empty
T{ s" ABC" $q $empty $len nip }T 0 ==
T{ s" ABC" $q $empty $start nip }T 0 ==

cr Tend
cr bye