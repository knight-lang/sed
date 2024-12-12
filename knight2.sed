:top
	1{x;n;}
	/^__END__$/!{H;n;btop
	}
	s/.*//
	x
	bparse

:parse
	# Delete leading whitespace and comments
	s/^[[:space:]]*//
	:parse.comments
		s/$.//;tparse.1
		:parse.1
		s/^#(\n|$)//;tparse
		s/^#./#/;tparse.comments

	# Go to `parse.end` if we're at the end.
	/^$/bparse.end

	# Now leading whitespace and comments are gone
	s/^[0-9]+/i&\x06/;tparse.append
	s/^[a-z_0-9]+/v&\x03i123\x06/;tparse.append
	s/^'([^']*)'/s&\x06/;tparse.append-single-quote-str
	s/^"([^"]*)"/s&\x06/;tparse.append-double-quote-str

	s/^([A-Z])[A-Z_]*/\1\x06/;tparse.append
	s/^(.)/&\x06/;tparse.append

	:parse.append-single-quote-str
	:parse.append-double-quote-str
		# TODO: replace newlines in string with an escape
	:parse.append
		H;x;s/\x06.*//;x;s/.*\x06//;bparse
	:parse.end
		s/$/\x03/;x
		s/$/\n/
		s/^\n/\x01/
		brun

:dbg
	i\
===[debug]=== pattern space:
	l;x
	i\
===[debug]=== hold space:
	l;q;bdbg

:run
	s/^$//;trun.1
	:run.1

	/\x01$/bdbg

	/\x01i/{
		H
		x;s/\x03.*\x01(i[0-9]+\n).*/\1\x03/; # addit to the stack
		x;s/\x01(i[0-9]+\n)/\1\x01/; # Move to next value
		brun
	}
	/\x01v/{
		H
		x;s/\x03.*\x01v[a-z_]+\x03(.*)\n.*/\1\x03/; # addit to the stack
		x;s/\x01(v[a-z_]+\x03.*\n)/\1\x01/; # Move to next value
		l;q
	}

	# s/\x01O\n/|O\n\x01/;trun.output

	=;l;q
	#s/^[is]/
	s/^(.).*/internal error: idk how to handle \1/p;q

#	:run.output
#		l;q
