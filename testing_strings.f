include ttester.f
include stacks.f
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

T{ s$ $len nip EXPECT 26 }T
T{ s$ $size nip EXPECT 40 }T
T{ s$ t$ $= nip nip EXPECT false }T
T{ s$ s$ $= nip nip EXPECT true }T
T{ s$ $len swap 0 0 $rem $len nip = EXPECT true }T
T{ t$ 5 7 $rem u$ $= nip nip EXPECT true }T
T{ u$ 0 100 $rem $len nip EXPECT 0 }T
T{ s" 1234" s$ 2 $ins v$ $= nip nip EXPECT true }T
				
CR ." Regression testing complete - check results!"