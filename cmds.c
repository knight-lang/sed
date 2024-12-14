string pattern, hold;

for (pattern = readline(); !is_end_of_file(); minus_n_given || print(pattern))
{
	/* SED program */
}
```

- `d`: `pattern = ""; continue;`
- `D`: `first_line(pattern) = ""; continue;`
- `n`: `print(pattern); pattern = next_line();`
- `N`: `print(first_line(pattern)); pattern += "\n" + next_line();`

- `a\NEWLINE<text>`: (print <text> just before the next `n` or `N`)
- `c\NEWLINE<text>`: `pattern = ""; print(<text>\n); continue`
- `i\NEWLINE<text>`: `print(<text>\n)`

- `d`: `pattern = ""; continue;`
- `D`: `first_line(pattern) = ""; continue`
- `n`: `print(pattern); pattern = readline();`
- `N`: `pattern += "\n" + readline();`

- `g`: `pattern = hold`
- `G`: `pattern += "\n" + hold`
- `h`: `hold = pattern`
- `H`: `hold += "\n" + pattern`
- `x`: `pattern, hold = hold, pattern`

- `: <label>`: `<label>:`
- `b <label>`: `goto <label>;`
- `t <label>`: `if (has_subst_happened) { has_subst_happened=0; goto <label>;}`

- `l`: write debug repr to stdout
- `=`: write lineno followed by `\n` to stdout
- `p`: Print pattern to stdout
- `P`: Print first line in pattern to stdout

- `s/regex/replacement/[flags]` do replacement. if `has_subst_happened`
- `y/str1/str2/` perform `tr`-style replacement

- `r file`: print `file`'s contents to stdout
- `w file`: append pattern space to `file`

- `{`: execute commands until the matching `}`
- `#`: comment, ignore text until end of line

