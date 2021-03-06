#!/usr/bin/env bash

# @file File
# @brief Functions for handling files.

# @description Create temporary file.
# Function creates temporary file with random name. The temporary file will be deleted when script finishes.
#
# @example
#   echo "$(file::make_temp_file)"
#   #Output
#   tmp.vgftzy
#
# @noargs
#
# @exitcode 0  If successful.
# @exitcode 1 If failed to create temp file.
#
# @stdout file name of temporary file created.
file::make_temp_file() {
    declare temp_file
    type -p mktemp &> /dev/null && { temp_file="$(mktemp -u)" || temp_file="${PWD}/$((RANDOM * 2)).LOG"; }
    trap 'rm -f "${temp_file}"' EXIT
    printf "%s" "${temp_file}"
}

# @description Get only the filename from string path.
#
# @example
#   echo "$(file::name "/path/to/test.md")"
#   #Output
#   test.md
#
# @arg $1 string path.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
#
# @stdout name of the file with extension.
file::name() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
    printf "%s" "${1##*/}"
}

# @description Get the basename of file from file name.
#
# @example
#   echo "$(file::basename "/path/to/test.md")"
#   #Output
#   test
#
# @arg $1 string path.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
#
# @stdout basename of the file.
file::basename() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2

    declare file basename
    file="${1##*/}"
    basename="${file%.*}"

    printf "%s" "${basename}"
}

# @description Get the extension of file from file name.
#
# @example
#   echo "$(file::extension "/path/to/test.md")"
#   #Output
#   md
#
# @arg $1 string path.
#
# @exitcode 0  If successful.
# @exitcode 1 If no extension is found in the filename.
# @exitcode 2 Function missing arguments.
#
# @stdout extension of the file.
file::extension() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
    declare file extension
    file="${1##*/}"
    extension="${file##*.}"
    [[ "${file}" = "${extension}" ]] && return 1

    printf "%s" "${extension}"
}

# @description Get directory name from file path.
#
# @example
#   echo "$(file::dirname "/path/to/test.md")"
#   #Output
#   /path/to
#
# @arg $1 string path.
#
# @exitcode 0  If successful.
# @exitcode 2 Function missing arguments.
#
# @stdout directory path.
file::dirname() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2

    declare tmp=${1:-.}

    [[ ${tmp} != *[!/]* ]] && { printf '/\n' && return; }
    tmp="${tmp%%"${tmp##*[!/]}"}"

    [[ ${tmp} != */* ]] && { printf '.\n' && return; }
    tmp=${tmp%/*} && tmp="${tmp%%"${tmp##*[!/]}"}"

    printf '%s' "${tmp:-/}"
}

# @description Get absolute path of file or directory.
#
# @example
#   file::full_path "../path/to/file.md"
#   #Output
#   /home/labbots/docs/path/to/file.md
#
# @arg $1 string relative or absolute path to file/direcotry.
#
# @exitcode 0  If successful.
# @exitcode 1  If file/directory does not exist.
# @exitcode 2 Function missing arguments.
#
# @stdout Absolute path to file/directory.
file::full_path() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
    declare input="${1}"
    if [[ -f ${input} ]]; then
        printf "%s/%s\n" "$(cd "$(file::dirname "${input}")" && pwd)" "${input##*/}"
    elif [[ -d ${input} ]]; then
        printf "%s\n" "$(cd "${input}" && pwd)"
    else
        return 1
    fi
}

# @description Get mime type of provided input.
#
# @example
#   file::mime_type "../src/file.sh"
#   #Output
#   application/x-shellscript
#
# @arg $1 string relative or absolute path to file/direcotry.
#
# @exitcode 0  If successful.
# @exitcode 1  If file/directory does not exist.
# @exitcode 2 Function missing arguments.
# @exitcode 3 If file or mimetype command not found in system.
#
# @stdout mime type of file/directory.
file::mime_type() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
    declare mime_type
    if [[ -f "${1}" ]] || [[ -d "${1}" ]]; then
        if type -p mimetype &> /dev/null; then
            mime_type=$(mimetype --output-format %m "${1}")
        elif type -p file &> /dev/null; then
            mime_type=$(file --brief --mime-type "${1}")
        else
            return 3
        fi
    else
        return 1
    fi
    printf "%s" "${mime_type}"
}
