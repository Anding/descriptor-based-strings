include ../simple-tester/simple-tester.fs
include strings.f

10 $initialize

s" Paulum Caesar consituit...              " 26 swap false 
$make CONSTANT s$

s" armis agenda erunt" dup false 
$make CONSTANT t$

s" armis erunt" dup false
$make CONSTANT u$

s" Pa1234ulum Caesar consituit..." dup false
$make CONSTANT v$

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
				
Tend
CR