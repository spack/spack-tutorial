#!/bin/bash

# Exit on undefined variables, errors and let piped commands errors bubble up.
set -ueo pipefail

# if in a container, put stuff in the bindmounted
# /project directory (see Makefile).  Otherwise use $PWD
if [ -d /project ]; then
    PROJECT=/project
else
    PROJECT="$PWD"
fi

raw_outputs="${PROJECT}/raw"

# used by scripts
tutorial_branch=releases/v1.0

print_status() {
    printf "\n%b: %s\n\n" "\033[1;35m$1\033[0m" "$2"
}

die_with_error() {
    printf "%b: %s\n" "\033[1;31mFAILED\033[0m" "$@"
    exit 1
}

example() {
    tee=0
    expect_error=0
    while [ $# -ne 0 ]; do
        case "$1" in
            --tee)
                tee=1
                shift
                ;;
            --expect-error)
                expect_error=1
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

    parent="$(dirname "$filename")"
    mkdir -p "$parent"

    if [ "$#" -ne 1 ]; then
        die_with_error "Expected command '$*' to be quoted/literal"
    fi

    # print the command to the file
    cmd="$1"

    print_status "[$filename]" "$cmd"

    echo "$ $cmd" &>> "$filename"

    if [ "$tee" = "1" ]; then
        # Don't use despacktivate alias (and strip comment)
        if [ "$cmd" != "${cmd#despacktivate}" ]; then
            cmd="spack env deactivate"
        fi
        # get the command's output
        if ! $cmd 2>&1 | tee -a "$filename"; then
            if [ "$expect_error" = "0" ]; then
                die_with_error "'$cmd' returned with error exit code. (Use --expect-error if errors are expected)"
            fi
        elif [ "$expect_error" = "1" ]; then
            die_with_error "'$cmd' returned with success exit code, but was expected to fail."
        fi
    else
        if ! script -eqa "$filename" -c "$cmd"; then
            if [ "$expect_error" = "0" ]; then
                die_with_error "'$cmd' returned with error exit code. (Use --expect-error if errors are expected)"
            fi
        elif [ "$expect_error" = "1" ]; then
            die_with_error "'$cmd' returned with success exit code, but was expected to fail."
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

    parent="$(dirname "$filename")"
    mkdir -p "$parent"

    # print the command to the file
    echo "$ $fake_cmd" &>> "$filename"

    if [ "$#" -ne 1 ]; then
        die_with_error "Expected command '$*' to be quoted/literal"
    fi

    cmd="$1"

    # Don't use despacktivate alias (and strip comment)
    if [ "$cmd" != "${cmd#despacktivate}" ]; then
        cmd="spack env deactivate"
    fi

    # print command to stdout to help debugging
    print_status "[$filename]" "$cmd"

    # get the command's output
    if ! $cmd | tee -a "$filename"; then
        die_with_error "'$cmd' returned with error exit code."
    fi
}
