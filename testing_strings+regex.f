include ../simple-tester/simple-tester.fs
include strings.f
include regex.f
include strings+regex.f

10 $initialize

: $type $s type ;

s"  my test string" dup true 
$make $dup CONSTANT s$ CONSTANT z$

s" m." dup true 
$make CONSTANT r$

s" my" dup true 
$make CONSTANT b1$

s"  test string" dup true 
$make CONSTANT s1$

s"  " dup true
$make CONSTANT a1$

CR
Tstart

T{ s$ r$ $regex ( a$ b$ s$ TRUE) drop rot a1$ $= nip nip rot b1$ $= nip nip rot s1$ $= nip nip }T -1 -1 -1 == 
T{ z$ r$ $parse ( b$ s$ TRUE) rot s1$ $= nip nip rot b1$ $= nip nip }T -1 -1 -1 == 

Tend
CR

