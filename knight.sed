###
# Separators that're in use:
##

## NOTE: All `ASSERTIONS:` can be completely removed and the program should stay the same.
# That means that things shouldnt rely on the `s//` from them.

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
	s/^/BUG: /;P
	s/\n/__TMP_BUG__/1
	s/.*__TMP_BUG__//
	# FALLTHRU
:dbg
	i\
===[debug]=== pattern space:
	l;x
	i\
===[debug]=== hold space:
	l;q

:run-start
	/^  [^f]/q ; # If the first thing parsed isn't a function, just stop
	s/ /C/2; # Add "current function" marker
	s/ /N/3; # Add "next function" marker
	s/^/\|/
	brun


## After finishing the execution of a function (and possibly pushing its value onto the stack),
# update the pattern space to be the next thing to execute. This expects the pattern space to be
# the stack, and the hold space to be the execution (as the first thing it does is swap.)
:next
 	# Swap the value stack back
	x

	## ASSERTION: Ensure the current execution is actually finished
	/[^0a-z ]C/{s/^/next when not done with a function\n/;bbug
	}

	# Delete the iteration and the `CURRENT` marker.
	s/[0a-z ]C/  /

	# Check to see if there's a previous thing to run. If not, we're at end of program.
	/(.*[0-9])_/!{s/.*/<END OF PROGRAM>/p;q;}

	# Mark the previous thing as the next thing to run.
	s//\1C/

	## ASSERTION: Make sure the arity is between 1 to 4.
	/[1-4]C/!{s/^/arity isnt the right size\n/;bbug
	}

	# Reset branch condition
	s/^$//;tnext.0
	:next.0

	# Reduce the arity by one. The `run.function.zero-arity` is an optimization, and not technically
	# required.
	s/1C/0C/;trun.function.zero-arity
	s/2C/1C/;trun
	s/3C/2C/;trun
	s/4C/3C/
	# FALLTHRU

# EXECUTE A VALUE
:run

	#################################################################################################
	#                                           Literals                                            #
	#################################################################################################

	## Execute strings and integers by just pushing them on the stack
	/C[is]/{
		# Push onto the stack
		# TODO: should this go on the back, or front like we have? if so, modify const fns
		H;x;s/(.*)\n(.* C)([is][^|]*).*/\3|\1/
		# Move back to the previous reference
		bnext
	}

	#################################################################################################
	#                                           Variables                                           #
	#################################################################################################
	/Cv/brun.todo


	#################################################################################################
	#                                           Functions                                           #
	#################################################################################################

	## ASSERTION: Ensure the current value is a function now; non-functions are handled before this.
	/C[^f]/{s/^/CURRENT value is a non-function with args\n/;bbug
	}

	# Set the arity of the function if it's not currently set.
	/ Cf/{
		# Reset jump
		s/^$//;trun.1
		:run.1

		# (TODO: handle `|` function when we are done)

		# Technically these can all `b` to `run`, but they jump to other locations as optimizations.
		s/ (Cf[TFNPR@])/0\1/;trun.function.zero-arity
		s/ (Cf[][BCQDOL!~A,])/1\1/;trun.function.nonzero-arity
		s# (Cf[-+*/%<>?&;=W])#2\1#;trun.function.nonzero-arity
		s/ (Cf[IG])/3\1/;trun.function.nonzero-arity
		s/ (CfS)/4\1/;trun.function.nonzero-arity

		s/^/unknown function encountered/;bbug
	}

	# Special cases for functions with non-zero arity
	:run.function.nonzero-arity

	## &
	/1Cf&/{s//aCf\&/;x
		s/^[^|]*/&|&/
		bto_boolean
	}
	/aCf&/{x
		/^T\|/{
			s///; # DELETE The `T`
			s/^[^|]*\|//; # Delete the first argument to `&`
			x; # go back to the instruction stack
			# unconditionally just jump to the next value as if `&` never existed
			s/aC(f.[^N]*)N([^|]*\| ) /  \1C\2N/;
			brun
		}
		bdbg
	}

	# Functions which dont always execute their args
	/1Cf[W&|B=]|2CfI/{
		i\
			TODO: deferred evaluation function
		q
	}

	# ; -- delete the first argument from the stack after evaluating it, it's not needed.
	/1Cf;/{x
		s/^[^|]*\|// ;# Delete the topmost element on the stack
		x
		# FALLTHRU
	}

	## Functions which always execute their args: Execute their arguments.
	/[^0]C/{
		s/([^0])C(f.[^N]*)N([^|]*\| ) /\1_\2C\3N/
		brun
	}

	s/^/shouldn't get here/;bbug

	:run.todo
	s/.*0C.(.)/todo: function \1/p;q

