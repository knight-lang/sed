
# ;=a 0 W + 1 a ; = a ~ 1 O a

| xW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
| xW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|2_W| x+|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|2_W|2_+| xi1|  va  |  ;|  =|  va|  ~|  i1|  O|  va : i1
|2_W|1x+|  i1| yva  |  ;|  =|  va|  ~|  i1|  O|  va : i1
|2_W|1_+|  i1| xva  |  ;|  =|  va|  ~|  i1|  O|  va : i1 a
|2_W|0x+|  i1|  va  | y;|  =|  va|  ~|  i1|  O|  va : i1 + a
|1xW|  +|  i1|  va  | y;|  =|  va|  ~|  i1|  O|  va :
|1_W|  +|  i1|  va  | x;|  =|  va|  ~|  i1|  O|  va :
|1_W|  +|  i1|  va  |2_;| x=|  va|  ~|  i1|  O|  va :
|1_W|  +|  i1|  va  |2_;|1_=|  va| x~|  i1|  O|  va :
|1_W|  +|  i1|  va  |2_;|1_=|  va|1_~| xi1|  O|  va : i1
|1_W|  +|  i1|  va  |2_;|1_=|  va|0x~|  i1| yO|  va : i-1
|1_W|  +|  i1|  va  |2_;|0x=|  va|  ~|  i1| yO|  va : i-1
|1_W|  +|  i1|  va  |1x;|  =|  va|  ~|  i1| yO|  va :
|1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1| xO|  va :
|1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|1_O| xvi : i
|1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|0xO|  va : N
|0xW|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|  O|  va : N


# 1 ; I + 1 2 O 3 O 4 O 5
 x;|  I|  +|  i1|  i2|  O|  i3|  O|  i4|  O|  i5 : ...
2_;| xI|  +|  i1|  i2|  O|  i3|  O|  i4|  O|  i5 : ...
2_;|3_I| x+|  i1|  i2|  O|  i3|  O|  i4|  O|  i5 : ...
2_;|3_I|2_+| xi1|  i2|  O|  i3|  O|  i4|  O|  i5 : ... i1
2_;|3_I|1x+|  i1| yi2|  O|  i3|  O|  i4|  O|  i5 : ... i1
2_;|3_I|1_+|  i1| xi2|  O|  i3|  O|  i4|  O|  i5 : ... i1 i2
2_;|3_I|0x+|  i1|  i2| yO|  i3|  O|  i4|  O|  i5 : ... i3
2_;|2xI|  +|  i1|  i2| yO|  i3|  O|  i4|  O|  i5 : ... _NOFALSE
2_;|2_I|  +|  i1|  i2| xO|  i3|  O|  i4|  O|  i5 : ... _NOFALSE
2_;|2_I|  +|  i1|  i2|1_O| xi3|  O|  i4|  O|  i5 : ... _NOFALSE i3
2_;|2_I|  +|  i1|  i2|0xO|  i3| yO|  i4|  O|  i5 : ... _NOFALSE N
2_;|1xI|  +|  i1|  i2|  O|  i3| yO|  i4|  O|  i5 : ... _NOFALSE N
2_;|1_I|  +|  i1|  i2|  O|  i3| xO|  i4|  O|  i5 # ... N
2_;|1_I|  +|  i1|  i2|  O|  i3|1_O| xi4|  O|  i5 # ... N
2_;|1_I|  +|  i1|  i2|  O|  i3|0xO|  i4| yO|  i5 # ... N
2_;|0xI|  +|  i1|  i2|  O|  i3|  O|  i4| yO|  i5 # ... N <-- that `#` needs to be nestable
1x;|  I|  +|  i1|  i2|  O|  i3|  O|  i4| yO|  i5 : ... N
1_;|  I|  +|  i1|  i2|  O|  i3|  O|  i4| xO|  i5 : ...
1_;|  I|  +|  i1|  i2|  O|  i3|  O|  i4|1_O| xi5 : ... i5
1_;|  I|  +|  i1|  i2|  O|  i3|  O|  i4|0xO|  i5 : ... N
1_;|  I|  +|  i1|  i2|  O|  i3|  O|  i4|  O|  i5 : ... N
0x;|  I|  +|  i1|  i2|  O|  i3|  O|  i4|  O|  i5 : ... N


2.;|3.I|2.+|0.i1|0.i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :
2x;|3=I|2.+|0.i1|0.i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :    # start
2_;|3xI|2=+|0.i1|0.i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :    # nonzero, advance to `=`, and set `=` to next
2_;|3_I|2x+|0=i1|0.i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :    # nonzero, advance to `=`, and set `=` to next
2_;|3_I|2_+|0xi1|0=i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :    # zero, handle. For integers:
2_;|3_I|2_+|0xi1|0.i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 : i1 # 1. push i1 onto stack
2_;|3_I|2_+|0xi1|0=i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 : i1 # 2. put `y` as next value
2_;|3_I|1x+|0_i1|0=i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 : i1 # 3. go back to the previous `_`, and decrement it.
2_;|3_I|1x+|0_i1|0=i2|1.O|0.i3|1.O|0.i4|1.O|0.i5 :    # nonzero, advance to `=`, and set `=` to next

|2x;| n=|  va|  i0  |  W|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|2_;| x=| nva|  i0  |  W|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|2_;|1_=|  va| xi0  | nW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|2_;|0x=|  va|  i0  | nW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va : i0
|1x;|  =|  va|  i0  | nW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va : i0
|1_;|  =|  va|  i0  | xW|  +|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va : <-- todo: ns
|1_;|  =|  va|  i0  |2_W| x+|  i1|  va  |  ;|  =|  va|  ~|  i1|  O|  va :
|1_;|  =|  va|  i0  |2_W|2_+| xi1|  va  |  ;|  =|  va|  ~|  i1|  O|  va : i1
|1_;|  =|  va|  i0  |2_W|1x+|  i1| yva  |  ;|  =|  va|  ~|  i1|  O|  va : i1
|1_;|  =|  va|  i0  |2_W|1_+|  i1| xva  |  ;|  =|  va|  ~|  i1|  O|  va : i1 a
|1_;|  =|  va|  i0  |2_W|0x+|  i1|  va  | y;|  =|  va|  ~|  i1|  O|  va : i1 + a
|1_;|  =|  va|  i0  |1xW|  +|  i1|  va  | y;|  =|  va|  ~|  i1|  O|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  | x;|  =|  va|  ~|  i1|  O|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |2_;| x=|  va|  ~|  i1|  O|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |2_;|1_=|  va| x~|  i1|  O|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |2_;|1_=|  va|1_~| xi1|  O|  va : i1
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |2_;|1_=|  va|0x~|  i1| yO|  va : i-1
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |2_;|0x=|  va|  ~|  i1| yO|  va : i-1
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |1x;|  =|  va|  ~|  i1| yO|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1| xO|  va :
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|1_O| xvi : i
|1_;|  =|  va|  i0  |1_W|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|0xO|  va : N
|1_;|  =|  va|  i0  |0xW|  +|  i1|  va  |1_;|  =|  va|  ~|  i1|  O|  va : N



; I 1 (I 2 O "w" O "x") (O "y") O "z"
