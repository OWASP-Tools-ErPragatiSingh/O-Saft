#! /bin/sh
#?
#? NAME
#?      $0 - postprocess to colourize output of o-saft.pl
#?
#? SYNOPSIS
#?      o-saft.pl | $0 
#?
#? DESCRIPTION
#?      That's it.
#?
#? OPTIONS
#?      --h     got it
#?      --test  simple self-testing
#?      --line  colourize complete line
#?      --word  colourize special words
#?      --italic colourize special words and additionally print "label texts:"
#?               with italic characters
#?              "label text:" is all text left of first : including :
#?      --NUM   if a number, change assumed terminal width to number
#?              (used for padding text on the right);  default: terminal width
#?
#? LIMITATIONS
#?      With --line  all formatting with spaces and TABs is lost.
#?
#?      Requires additional UNIX-style programs:
#?        /bin/echo, egrep, sed, tput, wc .
#
# HACKER's INFO
#       Feel free to write your own code. You just need to add/modify the code
#       following "main" below.
#
#       How it workd, see function  testeme  below calling with  $0 --test
#?
#? VERSION
#?      @(#) bunt.sh 1.1 16/01/08 18:00:26
#?
#? AUTHOR
#?      08-jan-16 Achim Hoffmann _at_ sicsec .dot. de
#?
# -----------------------------------------------------------------------------

if [ -n "$TERM" ]; then
	case "$TERM" in
	  screen) \echo "**WARNING: TERM=screen; take care ..." >&2; ;;
	esac
else
	# not a terminal, switch off terminal capabilities
	# checks are done with:    [ -z "$TERM" ]
	# probably better exit here
	true
fi

