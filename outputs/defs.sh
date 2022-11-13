#!/bin/bash

# if in a container, put stuff in the bindmounted
# /project directory (see Makefile).  Otherwise use ${PWD}
if [ -d /project ]; then
    PROJECT=/project
else
    PROJECT="${PWD}"
fi

raw_outputs="${PROJECT}/raw"

# used by scripts
tutorial_branch=releases/v0.19

example() {
    if [[ "$1" == "-tee" ]]; then
        # tee option allows us to use bash function; only use when necessary
        tee=1
        shift
    else
        # non-tee option uses a pty, so we get full outputs
        tee=0
    fi

    filename="$raw_outputs/$1.out"
    shift

    parent=$(dirname $filename)
    mkdir -p $parent

    # print the command to the file
    echo "$ $@" &>> "$filename"

    if [[ "$tee" == "1" ]]; then
        cmd="$@"

        # Don't use despacktivate alias (and strip comment)
        if [[ "$@" == despacktivate* ]]; then
            cmd="spack env deactivate"
        fi

        echo $cmd
        # get the command's output
        $cmd 2>&1 | tee -a "$filename"
    else
        script -q -a "$filename" -c "$@"

        # strip "script started/done" output from the file
        grep -v '^Script started\|^Script done' "$filename" > "${filename}.tmp"
        sed -i~ '$d' "${filename}.tmp"
        mv "${filename}.tmp" "$filename"
    fi
}

# This allows us to echo a different command than we run
# Used to stay out of the build environment subshell
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

    # print command to stdout to help debugging
    echo "$cmd"

    # get the command's output
    $cmd | tee -a "$filename"
}
