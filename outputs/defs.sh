#!/bin/bash

raw_outputs=/project/raw

example() {
    filename="$raw_outputs/$1.out"
    shift

    parent=$(dirname $filename)
    mkdir -p $parent

    # print the command to the file
    echo "$ $@" &>> "$filename"

    cmd="$@"

    # Don't use despacktivate alias (and strip comment)
    if [[ "$cmd" == despacktivate* ]]; then
        cmd="spack env deactivate"
    fi

    # print command to stdout to help debugging
    echo "$cmd"

    # get the command's output
    $cmd | tee -a "$filename"
}