# --------------------------------------------- internal variables; defaults
try=''
ich=${0##*/}
dir=${0%/*}
[ "$dir" = "$0" ] && dir="." # $0 found via $PATH in .

seq=/usr/bin/seq
echo=/bin/echo
# try to detect GNU echo
if [ -x $echo ]; then
	$echo --version | \egrep -q 'echo.*GNU'
	if [ $? -ne 0 ]; then
		\echo "**WARNING: not GNU $echo; take care ..." >&2
	fi

	echo="/bin/echo -e"
	    # more escape sequenzes for GNU /bin/echo:
	    # \a alarm    \c no more output
fi

word=1          # default: colourize words
italic=0        # default: nothing italic
_LEN=80         # default: 80 characters per line; set to termial width below
_MOD=0          # default: normal text, no highlight, bold, italic, underline, ...
	# more modes for GNU /bin/echo:
	# [0 normal
	# [1 bold/highlight
	# [2 dark
	# [3 normal italic
	# [4 normal underlined
	# [6 normal light gray
	# [7 normal reversed
	# [8 reversed bold
	# [9 normal strike

# colours   # escape sequence to be used in echo
#-----------+----------------------------------------
 black='0'; #  black='0;30m';	   dark_gray='1;30m'
   red='1'; #    red='0;31m';	   light_red='1;31m'
 green='2'; #  green='0;32m';	 light_green='1;32m'
 brown='3'; #  brown='0;33m';	      yellow='1;33m'
  blue='4'; #   blue='0;34m';	  light_blue='1;34m'
purple='5'; # purple='0;35m';	light_purple='1;35m'
  cyan='6'; #   cyan='0;36m';	  light_cyan='1;36m'
  gray='7'; #   gray='0;37m';	       white='1;37m'
#-----------+----------------------------------------
# we use $_MOD later to switch to light colours

_FG=""
_BG=""  # default: do not change background

# check terminal width
# NOTE: Unfortunatelly stty fails if we have no terminal, i.e. in cron,
#       or the intended use  in a stream (pipe).  Hence we use tput; if
#       that fails too, 80 will be hardcoded (which then may return the 
#       warning about length misatches).
arg=`\tput cols`
expr "$arg" + 0 >/dev/null ; # prints warning on STDERR
[ $? -eq 0 ] && len=$arg
if [ -n "$COLUMNS" ]; then
	# we got a hint, i.e. a bash
	[ $COLUMNS -ne $len ] && \echo "**WARNING: terminal width $COLUMNS mismatch, using $len"
fi
_LEN=$len       # got it


# --------------------------------------------- functions
colour () {
	[ -z "$TERM" ] && echo $@ && return
        _bg=''
        _fg=''
	[ -n "$_BG"  ] && _bg='\033[1;4'$_BG'm'
	[ -n "$_FG"  ] && _fg='\033['$_MOD';3'$_FG'm'
	$echo "$_fg$_bg$@\033[0m\c"
	# does not print \n at end of line, must be done by caller
}

colour_reset () {
	$echo "\033[0;m\033[0m\c"
}

# as changing text colour (forground) is the most common usage, there is one
# function for each color, and one function to just switch the background

background () {
	case "$1" in
		black)	_BG=$black ; ;;
		red)	_BG=$red   ; ;;
		green)	_BG=$green ; ;;
		brown)	_BG=$brown ; ;;
		blue)	_BG=$blue  ; ;;
		purple)	_BG=$purple; ;;
		cyan)	_BG=$cyan  ; ;;
		gray)	_BG=$gray  ; ;;
		*)	_BG=''; ;;
	esac
}

black () {
	m=$_FG; _FG=$black;    colour "$@"; _FG=$m
}
red () {
	m=$_FG; _FG=$red;      colour "$@"; _FG=$m
}
green () {
	m=$_FG; _FG=$green;    colour "$@"; _FG=$m
}
brown () {
	m=$_FG; _FG=$brown;    colour "$@"; _FG=$m
}
blue () {
	m=$_FG; _FG=$blue;     colour "$@"; _FG=$m
}
purple () {
	m=$_FG; _FG=$purple;   colour "$@"; _FG=$m
}
cyan () {
	m=$_FG; _FG=$cyan;     colour "$@"; _FG=$m
}
gray () {
	m=$_FG; _FG=$gray;     colour "$@"; _FG=$m
}
white () {
	m=$_MOD; _MOD=1;       gray "$@";   _MOD=$m
}
yellow () {
	m=$_MOD; _MOD=1;       brown "$@";  _MOD=$m
}
boldred () {
	m=$_MOD; _MOD=1;       red "$@";    _MOD=$m
}
boldpurple () {
	m=$_MOD; _MOD=1;       purple "$@"; _MOD=$m
}
underline () {
	m=$_MOD; _MOD=4;       purple "$@"; _MOD=$m
}
something () {
	m=$_MOD; _MOD=6;       purple "$@"; _MOD=$m
}
strike () {
	m=$_MOD; _MOD=9;       purple "$@"; _MOD=$m
}
reverse () {
	f=$_FG;  _FG=$gray
	m=$_MOD; _MOD=7;       colour "$@"; _MOD=$m; _FG=$f
}
italic () {
	f=$_FG;  _FG=$gray
	m=$_MOD; _MOD=3;       colour "$@"; _MOD=$m; _FG=$f
}

italic_label () {
	\echo "$@" | \sed -e  "s/^\(.*:\)/`italic \&`/"
}

pad_right () {
	space=""
	if [ -x $seq ]; then
		from=`echo "$@" | \wc -c`
		for s in `$seq $from $_LEN`; do
			space="$space "
		done
	fi
	$echo "$@$space"
}

testeme () {
	txt=`pad_right "  line padded"`; $echo "\033[7;37m$txt\033[m"
	red     " line  red\n"
	green   " line  green\n"
	brown   " line  brown\n"
	blue    " line  blue\n"
	purple  " line  purple\n"
	cyan    " line  cyan\n"
	gray    " line  gray\n"
	black   " line  black\n"
	white   " line  white\n"
	yellow  " line  yellow\n"
	underline " line  underlined\n"
	strike  " line  striked\n"
	something " line  something\n"
	$echo   " line with `red 'red'` word"
	$echo   " line with `red 'red'` `reverse and` `green 'green'` word"
	$echo   " line with `strike 'striked'` `reverse and` `underline 'underlined'` word"
	reverse " line reverse\n"
	italic_label "label with italic text: normal text "
	background cyan
	black   " line  black\n"
	green   " line  green\n"

	background ''
	$echo   `boldred "background just for the text"`
	colour_reset    # no reset background completely
	$echo   `green "done"`
}

# --------------------------------------------- options
while [ $# -gt 0 ]; do
	case "$1" in
	 '-h' | '--h' | '--help')
		\sed -ne "s/\$0/$ich/g" -e '/^#?/s/#?//p' $0
		exit 0
		;;
	  '--version')
		\sed -ne '/^#? VERSION/{' -e n -e 's/#?//' -e p -e '}' $0
		exit 0
		;;
	  '--line')   word=0; italic=0; ;;
	  '--word')   word=1; ;;
	  '--italic') word=1; italic=1; ;;
	  '--test') testeme; exit 0 ;;
	  --*)
		arg=`expr "$1" ':' '--\(.*\)'`
		expr "$arg" + 0 >/dev/null ; # prints warning on STDERR
		if [ $? -eq 0 ]; then
			[ $arg -gt $_LEN ] && \
				\echo "**WARNING: given width $arg larger than computed size $_LEN"
			_LEN=$arg
		fi
		;;
	esac
	shift
done

# --------------------------------------------- main

# get o-saft.pl's markup as regex
#	o-saft.pl --help=ourstr

bgcyan () {
	background cyan
	$echo `gray  "$@"`
	colour_reset    # FIXME: does not yet work proper
}

if [ -t 0 ]; then
	\echo "**ERROR [$ich]: text on STDIN expected; exit" >&2
	exit 2
fi
while read line; do
	[ -z "$line" ] &&	$echo && continue;   # speed!
	case "$line" in
		  \#\[*)	true; ;;
		  #\#yeast*CMD:*) bgcyan        "$line";      continue; ;;
		  \#*)		$echo `blue    "$line"`;     continue; ;;
		  \*\*HINT*)	$echo `purple  "$line"`;     continue; ;;
		  \*\*WARN*)	$echo `boldpurple "$line"`;  continue; ;;
		  \*\*ERROR*)	$echo `boldred "$line"`;     continue; ;;
		  =*)	line=`pad_right "$line"`; $echo "\033[7;37m$line\033[m"; continue; ;;
			#$echo `reverse "$line$space"`	# squeezes blanks :-((
		  "Use of "*perl*) $echo `purple "$line"`;   continue; ;;
	esac
	if [ $word -eq 0 ]; then
		case "$line" in
		  *"<<"*">>"*)	$echo `cyan  "$line"`; ;;
		  *yes*weak)	$echo `red   "$line"`; ;;
		  *yes*WEAK)	$echo `red   "$line"`; ;;
		  *yes*low)	$echo `red   "$line"`; ;;
		  *yes*LOW)	$echo `red   "$line"`; ;;
		  *yes*medium)	$echo `brown "$line"`; ;;
		  *yes*MEDIUM)	$echo `brown "$line"`; ;;
		  *yes*high)	$echo `green "$line"`; ;;
		  *yes*HIGH)	$echo `green "$line"`; ;;
		  *yes)		$echo `green "$line"`; ;;
		  *no)		$echo `brown "$line"`; ;;
		  *"no "*)	$echo `red   "$line"`; ;;
		  *)		$echo "$line"; ;;
		esac
	fi

	if [ $word -eq 1 ]; then
		[ $italic -eq 1 ] && line=`italic_label "$line"`
		# first a general check to improve performance
		\echo "$line" | \egrep -q -i '(LOW|WEAK|MEDIUM|HIGH|yes)$'
		if [ $? -eq 0 ]; then
			\echo "$line" | \egrep -q 'yes$'
			[ $? -eq 0 ] && \echo "$line" | \sed -e "s/yes$/`green yes`/" && continue
			\echo "$line" | \egrep -q -i 'yes.*(WEAK|LOW|MEDIUM|HIGH)$'
			[ $? -eq 0 ] && \echo "$line" | \sed \
					-e "s/\(LOW\)$/`red \&`/i"	\
					-e "s/\(WEAK\)$/`red \&`/i"	\
					-e "s/\(MEDIUM\)$/`brown \&`/i"	\
					-e "s/\(HIGH\)$/`green \&`/i"	\
				     && continue
			$echo "$line"
			continue
		fi
		# anything with "no" in value is a bit special
		\echo "$line" | \egrep -q 'no$'
		[ $? -eq 0 ] && \echo "$line" | \sed -e  "s/no$/`brown no`/"  && continue
		\echo "$line" | \egrep -q 'no \('
		[ $? -eq 0 ] && \echo "$line" | \sed -e "s/\(no (.*\)/`brown \&`/"  && continue
		\echo "$line" | \egrep -q '^#\['
		[ $? -eq 0 ] && \echo "$line" | \sed -e  "s/^\(#\[.*\]\)/`cyan \&`/"  && continue
		$echo "$line"
        fi

done

exit 0
