include ../simple-tester/simple-tester.fs
include strings.f
include regex.f
include strings+regex.f

255 $initialize

: $dump ( s$ -- s$, dump the memory contents of s$)
	cr $s type
	dup $.string dump
;

: $q ( c-addr n -- s$, make a quick temporary string)
	dup false $make
;

cr
Tstart

\ $match with simple word matches
T{ s" ABC DEF" $q s" ABC" $q $match >R $drop $drop $drop R> }T true ==
T{ s" ABC DEF" $q s" DEF" $q $match >R $drop $drop $drop R> }T true ==
T{ s" ABC DEF" $q s" ABC" $q $match drop $drop swap $drop s" ABC" $q $= nip nip }T true ==
T{ s" ABC DEF" $q s" ABC" $q $match drop -rot $drop $drop s"  DEF" $q $= nip nip }T true ==

\ $parse matches only at the start of a string
T{ s" ABC DEF" $q s" ABC" $q $parse >R $drop $drop R> }T true ==
T{ s" ABC DEF" $q s" ABC" $q $parse drop $drop s" ABC" $q $= nip nip }T true ==
T{ s" ABC DEF" $q s" ABC" $q $parse drop swap $drop s"  DEF" $q $= nip nip }T true ==
T{ s"      ABC DEF" $q s" ABC" $q $parse >R $drop $drop R> }T true ==
T{ s" ABC" $q s" ABC" $q $parse >R $drop $drop R> }T true ==
T{ s" ABCDEF" $q s" ABC" $q $parse >R $drop R> }T false ==
T{ s" ABC DEF" $q s" DEF" $q $parse >R $drop R> }T false ==

\ character literals
T{ s" 'a' " $q s" '~''" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 'a' " $q s" '~''" $q $parse >R $drop $drop R> }T true ==
T{ s" 'a' " $q s" '~''" $q $parse drop $drop s" 'a'" $q $= nip nip }T true ==

\ quoted strings
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $match >R $drop $drop $drop R> }T true ==
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $parse >R $drop $drop R> }T true ==
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $parse drop $drop s\" \"Happy New Year\"" $q $= nip nip }T true ==

\ s-quote strings
T{ s\" s\"Happy New Year\" " $q s\" s\"~\"+\"" $q $match >R $drop $drop $drop R> }T true ==
T{ s\" s\"Happy New Year\" " $q s\" s\"~\"+\"" $q $parse >R $drop $drop R> }T true ==
T{ s\" s\"Happy New Year\""  $q s\" s\"~\"+\"" $q $parse drop $drop s\" s\"Happy New Year\"" $q $= nip nip }T true ==

\ decimal numbers
T{ s" 12345 " $q s" \d+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 12345 " $q s" \d+" $q $parse >R $drop $drop R> }T true ==
T{ s" 12345 " $q s" \d+" $q $parse drop $drop s" 12345" $q $= nip nip }T true ==

\ hexadecimal numbers
T{ s" 0x123FE " $q s" 0x\h+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" $123FE " $q s" $\h+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 0x123FE " $q s" 0x\h+" $q $parse >R $drop $drop R> }T true ==
T{ s" 0x123FG " $q s" 0x\h+" $q $parse >R $drop R> }T false ==
T{ s" 0x123FE " $q s" 0x\h+" $q $parse drop $drop s" 0x123FE" $q $= nip nip }T true ==

\ binary numbers
T{ s" %1001 " $q s" %\b+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" %1001 " $q s" %\b+" $q $parse >R $drop $drop R> }T true ==
T{ s" %100I " $q s" %\b+" $q $parse >R $drop R> }T false ==
T{ s" %1001 " $q s" %\b+" $q $parse drop $drop s" %1001" $q $= nip nip }T true ==

\ colon definitions - assume that colon definitons take the format : ... ;
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $match >R $drop $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $parse >R $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $parse drop $drop s" : squ dup * ;" $q $= nip nip }T true ==	

\ macro definitions  - assume that macros take the format : ... ;;
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $match >R $drop $drop $drop R> }T true ==
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $parse >R $drop $drop R> }T true ==
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $parse drop $drop s" : squ dup * ;;" $q $= nip nip }T true ==	
	
cr cr

s"       Hello" $q s" ^\s*" $q $match 
drop 
cr $s rot drop type
cr $s rot drop type
cr $s rot drop type	
cr
Tend
cr 
bye