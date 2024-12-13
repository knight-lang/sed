###
##
# Separators (the ` is part of them):
# `NL` newline replacement used to represent strings
# `PS` program separator, put between elements
# `CUR` current function
# `NXT` Next function
# `DFR` deferred function, ie it hasnt gotten all its args


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
	s/^\n//     ;# Delete the `\n` that's on the first line
	s/$/\n  f:/ ;# Add a dummy function to the end, which is needed for proper functioning.
	y/\n/`PS`/  ;# Convert all newlines (which separated the parsed values) to `PS`, the program sep

	## Check to make sure there's actually something to execute.
	/^  [^f]/q ;# If the very first thing isn't a function, then exit.

	## Get ready for execution
	x;s/^/`VARS`/;x ;# Get ready for the list of variables
	s/ /`CUR`/2    ;# Add "current" marker to the first function
	s/ /`NXT`/3    ;# Add "next" marker to the next value

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
		s/\n/`NL`/     ;# Replace any newlines with `NL` (TODO: make this an ascii control charcater and use `y`)
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
	/[^0a-z ]`CUR`/{s/^/next when not done with a function\n/;bug
	}

	# Delete the iteration and the `CURRENT` marker.
	s/[0a-z ]`CUR`/  /

	# Check to see if there's a previous thing to run. If not, we're at end of program.
	#/(.*[0-9])`DFR`/!{s/.*/<END OF PROGRAM>/p;q;}
	/(.*[0-9])`DFR`/!q

	# Mark the previous thing as the next thing to run.
	s//\1`CUR`/

	## ASSERTION: Make sure the arity is between 1 to 4.
	/[1-4]`CUR`/!{s/^/arity isnt the right size\n/;bug
	}

	# Reset branch condition
	s/^$//;tnext.0
	:next.0

	# Reduce the arity by one. The `run.function.zero-arity` is an optimization, and not technically
	# required.
	s/1`CUR`/0`CUR`/;trun.function.zero-arity
	s/2`CUR`/1`CUR`/;trun
	s/3`CUR`/2`CUR`/;trun
	s/4`CUR`/3`CUR`/
	# FALLTHRU

# EXECUTE A VALUE
:run

	#################################################################################################
	#                                           Literals                                            #
	#################################################################################################

	## Execute strings and integers by just pushing them on the stack
	/`CUR`[is]/{
		# If we're not executing, don't actually push the literal onto the stack.
		#/^#/bnext_nx

		# Push onto the stack
		H;x;s/(.*)\n(.* `CUR`)([is][^`PS`]*).*/\3`PS`\1/
		# Move back to the previous reference
		bnext
	}

	#################################################################################################
	#                                           Variables                                           #
	#################################################################################################
	/`CUR`v/{
		# If we're not executing, don't actually push the variable onto the stack.
		/^#/bnext_nx
		bdbg
		brun.todo
	}


	#################################################################################################
	#                                           Functions                                           #
	#################################################################################################

	## ASSERTION: Ensure the current value is a function now; non-functions are handled before this.
	/`CUR`[^f]/{s/^/CURRENT value is a non-function with args\n/;bug
	}

	# Set the arity of the function if it's not currently set.
	/ `CUR`f/{
		# Reset jump
		s/^$//;trun.1
		:run.1

		# Technically these can all `b` to `run`, but they jump to other locations as optimizations.

		# vvv todo: this won't jump to the `#` place
		s/ (`CUR`f[TFNPR@])/0\1/;trun.function.zero-arity

		s/ (`CUR`f[][BCQDOL!~A,])/1\1/;trun.function.nonzero-arity
		s# (`CUR`f[-+*/%<>?&;=W|])#2\1#;trun.function.nonzero-arity
		s/ (`CUR`f[IG])/3\1/;trun.function.nonzero-arity
		s/ (`CUR`fS)/4\1/;trun.function.nonzero-arity

		s/^/unknown function encountered/;bug
	}
#
#	# Special cases for functions with non-zero arity
	:run.function.nonzero-arity
