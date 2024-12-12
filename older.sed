:accumulate-program
	1{x;n;} ;# TODO: is `n` needed
	/^__END__$/{
		s///;x
		# `Q 0` to always quit, the other `0`s are to add stuff to teh end. The `;` is to run to it.
		s/^;//
		s/$/Q/;bparse
	}
	H;n;baccumulate-program

:parse
	# Delete leading whitespace characters
	s/^[[:space:]:()]+//

	# Parse comments. We need this b/c no way to use `\n` in char classes.
	:parse.comments
		s/^#\n//;tparse
		s/^#./#/;tparse.comments

	# If we're done parsing, run the program
	/^$/{
		# s/$/:/
		x;brun-start
	}

	# Parse out individual strings
	s/^[0-9]+/  i&\x1F/;tparse.append
	s/^[a-z_0-9]+/  v&\x1F/;tparse.append
	s/^'([^']*)'/  s\1\x1F/;tparse.append-single-quote-str
	s/^"([^"]*)"/  s\1\x1F/;tparse.append-double-quote-str
	s/^([A-Z])[A-Z_]*/  f\1\x1F/;tparse.append
	s/^(.)/  f&\x1F/;tparse.append

	:parse.append-single-quote-str
	:parse.append-double-quote-str
		# TODO: replace newlines in string with an escape
	:parse.append
		H
		x;s/^\n//;s/\x1F.*//;y/\n/|/
		x;s/.*\x1F//
		bparse

:bug
:dbg
	i\
===[debug]=== pattern space:
	l;x
	i\
===[debug]=== hold space:
	l;q;bdbg

:run-start
	/^  [^f]/q ; # If the first thing parsed isn't a function, just stop
	s/ /C/2; # Add "current function" marker
	s/ /N/3; # Add "next function" marker
	s/^/\|/

	# Fallthrough
:run
	s/^$//;trun.0
	:run.0
	#l

	# Execute strings and integers by just pushing them on the stack/
	/ C([is][^|]*\|)/{
		# Push onto the stack
		# TODO: should this go on the back, or front like we have? if so, modify const fns
		H;x;s/(.*)\n(.* C)([is][^|]*).*/\3|\1/;x
		# Move back to the previous reference
		brun.go-to-previous-function
	}

	# If the current value doesn't start with a space, then it must be a function.
	/[^ ]C[^f]/{
		i\
		BUG: CURRENT value is a non-function with args
		bdbg
	}

	# If the current function doesn't have its arity set, the set the arity.
	/ (Cf.)/{
		 # TODO: handle `|` function when we are done
		s/ (Cf[TFNPR@])/0\1/;trun.function.zero-arity
		s/ (Cf[][BCQDOL!~A,])/1\1/;trun.function.nonzero-arity
		s_ (Cf[-+*/%<>?&;=W])_2\1_;trun.function.nonzero-arity
		s/ (Cf[IG])/3\1/;trun.function.nonzero-arity
		s_ (CfS)_4\1_;trun.function.nonzero-arity
		i\
		BUG: unknown function encountered
		bbug
	}

	:run.function.nonzero-arity

	# Functions which dont always execute their args
	/1Cf[W&|B]|2CfI/{
		i\
			TODO: deferred evaluation function
		q
	}

	# Functions which always execute their args, just execute
	/[^0]C/{
		s/([^0])C(f.[^N]*)N([^|]*\| ) /\1_\2C\3N/
		brun
	}

	i\
		BUG: shoudlnt get here
	bdbg

	:run.go-to-previous-function
		s/C/ /; # Delete the current

		# Reset branch condition
		s/^$//;#l
			;trun.go-to-previous-function.0
		:run.go-to-previous-function.0

		# Replace the previousmost with the current
		s/(.*[0-9])_/\1C/;trun.reduce-arity

		# End of program encountered, as there's
		i\
			<end of program>
		bdbg

		:run.reduce-arity
		s/1C/0C/;trun.function.zero-arity
		s/2C/1C/;trun
		s/3C/2C/;trun
		s/4C/3C/;trun

		i\
			BUG: arity isnt the right size
		bbug

	:run.function.zero-arity
	/[^0a-z]C/{
		i\
			BUG: went to run.function.zero-arity with a nonzero-arity function.
		bbug
	}

	# Keyword literals
	/0CfT/{ x;s/^/T|/;x;brun.go-to-previous-function
	}
	/0CfF/{ x;s/^/F|/;x;brun.go-to-previous-function
	}
	/0CfN/{ x;s/^/N|/;x;brun.go-to-previous-function
	}

	/0CfQ/{
		i\
			<quit>
		q
	}

	/0CfO/{
		s//aCfO/;x;bto_string
	}
	/aCfO/{
		bdbg
		# TODO: insert null
		#:run.function.O.end
		bdbg
	}

	/0(Cf.)/{
		s// \1/
		i\
		RAN FN
		brun.go-to-previous-function
	}

	i\
		BUG: got a zero arity function but it's not known
	bbug



:runold
	brunold
	brun
	s/^$//;trunold.1
	:runold.1

	/\x01$/bdbg

	/\x01i/{
		H
		x;s/\x03.*\x01(i[0-9]+\n).*/\1\x03/; # addit to the stack
		x;s/\x01(i[0-9]+\n)/\1\x01/; # Move to next value
		brunold
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

#	:runold.output
#		l;q


:to_string
	s/\|/\n/

	/^a/bdbg
	s/^T/true/
	s/^F/false/
	s/^N/null/
	s/^N/null/
	s/^[in]//
	x
	brun.function.zero-arity
	#s/.*\|//
	bdbg
# 		# TODO: to-string
# 		x;H
# 		/^T/i\
# true
# 		/^F/i\
# false
# 		/^N/{
# 			s/.*//p
# 		}
# 		/^i/{
# 			# Abuse the fact that we can use `P` to print out ints
# 			s///;s/\|/\n/1;P
# 			brun.function.O.end
# 		}
# 		/^s/{
# 			# TODO: handle `\n`s
# 			s///
# 			s/\|.*//
#
# 			s/^$//;trun.function.O.0
# 			:run.function.O.0
#
# 			/\\$/!P
# 			/\\$/{
# 				s//<NO NEWLINE>/; # todo, why you no work :-(
# 				p
# 			}
# 			brun.function.O.end
# 		}
