include ../simple-tester/simple-tester.fs
include strings.f

20 $initialize

s" Paulum Caesar consituit...              " 26 swap false 
$make CONSTANT s$

s" armis agenda erunt" dup false 
$make CONSTANT t$

s" armis erunt" dup false
$make CONSTANT u$

s" Pa1234ulum Caesar consituit..." dup false
$make CONSTANT v$

s" 1234" dup false
$make CONSTANT w$

s" 12" dup false
$make CONSTANT x$

CR
Tstart

T{ s$ $len nip }T 26 ==
T{ s$ $size nip }T 40 }T
T{ s$ t$ $= nip nip }T false ==
T{ s$ s$ $= nip nip }T true ==
T{ s$ $len swap 0 0 $rem $len nip = }T true ==
T{ t$ 5 7 $rem u$ $= nip nip }T true ==
T{ u$ 0 100 $rem $len nip }T 0 ==
T{ s" 1234" s$ 2 $ins v$ $= nip nip }T true ==
T{ v$ 2 4 $sub w$ $= nip nip }T true ==
T{ w$ 0 2 $sub x$ $= nip nip }T true ==
T{ w$ $dup nip x$ $= nip nip }T true ==
T{ w$ $dup $drop drop }T ==			
	
Tend
CR

bye