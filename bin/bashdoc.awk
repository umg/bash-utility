#!/usr/bin/awk -f

BEGIN {
    styles["h1", "from"] = ".*"
    styles["h1", "to"] = "# &"

    styles["h2", "from"] = ".*"
    styles["h2", "to"] = "## &"

    styles["h3", "from"] = ".*"
    styles["h3", "to"] = "### &"

    styles["h4", "from"] = ".*"
    styles["h4", "to"] = "#### &"

    styles["code", "from"] = ".*"
    styles["code", "to"] = "```&"

    styles["/code", "to"] = "```"

    styles["argN", "from"] = "^(\\$[0-9]) (\\S+)"
    styles["argN", "to"] = "**\\1** (\\2):"

    styles["arg@", "from"] = "^\\$@ (\\S+)"
    styles["arg@", "to"] = "**...** (\\1):"

    styles["li", "from"] = ".*"
    styles["li", "to"] = "- &"

    styles["i", "from"] = ".*"
    styles["i", "to"] = "*&*"

    styles["anchor", "from"] = ".*"
    styles["anchor", "to"] = "[&](#&)"

    styles["exitcode", "from"] = "([>!]?[0-9]{1,3}) (.*)"
    styles["exitcode", "to"] = "**\\1**: \\2"
}

function render(type, text) {
    return gensub( \
        styles[type, "from"],
        styles[type, "to"],
        "g",
        text \
    )
}

function reset() {
    has_example = 0
    has_args = 0
    has_exitcode = 0
    has_stdout = 0
}

/^[[:space:]]*# @internal/ {
    is_internal = 1
}

/^[[:space:]]*# @file/ {
    sub(/^[[:space:]]*# @file /, "")
    filedoc = render("h2", $0) "\n"
}

/^[[:space:]]*# @brief/ {
    sub(/^[[:space:]]*# @brief /, "")
    filedoc = filedoc "\n" $0
}

/^[[:space:]]*# @description/ {
    in_description = 1
    in_example = 0

    reset()

    docblock = ""
}

in_description {
    if (/^[^[[:space:]]*#]|^[[:space:]]*# @[^d]|^[[:space:]]*[^#]/) {
        if (!match(docblock, /\n$/)) {
            docblock = docblock "\n"
        }
        in_description = 0
    } else {
        sub(/^[[:space:]]*# @description /, "")
        sub(/^[[:space:]]*# /, "")
        sub(/^[[:space:]]*#$/, "")

        docblock = docblock "\n" $0
    }
}

in_example {
    if (! /^[[:space:]]*#[ ]{3}/) {
        in_example = 0

        docblock = docblock "\n" render("/code") "\n"
    } else {
        sub(/^[[:space:]]*#[ ]{3}/, "")

        docblock = docblock "\n" $0
    }
}

/^[[:space:]]*# @example/ {
    in_example = 1

    docblock = docblock "\n" render("h4", "Example")
    docblock = docblock "\n\n" render("code", "bash")
}

/^[[:space:]]*# @arg/ {
    if (!has_args) {
        has_args = 1

        docblock = docblock "\n" render("h4", "Arguments") "\n\n"
    }

    sub(/^[[:space:]]*# @arg /, "")

    $0 = render("argN", $0)
    $0 = render("arg@", $0)

    docblock = docblock render("li", $0) "\n"
}

/^[[:space:]]*# @noargs/ {
    docblock = docblock "\n" render("i", "Function has no arguments.") "\n"
}

/^[[:space:]]*# @exitcode/ {
    if (!has_exitcode) {
        has_exitcode = 1

        docblock = docblock "\n" render("h4", "Exit codes") "\n\n"
    }

    sub(/^[[:space:]]*# @exitcode /, "")

    $0 = render("exitcode", $0)

    docblock = docblock render("li", $0) "\n"
}

/^[[:space:]]*# @see/ {
    sub(/[[:space:]]*# @see /, "")

    $0 = render("anchor", $0)
    $0 = render("li", $0)

    docblock = docblock "\n" render("h4", "See also") "\n\n" $0 "\n"
}

/^[[:space:]]*# @stdout/ {
    has_stdout = 1

    sub(/^[[:space:]]*# @stdout /, "")

    docblock = docblock "\n" render("h4", "Output on stdout")
    docblock = docblock "\n\n" render("li", $0) "\n"
}

/^[ \t]*(function([ \t])+)?([a-zA-Z0-9_:-]+)([ \t]*)(\(([ \t]*)\))?[ \t]*\{/ && docblock != "" && !in_example {
    if (is_internal) {
        is_internal = 0
    } else {
        func_name = gensub(\
            /^[ \t]*(function([ \t])+)?([a-zA-Z0-9_:-]+)[ \t]*\(.*/, \
            "\\3()", \
            "g" \
        )
        doc = doc "\n" render("h3", func_name) "\n" docblock

        # url = func_name
        # # https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/toc_filter.rb#L44-L45
        # url = tolower(url)
        # gsub(/[^[:alnum:] -]/, "", url)
        # gsub(/ /, "-", url)

        # toc = toc "\n" "- [" func_name "](#" url ")"
    }

    docblock = ""
    reset()
}

END {
    if (filedoc != "") {
        print filedoc
    }
    #print toc
   # print ""
    print doc
}
