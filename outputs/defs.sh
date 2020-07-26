#!/bin/bash

raw_outputs=/project/raw

example() {
    filename="$raw_outputs/$1.out"
    shift

    parent=$(dirname $filename)
    mkdir -p $parent

    # print the command to the file
    echo "$ $@" &>> "$filename"

    # get the command's output
    script -q -a "$filename" -c "$@"

    # strip "script started/done" output from the file
    grep -v '^Script started\|^Script done' "$filename" > "${filename}.tmp"
    sed -i~ '$d' "${filename}.tmp"
    mv "${filename}.tmp" "$filename"
}
