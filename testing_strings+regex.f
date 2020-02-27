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

: $T= ( s$ t$ -- flag, test strings for equality and attempt to recycle them)
	$= -rot $drop $drop
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
T{ s" ABCDEF" $q s" DEF" $q $parse >R $drop R> }T false ==
T{ s" ABC DEF" $q s" DEF" $q $parse >R $drop R> }T false ==

\ character literals
T{ s" 'a' " $q s" '~''" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 'a' " $q s" '~''" $q $parse >R $drop $drop R> }T true ==
T{ s" 'a' " $q s" '~''" $q $parse drop $drop s" 'a'" $q $T= }T true ==

\ quoted strings
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $match >R $drop $drop $drop R> }T true ==
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $parse >R $drop $drop R> }T true ==
T{ s\" \"Happy New Year\"" $q s\" \"~\"+\"" $q $parse drop $drop s\" \"Happy New Year\"" $q $T= }T true ==

\ s-quote strings
T{ s\" s\"Happy New Year\" " $q s\" s\"~\"+\"" $q $match >R $drop $drop $drop R> }T true ==
T{ s\" s\"Happy New Year\" " $q s\" s\"~\"+\"" $q $parse >R $drop $drop R> }T true ==
T{ s\" s\"Happy New Year\""  $q s\" s\"~\"+\"" $q $parse drop $drop s\" s\"Happy New Year\"" $q $T= }T true ==

\ decimal numbers
T{ s" 12345 " $q s" \d+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 12345 " $q s" \d+" $q $parse >R $drop $drop R> }T true ==
T{ s" 12345 " $q s" \d+" $q $parse drop $drop s" 12345" $q $T= }T true ==

\ hexadecimal numbers
T{ s" 0x123FE " $q s" 0x\h+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" $123FE " $q s" $\h+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" 0x123FE " $q s" 0x\h+" $q $parse >R $drop $drop R> }T true ==
T{ s" 0x123FG " $q s" 0x\h+" $q $parse >R $drop R> }T false ==
T{ s" $123FG " $q s" $\h+" $q $parse >R $drop R> }T false ==
T{ s" 0x123FE " $q s" 0x\h+" $q $parse drop $drop s" 0x123FE" $q $T= }T true ==

\ binary numbers
T{ s" %1001 " $q s" %\b+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" %1001 " $q s" %\b+" $q $parse >R $drop $drop R> }T true ==
T{ s" %100I " $q s" %\b+" $q $parse >R $drop R> }T false ==
T{ s" %1001 " $q s" %\b+" $q $parse drop $drop s" %1001" $q $T= }T true ==

\ colon definitions - option 1 - match the whole definition at once ": NAME ... ;"
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $match >R $drop $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $parse >R $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :~;+;" $q $parse drop $drop s" : squ dup * ;" $q $T= }T true ==	

\ colon defintions - option 2 - just match ": NAME"
T{ s" : squ dup * ; etc." $q s" :\s+\S+" $q $match >R $drop $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :\s+\S+" $q $parse >R $drop $drop R> }T true ==
T{ s" : squ dup * ; etc." $q s" :\s+\S+" $q $parse drop $drop s" : squ" $q $T= }T true ==	
	
\ macro definitions  - assume that macros take the format : ... ;;
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $match >R $drop $drop $drop R> }T true ==
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $parse >R $drop $drop R> }T true ==
T{ s" : squ dup * ;; etc." $q s" :~;+;;" $q $parse drop $drop s" : squ dup * ;;" $q $T= }T true ==	
	
\ comments
T{ s\" \\ a comment   \nA" $q s" \\~\n*" $q $parse >R $drop $drop R> }T true ==
T{ s\"    \\ a comment   \nA" $q s" \\~\n*" $q $parse >R $drop $drop R> }T true ==
T{ s\" \\ a comment   " $q s" \\~\n*" $q $parse >R $drop $drop R> }T true ==
T{ s\"    \\ a comment   " $q s" \\~\n*" $q $parse >R $drop $drop R> }T true ==

\ $trim
T{ s" abc" $q $trim s" abc" $q $T= }T true ==
T{ s"  abc" $q $trim s" abc" $q $T= }T true ==
T{ s\"  \n\tabc" $q $trim s" abc" $q $T= }T true ==

\ $word
T{ s" abc" $q $word s" abc" $q $T= >R s" " $q $T= R> }T true true ==
T{ s" abc def" $q $word s" abc" $q $T= >R s"  def" $q $T= R> }T true true ==
T{ s"  abc def" $q $word s" abc" $q $T= >R s"  def" $q $T= R> }T true true ==
T{ s" " $q $word s" " $q $T= >R s" " $q $T= R> }T true true ==
T{ s\" \n" $q $word s" " $q $T= >R s" " $q $T= R> }T true true ==

cr
Tend
cr 
bye