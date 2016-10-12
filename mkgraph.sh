#!/bin/sh

PROGNAME=$(basename $0)
INPUT=
OUTPUT=
TITLE=
PLOT=
PLOTSTR=
XLABEL=
YLABEL=

usage ()
{
cat <<EOF
$PROGNAME creates graph.

Usage:
  $PROGNAME [OPTIONS] INPUT PLOT

Description:
  This utility creates the line graph which plots INPUT file
  according to the PLOT format.

  PLOT: field_number_of_x-axis:field_number_of_y-axis[@label_title]

  For example, the following command plots the run/wait queue of
  vmstat output (the run/wait queue is 1st/2nd field of vmstat output).

      vmstat 1 > vmstat.log
      $PROGNAME vmstat.log 0:1@\"run queue\",0:2@\"wait queue\"

Options:
  -o FILE         uses FILE instead of INPUT.png for name of output png file
  -t TITLE        shows graph title
  --xlabel LABEL  shows label for x-axis
  --ylabel LABEL  shows label for y-axis
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		"-?"|--help)
			usage
			exit 0;;
		-o|--output)
			OUTPUT="$2"
			shift;;
		-t|--title)
			TITLE="$2"
			shift;;
		--xlabel)
			XLABEL="$2"
			shift;;
		--ylabel)
			YLABEL="$2"
			shift;;
		*)
			if [ -z "$INPUT" ]; then
				INPUT="$1"
			elif [ -z "$PLOTSTR" ]; then
				PLOTSTR="$1"
			else
				echo "$PROGNAME: too many options: $1" 1>&2
				exit 1
			fi;;
	esac
	shift
done

if [ -z "$INPUT" -o -z "$PLOTSTR" ]; then
	echo "$PROGNAME: INPUT and PLOT must be supplied" 1>&2
	exit 1
fi

if [ -z "$OUTPUT" ]; then
	OUTPUT="$INPUT.png"
fi

remain="$PLOTSTR"
while [ 1 ]; do
	values=$(echo "$remain" | cut -d, -f1)
	remain=$(echo "$remain" | cut -d, -f2-)

	plotpoint=$(echo $values | cut -d\@ -f1)
	plottitle=$(echo $values | cut -d\@ -f2)

	if [ ! -z "$PLOT" ]; then
		PLOT="$PLOT, "
	fi
	PLOT="$PLOT\"$INPUT\" using $plotpoint"

	if [ "$plottitle" != "$plotpoint" ]; then
		PLOT="$PLOT title \"$plottitle\""
	fi
	PLOT="$PLOT with lines"

	if [ "$values" = "$remain" -o -z "$remain" ]; then
		break
	fi
done

gnuplot <<EOF
set terminal png
set output "$OUTPUT"
set title "$TITLE"
set border 3
set xtics nomirror
set ytics nomirror
set xlabel "$XLABEL"
set ylabel "$YLABEL"
set lmargin 10
set bmargin 3
set rmargin 2
set tmargin 1
plot $PLOT
EOF
