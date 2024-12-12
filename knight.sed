:accumulate-program
	/^__END__$/!{
		H;n;baccumulate-program
	}

	s///;x
	# `Q 0` to always quit, the other `0`s are to add stuff to teh end. The `;` is to run to it.
	s/^;//
	s/$/Q/
	bparse

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
	brun


:next
	x; # Swap the value stack back
:run.go-to-previous-function
	/[^0a-z]Cf/{
		i\
			BUG: go-to-previous-function when not done with a function
		bbug
	}

	s/[0a-z ]C/  /; # Delete the current and its iteration

	# Reset branch condition
	s/^$//;#l
		;trun.go-to-previous-function.0
	:run.go-to-previous-function.0

	# Replace the previousmost with the current
	s/(.*[0-9])_/\1C/;trun.reduce-arity

	# End of program encountered,
	i\
<END OF PROGRAM>
	q

	:run.reduce-arity
	s/1C/0C/;trun.function.zero-arity
	s/2C/1C/;trun
	s/3C/2C/;trun
	s/4C/3C/;trun

	i\
		BUG: arity isnt the right size
	bbug
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

	:run.function.zero-arity
	/[^0a-z]C/{
		i\
			BUG: went to run.function.zero-arity with a nonzero-arity function.
		bbug
	}

	# Keyword literals
	/0CfT/{ x;s/^/T|/;bnext
	}
	/0CfF/{ x;s/^/F|/;bnext
	}
	/0CfN/{ x;s/^/N|/;bnext
	}


	## ARITY 1

	/0CfQ/{s//aCfQ/;x;bto_integer
	}
	/aCfQ/{x;s/^([0-9]*).*/<exit with status \1>\n/p;q;}

	# `~`: Negate an argument
	/0Cf~/{s//aCf~/;x;bto_integer
	}
	/aCf~/{x
		s/^/i-/
		s/^i--/i/
		s/^i-0\|/i0/
		bnext
	}

	/0Cf!/{s//aCf!/;x;bto_boolean
	}
	/aCf!/{x
		s/^T/_/
		s/^F/T/
		s/^_/F/
		bnext
	}

	/0CfO/{s//aCfO/;x;bto_string
	}
	/aCfO/{x;
		# TODO: `\` at end of line

		# TODO: `\` at the end of the line
		s/\|/\n/1
		P;
		s/.*\n/N|/; # Delete the current line from the stack, replacing with null
		bnext
	}

	## ARITY 2
	/0Cf\+/{x
		/^[^|]*\|s/{x;s/0Cf\+/sCf+/;x;bto_string
		}
		/^[^|]*\|i/{x;s/0Cf\+/iCf+/;x;bto_integer
		}
		i\
		TODO: add others
	}
	/sCf\+/{x
		s/^([^|]*)\|s([^|]*)/s\2\1/
		bnext
	}
	/iCf\+/{
		s//bCf+/;x
		s/^([^|]*)\|i([^|]*)/\2+\1__END_OF_ADDSUB_ARGS__/;x
		# FALLTHRU
	}

	/0Cf-/{s//iCf-/;x;bto_integer
	}
	/iCf-/{s//bCf-/;x;
		s/\|/__TMP__/1
		s/\|/__TMP__/1
		s/(.*)__TMP__(.*)__TMP__/\2-\1__END_OF_ADDSUB_ARGS__/;
		bto_integer
	}
	/bCf[-+]/{x;
		H
		s/\|.*//
		bsubtract
	}


	/0Cf;/{x
		s/\|/__TMP__/1
		s/\|/__TMP__/1
		s/(.*)__TMP__.*__TMP__/\1|/; # delete the second argument
		bnext
	}

	s/.*0Cf(.).*/unknown function: \1/p
	q



:to_string
	/^a/bdbg
	s/^T/true/
	s/^F/false/
	s/^N/null/
	s/^[is]//
	x
	brun.function.zero-arity

:to_boolean
	/^a/bdbg
	s/^([sN]|i0)\|/F|/
	s/^[is][^|]*/T/
	/^[TF]/!{
		i\
			BUG: somehow to_boolean failed
		bdbg
	}
	x
	brun.function.zero-arity

:to_integer
	/^a/bdbg
	s/^T/1/
	s/^[FN]/0/
	s/^i//
	/^s/{
		s/\|/__TMP__/1
		tto_integer.0
		:to_integer.0
		s/^s[[:space:]]*([-+]?[0-9]+).*__TMP__/\1|/;tto_integer.1
		s/^s.*__TMP__/0|/
		:to_integer.1
		s/^[+]//
	}
	x
	brun.function.zero-arity

#:tally-to-digit
#	s/IIIIIIIIII/x/g
#	s/x([0-9]*)$/x0\1/
#	s/IIIIIIIII/9/; s/IIIIIIII/8/; s/IIIIIII/7/; s/IIIIII/6/; s/IIIII/5/; s/IIII/4/
#	s/III/3/; s/II/2/; s/I/1/
#	s/x/I/g
#	tsubtract.back


:subtract
	s/__END_OF_ADDSUB_ARGS__.*//

	s/\+-/-/

	# Fix different signs being used
	s/^(-?[0-9]+)(\+|--)([0-9]+)/\3+\1/
	s/^(-[0-9]+)-([0-9]+)/\1+\2/

	# from https://unix.stackexchange.com/questions/36949/addition-with-sed:
		s/[0-9]/x&/g
		s/0//g; s/1/I/g; s/2/II/g; s/3/III/g; s/4/IIII/g; s/5/IIIII/g; s/6/IIIIII/g
		s/7/IIIIIII/g; s/8/IIIIIIII/g; s/9/IIIIIIIII/g
		:subtract.tens
			s/Ix/xIIIIIIIIII/g
			tsubtract.tens
		s/x//g
		s/\+//g
		:subtract.minus
			s/I-I/-/g
			tsubtract.minus
		s/-$//
		:subtract.back
			s/IIIIIIIIII/x/g
			s/x([0-9]*)$/x0\1/
			s/IIIIIIIII/9/; s/IIIIIIII/8/; s/IIIIIII/7/; s/IIIIII/6/; s/IIIII/5/; s/IIII/4/
			s/III/3/; s/II/2/; s/I/1/
			s/x/I/g
			tsubtract.back
	s/^$/0/
	s/$/__END_OF_ADDSUB__/
	G
	s/(.*)__END_OF_ADDSUB__.*__END_OF_ADDSUB_ARGS__/i\1|/
	x;s/\n.*//;x
	bnext

