###
##

## NOTE: All `ASSERTIONS:` can be completely removed and the program should stay the same.
# That means that things shouldnt rely on the `s//` from them.

#1{=;s/^/;/;}

####################################################################################################
#                                                                                                  #
#                                        Parsing the Input                                         #
#                                                                                                  #
####################################################################################################

# If we ever receive `^X__END__$` on its own line, then that means we're done parsing. (We use the
# `X` to start it as no valid knight expression can start with it)
/^X__END__$/{
	s///       ;# Delete `X__END__`
	x          ;# Swap to the program that's been parsed

	## Cleanup the program
	s/^\n//    ;# Delete the `\n` that's on the first line
	y/\n/|/    ;# Convert all newlines (which separated the parsed values) to `|`, the program sep
	s/$/|  f:/ ;# Add a dummy function to the end, which is needed for proper functioning.

	## Check to make sure there's actually something to execute.
	/^  [^f]/q ;# If the very first thing isn't a function, then exit.

	## Get ready for execution
	s/ /C/2    ;# Add "current" marker to the first function
	s/ /N/3    ;# Add "next" marker to the next value

	## Execute the program
	brun
}

## parse out a value.
# `parse` is its own label, so we can go to it after parsing a value. It intentionally doesn't
# include the `X__END__` check, as the only time we ever completely restart execution from the top
# is during the `/^(#|$)/d` check.
:parse

	## Delete leading whitespace and comments
	s/^[[:space:]:()]+// ;# Strip leading whitespace from the line
	/^(#|$)/d            ;# If the line starts with a `#` or is empty, delete it and go again.

	## Parse strings, if the line starts with a quote.
	/^["']/{
		:parse.string

		# If we don't have a full string on this line, then accumulate until we do.
		/^"([^"]*)"|^'([^']*)'/!{
			N;             # Adds a newline followed by the next input line to the pattern space.
			bparse.string
		}
		s//  s\1\2\x1F/;# Double quotes were found. Replace the string with its parsed replacement
		s/\n/_NL_/     ;# Replace any newlines with _NL_ (TODO: make this an ascii control charcater and use `y`)
		bparse.append
	}

	# Reset the "jump" counter so the `s` below can jump down
	s/^$//;tparse.0
	:parse.0

	## Parse out the remaining (non-multiline) constructs: Integers, variables, and functions
	s/^[0-9]+/  i&\x1F/;tparse.append
	s/^[a-z_0-9]+/  v&\x1F/;tparse.append
	s/^([A-Z])[A-Z_]*/  f\1\x1F/;tparse.append
	s/^(.)/  f&\x1F/;tparse.append

	## ASSERTION: Somehow nothing could be parsed?
	s/.*/unable to parse out something?/;bug

	## Append the value we parsed to the end of the program, and continue parsing
	:parse.append
		H          ;# Add the value we just parsed along with the rest of the line to the program.
		s/.*\x1F// ;# Delete off what was just parsed from the current line.
		x          ;# Swap to the program to delete the remainder of the line.
		s/\x1F.*// ;# Delete everything after the parsed value from the program.
		x          ;# Go back to the parsed line, So we can begin parsing the nextline
		bparse

###
# The program will never reach this point. Execution is only ever restarted via the `d` within
# `parse`, and the `X__END__` check above goes directly down to `run`.
###
bug

####################################################################################################
#                                            Utilities                                             #
####################################################################################################

# Named `ug` so we can `bug` and branch to bug. lol im silly.
:ug
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


####################################################################################################
#                                                                                                  #
#                                        Program Execution                                         #
#                                                                                                  #
####################################################################################################

## After finishing the execution of a function (and possibly pushing its value onto the stack),
# update the pattern space to be the next thing to execute. This expects the pattern space to be
# the stack, and the hold space to be the execution (as the first thing it does is swap.)
:next
 	# Swap the value stack back
	x
