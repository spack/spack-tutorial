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

    echo $cmd
    # get the command's output
    $cmd | tee -a "$filename"
}

fake_example(){
    filename="$raw_outputs/$1.out"
    shift

    fake_cmd="$1"
    shift

    parent=$(dirname $filename)
    mkdir -p $parent

    # print the command to the file
    echo "$ $fake_cmd" &>> "$filename"

    cmd="$@"

    # Don't use despacktivate alias (and strip comment)
    if [[ "$cmd" == despacktivate* ]]; then
        cmd="spack env deactivate"
    fi

    # get the command's output
    $cmd | tee -a "$filename"
}