#	/^#.*[^0]C/{
#		s/([^0])C(f.[^N]*)N([^|]*`PS` ) /\1_\2C\3N/
#		brun
#	}


	## &
	/1`CUR`f&/{s//a`CUR`f\&/;x
		brun.todo
		s/^[^`PS`]*/&`PS`&/
		bto_boolean
	}
	/a`CUR`f&/{x
		brun.todo
		# Top of the stack is true, pop it off and run the right
		/^T`PS`/{
			s///; # DELETE The `T`
			s/^[^`PS`]*`PS`//; # Delete the first argument to `&`
			x; # go back to the instruction stack
			# unconditionally just jump to the next value as if `&` never existed
			s/a`CUR`(f.[^`NXT`]*)`NXT`([^`PS`]*`PS` ) /  \1`CUR`\2`NXT`/;
			brun
		}

		## ASSERTION: `bto_boolean` ever puts T or F on the stack
		/^F`PS`/!{s/^/bto_boolean didnt put a T or F on top\n/;bug
		}

		s/^F`PS`//; # Delete the "false" conditional out
		x; # go back to the instruction space
		s/^/#/; # Add the indicator that we're not actually executing programs rn to the front
		s/a`CUR`f&/0`CUR`f\&/
		brun.execute-next
	}

	/0`CUR`f&/{
		brun.todo
		s/^#//; # Delete the frontmost "dont execute" marker
		bnext_nx
	}

	# Functions which dont always execute their args
	/1`CUR`f[W&|B=]|2`CUR`fI/{
		i\
			TODO: deferred evaluation function
		q
	}

	# ; -- delete the first argument from the stack after evaluating it, it's not needed.
	/1`CUR`f;/{x
		s/^[^`PS`]*`PS`// ;# Delete the topmost element on the stack
		x
		# FALLTHRU
	}

	## Functions which always execute their args: Execute their arguments.
	/[^0]`CUR`/{
		:run.execute-next
		s/([^0])`CUR`(f.[^`NXT`]*)`NXT`([^`PS`]*`PS` ) /\1`DFR`\2`CUR`\3`NXT`/
		brun
	}

	s/^/shouldn't get here\n/;bug

	:run.todo
		s/.*`CUR`.(.).*/todo: function \1\n/p;q

################################################################################
#                                   Arity 0                                    #
################################################################################
	:run.function.zero-arity
	/[^0a-z]`CUR`/{s/^/went to run.function.zero-arity with a nonzero-arity function\n/;bug
	}

	# Keyword literals
	/0`CUR`fT/{ x;s/^/T`PS`/;bnext
	}
	/0`CUR`fF/{ x;s/^/F`PS`/;bnext
	}
	/0`CUR`fN/{ x;s/^/N`PS`/;bnext
	}

	## PROMPT
	/0`CUR`fP/brun.todo

	## RANDOM
	/0`CUR`fR/brun.todo