:next_nx

	## ASSERTION: Ensure the current execution is actually finished
	/[^0a-z ]C/{s/^/next when not done with a function\n/;bug
	}

	# Delete the iteration and the `CURRENT` marker.
	s/[0a-z ]C/  /

	# Check to see if there's a previous thing to run. If not, we're at end of program.
	/(.*[0-9])_/!{s/.*/<END OF PROGRAM>/p;q;}

	# Mark the previous thing as the next thing to run.
	s//\1C/

	## ASSERTION: Make sure the arity is between 1 to 4.
	/[1-4]C/!{s/^/arity isnt the right size\n/;bug
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
	l
	#################################################################################################
	#                                           Literals                                            #
	#################################################################################################

	## Execute strings and integers by just pushing them on the stack
	/C[is]/{
		# If we're not executing, don't actually push the literal onto the stack.
		#/^#/bnext_nx

		# Push onto the stack
		H;x;s/(.*)\n(.* C)([is][^|]*).*/\3|\1/
		# Move back to the previous reference
		bnext
	}

	#################################################################################################
	#                                           Variables                                           #
	#################################################################################################
	/Cv/{
		# If we're not executing, don't actually push the variable onto the stack.
		/^#/bnext_nx

		brun.todo
	}


	#################################################################################################
	#                                           Functions                                           #
	#################################################################################################

	## ASSERTION: Ensure the current value is a function now; non-functions are handled before this.
	/C[^f]/{s/^/CURRENT value is a non-function with args\n/;bug
	}

	# Set the arity of the function if it's not currently set.
	/ Cf/{
		# Reset jump
		s/^$//;trun.1
		:run.1

		# (TODO: handle `|` function when we are done)

		# Technically these can all `b` to `run`, but they jump to other locations as optimizations.

		# vvv todo: this won't jump to the `#` place
		s/ (Cf[TFNPR@])/0\1/;trun.function.zero-arity

		s/ (Cf[][BCQDOL!~A,])/1\1/;trun.function.nonzero-arity
		s# (Cf[-+*/%<>?&;=W])#2\1#;trun.function.nonzero-arity
		s/ (Cf[IG])/3\1/;trun.function.nonzero-arity
		s/ (CfS)/4\1/;trun.function.nonzero-arity

		s/^/unknown function encountered/;bug
	}
#
#	# Special cases for functions with non-zero arity
	:run.function.nonzero-arity
#	/^#.*[^0]C/{
#		s/([^0])C(f.[^N]*)N([^|]*\| ) /\1_\2C\3N/
#		brun
#	}


	## &
	/1Cf&/{s//aCf\&/;x
		brun.todo
		s/^[^|]*/&|&/
		bto_boolean
	}
	/aCf&/{x
		brun.todo
		# Top of the stack is true, pop it off and run the right
		/^T\|/{
			s///; # DELETE The `T`
			s/^[^|]*\|//; # Delete the first argument to `&`
			x; # go back to the instruction stack
			# unconditionally just jump to the next value as if `&` never existed
			s/aC(f.[^N]*)N([^|]*\| ) /  \1C\2N/;
			brun
		}

		## ASSERTION: `bto_boolean` ever puts T or F on the stack
		/^F\|/!{s/^/bto_boolean didnt put a T or F on top\n/;bug
		}

		s/^F\|//; # Delete the "false" conditional out
		x; # go back to the instruction space
		s/^/#/; # Add the indicator that we're not actually executing programs rn to the front
		s/aCf&/0Cf\&/
		brun.execute-next
	}

	/0Cf&/{
		brun.todo
		s/^#//; # Delete the frontmost "dont execute" marker
		bnext_nx
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
		:run.execute-next
		s/([^0])C(f.[^N]*)N([^|]*\| ) /\1_\2C\3N/
		brun
	}

	s/^/shouldn't get here\n/;bug

	:run.todo
	s/.*0C.(.).*/todo: function \1/p;q

################################################################################
#                                   Arity 0                                    #
################################################################################
	:run.function.zero-arity
	/[^0a-z]C/{s/^/went to run.function.zero-arity with a nonzero-arity function\n/;bug
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
		# TODO: `\` at the end of the line, and convert `_NL_` to newlines
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
	/^[TF]/!{s/^/somehow to_boolean failed/;bug
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

