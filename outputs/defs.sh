#!/bin/bash

set -o pipefail
set -u

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

die_with_error() {
    printf "%b: %s\n" "\033[1;31mFAILED\033[0m" "$@"
    exit 1
}

example() {
    tee=0
    ignore_errors=0
    while [ $# -ne 0 ]; do
        case "$1" in
            --tee)
                tee=1
                shift
                ;;
            --ignore-errors)
                ignore_errors=1
                shift
                ;;
            -*)
                die_with_error "example: unknown argument $1"
                ;;
            *)
                break
                ;;
        esac
    done

    filename="$raw_outputs/$1.out"
    shift

    parent=$(dirname "$filename")
    mkdir -p "$parent"

    if [ "$#" -ne 1 ]; then die_with_error "Expected command '$*' to be quoted/literal"; fi

    # print the command to the file
    cmd="$1"
    echo "$ $cmd" &>> "$filename"

    if [ "$tee" == "1" ]; then
        # Don't use despacktivate alias (and strip comment)
        if [[ "$cmd" == despacktivate* ]]; then
            cmd="spack env deactivate"
        fi
        # get the command's output
        if ! $cmd 2>&1 | tee -a "$filename"; then
            if [ "$ignore_errors" = "0" ]; then die_with_error "'$cmd' returned with error exit code. (Use --ignore-errors if errors are expected)"; fi
        fi
    else
        if ! script -eqa "$filename" -c "$cmd"; then
            if [ "$ignore_errors" = "0" ]; then die_with_error "'$cmd' returned with error exit code. (Use --ignore-errors if errors are expected)"; fi
        fi

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

    parent=$(dirname "$filename")
    mkdir -p "$parent"

    # print the command to the file
    echo "$ $fake_cmd" &>> "$filename"

    if [ "$#" -ne 1 ]; then die_with_error "Expected command '$*' to be quoted/literal"; fi

    cmd="$1"

    # Don't use despacktivate alias (and strip comment)
    if [[ "$cmd" == despacktivate* ]]; then
        cmd="spack env deactivate"
    fi

    # print command to stdout to help debugging
    echo "$cmd"

    # get the command's output
    $cmd | tee -a "$filename"
}
