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

cr Tstart

255 $initialize

T{ 100 $buffer $size swap $debuffer }T 100 ==
T{ 100 $buffer $len swap $debuffer }T 0 ==
T{ s" ABCD" $q $copy $T= }T true ==

cr Tend
cr bye