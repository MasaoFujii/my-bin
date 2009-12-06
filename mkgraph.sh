#!/bin/sh

PROGNAME=$(basename $0)
INPUT=
PLOT=

usage ()
{
	echo "$PROGNAME creates graph"
	echo ""
	echo "Usage:"
	echo "  $PROGNAME [OPTIONS] INPUT PLOT"
	echo ""
	echo "Options:"
	echo "  -h                     shows this help, then exits"
	echo "  -o                     output png file"
	echo "  -t                     shows graph title"
}



gnuplot <<EOF
set terminal png
set output "$output"
set title "$title"
set border 3
set xtics nomirror
set ytics nomirror
set lmargin 10
set bmargin 3
set rmargin 2
set tmargin 1

EOF