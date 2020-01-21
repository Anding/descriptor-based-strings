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

T{ 100 $buffer $size swap $debuffer }T 100 ==
T{ 100 $buffer $len swap $debuffer }T 0 ==
T{ s" ABCD" $q $copy $T= }T true ==
T{ s" ABCD" $q test-file $demap $drop }T ==
0 0 test-file reposition-file
T{ test-file $map s" ABCD" $q $T= }T true ==

cr Tend
cr bye