################################################################################
#                                   Arity 0                                    #
################################################################################
	:run.function.zero-arity
	/[^0a-z]C/{s/^/went to run.function.zero-arity with a nonzero-arity function\n/;bbug
	}

	# Keyword literals
	/0CfT/{ x;s/^/T|/;bnext
	}
	/0CfF/{ x;s/^/F|/;bnext
	}
	/0CfN/{ x;s/^/N|/;bnext
	}

	## PROMPT
	/0CfP/brun.todo

	## RANDOM
	/0CfR/brun.todo

################################################################################
#                                   Arity 1                                    #
################################################################################
	# No `B`, it's handled elsewhere

	## CALL
	/0CfC/brun.todo

	## QUIT
	/0CfQ/{s//aCfQ/;x;bto_integer
	}
	/aCfQ/{x;s/^([0-9]*).*/<exit with status \1>\n/p;q;}

	## DUMP
	/0CfD/{x;H
		/^N\|.*/{
			#s//null/p
			x;s/.*//
			x;s/.*//;p
			q
			bdbg
		}
		bdbg
	}

	## OUTPUT
	/0CfO/{s//aCfO/;x;bto_string
	}
	/aCfO/{x;
		# TODO: `\` at the end of the line
		s/\|/\n/1
		P;
		s/.*\n/N|/; # Delete the current line from the stack, replacing with null
		bnext
	}

	## LENGTH
	/0CfL/brun.todo

	## !
	/0Cf!/{s//aCf!/;x;bto_boolean
	}
	/aCf!/{x
		s/^T/_/
		s/^F/T/
		s/^_/F/
		bnext
	}

	## ~
	/0Cf~/{s//aCf~/;x;bto_integer
	}
	/aCf~/{x
		s/^/i-/
		s/^i--/i/
		s/^i-0\|/i0/
		bnext
	}

	## ASCII
	/0CfA/brun.todo

	## , [ and ]
	/0Cf[][,]/brun.todo

################################################################################
#                                   Arity 2                                    #
################################################################################

	## +
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

	## -
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

	## *, /, %, ^, <, >
	/0Cf[*/%^<>]/brun.todo

	## ?
	/0Cf\?/brun.todo

	# (& and | are handled earlier)

	## ;
	/0Cf;/{x;
		# DO NOTHING, as we've already executed the first argument. TODO: can this be optimized out,
		# and we never actually reach this?
		bnext
	}

	# (WHILE is handled earlier)

################################################################################
#                                   Arity 3                                    #
################################################################################

	# (IF is handled earlier)

	## GET
	/0CfG/brun.todo

################################################################################
#                                   Arity 4                                    #
################################################################################

	## SET
	/0CfS/brun.todo

## EVERYTHING ELSE IS A BUG ##
	s/.*0Cf(.).*/unknown function: \1/p
	q

####################################################################################################
#                                                                                                  #
#                                           conversions                                            #
#                                                                                                  #
####################################################################################################

:to_array
	i\
	todo: to_array
	q
	bto_array

:to_string
	/^a/bdbg
	s/^T/true/
	s/^F/false/
	s/^N/null/; # TODO: MAKE EMPTY
	s/^[is]//
	x
	brun.function.zero-arity

:to_boolean
	/^a/bdbg
	s/^([sN]|i0)\|/F|/
	s/^[is][^|]*/T/
	/^[TF]/!{s/^/somehow to_boolean failed/;bbug
	}
	x
	brun

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

####################################################################################################
#                                                                                                  #
#                                            Operators                                             #
#                                                                                                  #
####################################################################################################

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
	s/(.*)__END_OF_ADDSUB__.*__END_OF_ADDSUB_ARGS__/i\1/
	x;s/\n.*//;x
	bnext

