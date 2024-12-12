s/[0-9]/x&/g
s/0//g; s/1/I/g; s/2/II/g; s/3/III/g; s/4/IIII/g; s/5/IIIII/g; s/6/IIIIII/g
s/7/IIIIIII/g; s/8/IIIIIIII/g; s/9/IIIIIIIII/g
: tens
s/Ix/xIIIIIIIIII/g
t tens
s/x//g
s/\+//g
: minus
s/I-I/-/g
t minus
s/-$//
: back
s/IIIIIIIIII/x/g
s/x([0-9]*)$/x0\1/p
l
=
s/IIIIIIIII/9/; s/IIIIIIII/8/; s/IIIIIII/7/; s/IIIIII/6/; s/IIIII/5/; s/IIII/4/
s/III/3/; s/II/2/; s/I/1/
s/x/I/g
t back
