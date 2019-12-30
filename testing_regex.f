include ../simple-tester/simple-tester.fs
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
\ uses local variables
	addrT uT addrR uR match					( start len TRUE | FALSE)
	IF
		CR addrT uT type					( addrF addrN)
		CR swap spaces stars
	ELSE
		CR ." No match"
	THEN
		CR
;

\ : utime ticks 0 ; 						\ VFX Forth
: example s" my test sssstring" s" s*tr" match drop drop drop ;
: speedtest									\ about 5 seconds VFX Forth, 125 seconds gforth
	CR s" speedtest: " type key? drop
	utime drop
	10000000 0 DO example LOOP
	utime drop swap - . ." us" CR
;

CR CR
\ speedtest

Tstart

T{ s" my test string" s" my" match }T 0 2 -1 ==
T{ s" my test string" s" ^my" match }T 0 2 -1 ==
T{ s" my test string" s" !my" match }T 0 2 -1 ==
T{ s"    my test string" s" !my" match }T 3 2 -1 ==
T{ s" my test string" s" test" match }T 3 4 -1 ==
T{ s" my test string" s" ng" match }T 12 2 -1 ==
T{ s" my test string" s" ng$" match }T 12 2 -1 ==
T{ s" my test string" s" t.st" match }T 3 4 -1 ==
T{ s" my test string" s" s*tr" match }T 8 3 -1 ==
T{ s" my test sssstring" s" s*tr" match }T 8 6 -1 ==
T{ s" abccXabcd" s" X*abcd" match }T 4 5 -1 ==
T{ s" abc9d" s" c\dd" match }T 2 3 -1 ==
T{ s" abcd" s" \d" match }T 0 ==
T{ s" abc\d" s" c\\d" match }T 2 3 -1 ==
T{ s" hgfh" s" \h" match }T 2 1 -1 ==
T{ s" pqr12345abc" s" \d*abc" match }T 3 8 -1 ==
T{ s" pqr12345" s" r\d*" match }T 2 6 -1 ==
T{ s" abcd" s" cX*d" match }T 2 2 -1 ==
T{ s" abcXd" s" cX*d" match }T 2 3 -1 ==
T{ s" abcXXd" s" cX*d" match }T 2 4 -1 ==
T{ s" abcd" s" cX+d" match }T 0 ==
T{ s" abcXd" s" cX+d" match }T 2 3 -1 ==
T{ s" abcXXd" s" cX+d" match }T 2 4 -1 ==
T{ s" abcd" s" cX?d" match }T 2 2 -1 ==
T{ s" abcXd" s" cX?d" match }T 2 3 -1 ==
T{ s" abcXXd" s" cX?d" match }T 0 ==
T{ s" abc*def" s" \*" match }T 3 1 -1 ==
T{ s" abc+def" s" \+" match }T 3 1 -1 ==
T{ s" abc?def" s" \?" match }T 3 1 -1 ==
T{ s" abc\def" s" \\" match }T 3 1 -1 ==
T{ s" my spaceship" s" \sspace" match  }T 2 6 -1 ==
T{ s"       Hello it's me" s" \S+" match }T 6 5 -1 ==
T{ s"       76233" s" !\d+" match }T 6 5 -1 ==
T{ s" ABC 'a' XYZ" s" '\S'" match }T 4 3 -1 ==
T{ s" aaaaaaxaaa" s" ~a" match }T 6 1 -1 ==
T{ s" aaaaaaaaaa" s" ~a" match }T 0 ==
T{ s" my test string" s" my" parse-match }T 0 2 -1 ==
T{ s"    my test string" s" my" parse-match }T 3 2 -1 ==
T{ s" my" s" my" parse-match }T -1 0 2 -1  ==
T{ s" mytest string" s" my" parse-match }T 0 ==
T{ s" xmy test string" s" my" parse-match }T 0 ==
Tend
CR

bye
