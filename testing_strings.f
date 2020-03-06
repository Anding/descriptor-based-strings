include ../simple-tester/simple-tester.fs
include strings.f

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

255 $initialize

s" Paulum Caesar consituit...              " 26 swap true 
$make CONSTANT s$

s" armis agenda erunt" dup true 
$make CONSTANT t$

s" armis erunt" dup true
$make CONSTANT u$

s" Pa1234ulum Caesar consituit..." dup true
$make CONSTANT v$

s" 1234" dup true
$make CONSTANT w$

s" 12" dup true
$make CONSTANT x$

CR
Tstart

\ structure lookup
T{ s" ABC" over >R dup false $make $addr swap $drop }T R> ==
T{ s$ $len nip }T 26 ==
T{ s$ $size nip }T 40 ==
T{ s" ABC" dup -1 $make $perm $nip }T true ==
T{ s" ABC" dup 0 $make $perm $nip }T false ==

\ $=
T{ s$ s" 1234" $q $T= }T false ==
T{ s$ s" Paulum Caesar consituit..." $q $T= }T true ==

\ $write
T{ s" ABC  " 3 swap false $make s" DE" $write s" ABCDE" $q $T= }T true ==
T{ s" ABCD  " 4 swap false $make s" EF" $write s" ABCDEF" $q $T= }T true ==
T{ s" ABCD  " $q 0 3 $sub s" XYZ" $write s" ABCXYZ" $q $T= }T true ==

\ $rem
T{ s$ $len swap 0 0 $rem $len nip = }T true ==
T{ t$ 5 7 $rem u$ $T= }T true ==
T{ u$ 0 100 $rem $len nip }T 0 ==
T{ s" ABCDEF" $q 2 1 $rem s" ABDEF" $q $T= }T true ==

\ $ins
T{ s$ 2 s" 1234" $ins v$ $= nip nip }T true ==

\ $sub
T{ v$ 2 4 $sub w$ $T= }T true ==
T{ w$ 0 2 $sub x$ $T= }T true ==

\ $dup
T{ w$ $dup nip x$ $T= }T true ==
T{ w$ $dup $drop drop }T ==	

\ $prune
T{ s" ABCDEF" $q 1 2 $prune s" BCD" $q $T= }T true ==
T{ s" ABCDEF" $q 0 0 $prune s" ABCDEF" $q $T= }T true ==		
T{ s" ABCDEF" $q 6 0 $prune s" " $q $T= }T true ==	
T{ s" ABCDEF" $q 0 6 $prune s" " $q $T= }T true ==	
T{ s" ABCDEF" $q 3 3 $prune s" " $q $T= }T true ==	
T{ s" ABCDEF" $q 4 4 $prune s" " $q $T= }T true ==	
T{ s" ABCDEFGHIJ" $q 3 4 $sub ( DEFG) -1 -2 $prune s" CDEFGHI" $q $T= }T true ==

cr
Tend
cr

bye