include ttester.f
include regex.f

: stars ( n --)
\ emit n stars
	0 ?do 42 emit loop
;

: spaces ( n --)
\ emit n spaces
	0 ?do 32 emit loop
;

: look { addrT uT addrR uR -- }
\ show the regex match within the text
\ uses local variables, VFX style
	addrT uT addrR uR match					( start len TRUE | FALSE)
	IF
		CR addrT uT type					( addrF addrN)
		CR swap spaces stars
	ELSE
		CR ." No match"
	THEN
		CR
;

: example s" my test sssstring" s" s*tr" match drop drop drop ;
: speedtest
	CR s" speedtest: " type key? drop
	utime drop 									\ VFX ticks in ms
	10000000 0 DO example LOOP
	utime drop swap - . ." us" CR
;

CR CR
\ speedtest

T{ s" my test string" s" my" match EXPECT 0 2 -1 }T
T{ s" my test string" s" ^my" match EXPECT 0 2 -1 }T
T{ s" my test string" s" test" match EXPECT 3 4 -1 }T
T{ s" my test string" s" ng" match EXPECT 12 2 -1 }T
T{ s" my test string" s" ng$" match EXPECT 12 2 -1 }T
T{ s" my test string" s" t.st" match EXPECT 3 4 -1 }T
T{ s" my test string" s" s*tr" match EXPECT 8 3 -1 }T
T{ s" my test sssstring" s" s*tr" match EXPECT 8 6 -1 }T
T{ s" abccXabcd" s" X*abcd" match EXPECT 4 5 -1 }T
T{ s" abc9d" s" c\dd" match EXPECT 2 3 -1 }T
T{ s" abcd" s" \d" match EXPECT 0 }T
T{ s" abc\d" s" c\\d" match EXPECT 2 3 -1 }T
T{ s" hgfh" s" \h" match EXPECT 2 1 -1 }T
T{ s" pqr12345abc" s" \d*abc" match EXPECT 3 8 -1 }T
T{ s" pqr12345" s" r\d*" match EXPECT 2 6 -1 }T
T{ s" abcd" s" cX*d" match EXPECT 2 2 -1 }T
T{ s" abcXd" s" cX*d" match EXPECT 2 3 -1 }T
T{ s" abcXXd" s" cX*d" match EXPECT 2 4 -1 }T
T{ s" abcd" s" cX+d" match EXPECT 0 }T
T{ s" abcXd" s" cX+d" match EXPECT 2 3 -1 }T
T{ s" abcXXd" s" cX+d" match EXPECT 2 4 -1 }T
T{ s" abcd" s" cX?d" match EXPECT 2 2 -1 }T
T{ s" abcXd" s" cX?d" match EXPECT 2 3 -1 }T
T{ s" abcXXd" s" cX?d" match EXPECT 0 }T
T{ s" abc*def" s" \*" match EXPECT 3 1 -1 }T
T{ s" abc+def" s" \+" match EXPECT 3 1 -1 }T
T{ s" abc?def" s" \?" match EXPECT 3 1 -1 }T
T{ s" abc\def" s" \\" match EXPECT 3 1 -1 }T
T{ s" my spaceship" s" \sspace" match  EXPECT 2 6 -1 }T
T{ s"       Hello it's me" s" \S+" match EXPECT 6 5 -1 }T
T{ s"       76233" s" !\d+" match EXPECT 6 5 -1 }T
T{ s" aaaaaaxaaa" s" ~a" match EXPECT 6 1 -1 }T
T{ s" aaaaaaaaaa" s" ~a" match EXPECT 0 }T

CR ." Regression testing complete"