################################################################################
#                                   Arity 1                                    #
################################################################################
	# No `B`, it's handled elsewhere

	## CALL
	/0`CUR`fC/brun.todo

	## QUIT
	/0`CUR`fQ/{s//a`CUR`fQ/;x;bto_integer
	}
	/a`CUR`fQ/{x;s/^([0-9]*).*/<exit with status \1>\n/p;q;}

	## DUMP
	/0`CUR`fD/{x;H
		s/^$//;trun.DUMP.0
		:run.DUMP.0

		s/^N.*/null/;trun.DUMP.done
		s/^T.*/true/;trun.DUMP.done
		s/^F.*/false/;trun.DUMP.done
		s/^i([0-9]+).*/\1/;trun.DUMP.done

		## ASSERTION: Make sure it's a string
		/^[^s]/{s/.*/called DUMP on an invalid type/;bug
		}

		# Strings are special
		s/^s([^`PS`]*).*/\1/
		s/[\"]/\\&/g
		s/`NL`/\\n/g
		s/\x0D/\\r/g
		s/\x09/\\t/g
		s/^/"/;s/$/"/; # Add quotes to the start and end

		# FALLTHROUGH
	:run.DUMP.done
		p           ;# Print out the current pattern space. (Technically could be on each `s/`)
		g           ;# Replace the pattern space with `<program>\n<stack>`
		s/.*\n//    ;# Delete the program from the stack
		x;s/\n.*//  ;# Delete the stack from the program
		bnext_nx
	}

	## OUTPUT
	/0`CUR`fO/{s//a`CUR`fO/;x;bto_string
	}
	/a`CUR`fO/{x
		H            ;# save the stack
		s/`PS`.*//     ;# Delete everything other than the string to print
		s/`NL`/\n/g  ;# Replace the newline replacement hack with actual newlines.

		# Reset `t`. (Technically, I dont think you need the `s/^$`, as the 's/`PS`' always works.)
		s/^$//;trun.OUTPUT.0
		:run.OUTPUT.0

		## Delete trailing `\`s, and then go to the end
		s/\\$//p;trun.OUTPUT.done

		## Add a newline to the end and print it
		s/$/\n/p

		# FALLTHROUGH
	:run.OUTPUT.done
		g;s/.*\n[^`PS`]*/N/ ;# Replace the program space with the stack, then pop, then push `N`.
		x;s/\n.*//       ;# Delete the stack from the program
		bnext_nx
	}

	## LENGTH
	/0`CUR`fL/brun.todo

	## !
	/0`CUR`f!/{s//a`CUR`f!/;x;bto_boolean
	}
	/a`CUR`f!/{x
		s/^T/_/
		s/^F/T/
		s/^_/F/
		bnext
	}

	## ~
	/0`CUR`f~/{s//a`CUR`f~/;x;bto_integer
	}
	/a`CUR`f~/{x
		s/^/i-/
		s/^i--/i/
		s/^i-0`PS`/i0/
		bnext
	}

	## ASCII
	/0`CUR`fA/brun.todo

	## , [ and ]
	/0`CUR`f[][,]/brun.todo

################################################################################
#                                   Arity 2                                    #
################################################################################

	## +
	/0`CUR`f\+/{x
		/^[^`PS`]*`PS`s/{x;s/0`CUR`f\+/s`CUR`f+/;x;bto_string
		}
		/^[^`PS`]*`PS`i/{x;s/0`CUR`f\+/i`CUR`f+/;x;bto_integer
		}
		i\
		TODO: add others
	}
	/s`CUR`f\+/{x
		s/^([^`PS`]*)`PS`s([^`PS`]*)/s\2\1/
		bnext
	}
	/i`CUR`f\+/{
		s//b`CUR`f+/;x
		s/^([^`PS`]*)`PS`i([^`PS`]*)/\2+\1__END_OF_ADDSUB_ARGS__/;x
		# FALLTHRU
	}

	## -
	/0`CUR`f-/{s//i`CUR`f-/;x;bto_integer
	}
	/i`CUR`f-/{s//b`CUR`f-/;x;
		s/`PS`/__TMP__/1
		s/`PS`/__TMP__/1
		s/(.*)__TMP__(.*)__TMP__/\2-\1__END_OF_ADDSUB_ARGS__/;
		bto_integer
	}
	/b`CUR`f[-+]/{x;
		H
		s/`PS`.*//
		bsubtract
	}

	## *, /, %, ^, <, >
	/0`CUR`f[*/%^<>]/brun.todo

	## ?
	/0`CUR`f\?/brun.todo

	# (& and | are handled earlier)

	## ;
	/0`CUR`f;/{x;
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
	/0`CUR`fG/brun.todo

################################################################################
#                                   Arity 4                                    #
################################################################################

	## SET
	/0`CUR`fS/brun.todo

## EVERYTHING ELSE IS A BUG ##
	s/.*0`CUR`f(.).*/unknown function: \1/p
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
	s/^([sN]|i0)`PS`/F`PS`/
	s/^[is][^|]*/T`PS`/
	/^[TF]/!{s/^/somehow to_boolean failed/;bug
	}
	x
	brun.function.zero-arity

:to_integer
	/^a/bdbg
	s/^T/1/
	s/^[FN]/0/
	s/^i//
	/^s/{
		s/`PS`/__TMP__/1
		tto_integer.0
		:to_integer.0
		s/^s[[:space:]]*([-+]?[0-9]+).*__TMP__/\1`PS`/;tto_integer.1
		s/^s.*__TMP__/0`PS`/
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

