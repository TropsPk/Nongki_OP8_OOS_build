#!/usr/bin/env bash
# Shell author: JackA1ltman <cs2dtzq@163.com>
# 20250610

LOG_FILE="error.log"

print_separator() {
    echo "--------------------------------------------------------"
}

analyze_errors() {
    local log_file="$1"
    local error_found=false
    local error_count=0
    local current_error_lines=()
    local processing_error=false

    if [ ! -f "$log_file" ]; then
        echo "Error: Log file '$log_file' not found."
        exit 1
    fi

    echo "Analyzing log file: $log_file"
    print_separator

    while IFS= read -r line; do
        if [[ "$line" =~ " error:" || "$line" =~ " fatal error:" || "$line" =~ "undefined reference to" ]]; then
            processing_error=true
            error_found=true
            error_count=$((error_count + 1))

            current_error_lines=()
            current_error_lines+=("$line")
        elif [[ "$processing_error" == true && ( "$line" =~ "note:" || ( "$line" =~ "make\[[0-9]\]:" && "$line" =~ "***" ) ) ]]; then

            current_error_lines+=("$line")
        elif [[ "$processing_error" == true && -n "$line" ]]; then

            current_error_lines+=("$line")
        else

            if [[ "$processing_error" == true ]]; then
                process_error_block "$error_count" "${current_error_lines[@]}"
                processing_error=false
                current_error_lines=()
            fi
        fi
    done < "$log_file"

    if [[ "$processing_error" == true ]]; then
        process_error_block "$error_count" "${current_error_lines[@]}"
    fi

    print_separator
    if [ "$error_found" = true ]; then
        echo "Total found $error_count error(s). "
        echo "Please carefully review the error messages and suggestions above."
        touch have_error
    else
        echo "Not found any errors."
    fi
    print_separator
}

process_error_block() {
    local -a error_block=("${@:2}")
    local current_error_num="$1"

    echo "Error #$current_error_num:"
    for error_line in "${error_block[@]}"; do
        echo "  $error_line"
    done

    local error_type="Uncommon error"
    local suggestion="Review the compiler output and search for the exact error message."

    if grep -q "No such file or directory" <<< "${error_block[@]}"; then
        error_type="Missing header or source file"
        suggestion="Check that the file path is correct, or that a required dev library is missing (e.g. libssl-dev, zlib1g-dev)."
    elif grep -q "undefined reference to" <<< "${error_block[@]}"; then
        error_type="Link error: missing library or function"
        suggestion="Check for a missing linked library (e.g. -lssl, -lcrypto), whether the library path is in LDFLAGS/LDLIBS, or a misspelled function name."
    elif grep -q "unrecognized command line option" <<< "${error_block[@]}"; then
        error_type="Unsupported compiler option"
        suggestion="Your compiler version may be too old or too new. Check the Makefile's compiler flags for compatibility, and consider upgrading or downgrading the toolchain."
    elif grep -q "misleading-indentation" <<< "${error_block[@]}"; then
        error_type="Indentation doesn't match logic"
        suggestion="Likely a code-style/logic issue. Add braces '{}' after 'if'/'for'/'while' to make the block explicit, or disable this warning (not recommended)."
    elif grep -q "type specifier missing" <<< "${error_block[@]}"; then
        error_type="Missing C type declaration"
        suggestion="A variable or function declaration may be missing a type (e.g. 'int'). For kernel modules this is often a missing/out-of-order header or an API change across kernel versions."
    elif grep -q "make\[[0-9]\]:" <<< "${error_block[@]}" && grep -q "Error [0-9]" <<< "${error_block[@]}"; then
        error_type="Makefile build error"
        suggestion="A Makefile rule failed. Check the specific error above it — usually a sub-command (gcc, ld, sh) returned non-zero."
    elif grep -q "target emulation unknown" <<< "${error_block[@]}"; then
        error_type="Linker emulation mode error"
        suggestion="Your linker (ld) doesn't recognize the requested emulation mode. Check for a mixed LLVM/GNU toolchain, or make sure LD points at LLVM's lld."
    elif grep -q "cannot open" <<< "${error_block[@]}" && grep -q ".gz" <<< "${error_block[@]}"; then
        error_type="Missing file (config likely not generated)"
        suggestion="Check whether 'make defconfig' (or your device-specific config) has run. If 'make mrproper' ran before, you'll need to reconfigure."
    elif grep -q "makes pointer from integer without a cast" <<< "${error_block[@]}"; then
        error_type="Type mismatch (pointer vs integer)"
        suggestion="A serious type mismatch — usually a function's return type doesn't match what's expected (e.g. returns int but a pointer is expected). May need a source fix, or a more lenient compiler."
    elif grep -q "not found (required by clang) " <<< "${error_block[@]}"; then
        error_type="Clang version issue"
        suggestion="Your build OS version is too old — use 22.04 instead of 20.04, or the latest available."
    elif grep -q "multiple definition of 'yylloc'" <<< "${error_block[@]}"; then
        error_type="Kernel source defect"
        suggestion="Change 'YYLTYPE yylloc;' to 'extern YYLTYPE yylloc;' in scripts/dtc/dtc-lexer.lex.c_shipped."
    elif grep -q "assembler command failed with exit code 1" <<< "${error_block[@]}"; then
        error_type="Clang compiler error"
        suggestion="Try a different Clang version."
    elif grep -q "incompatible pointer types passing 'atomic_long_t *'" <<< "${error_block[@]}"; then
        error_type="Source pointer type error"
        suggestion="Usually caused by a manually-patched cred.h — replace atomic_inc_not_zero with atomic_long_inc_not_zero."
    elif grep -q "Error: junk at end of line, first unrecognized character is" <<< "${error_block[@]}"; then
        error_type="Clang version issue"
        suggestion="Try a lower Clang version (e.g. 20 -> 12 -> 10), or add -gdwarf-4 to KBUILD_CFLAGS in the Makefile to request an older DWARF version."
    elif grep -q "undefined symbol: __stack_chk_guard" <<< "${error_block[@]}"; then
        error_type="Clang version issue"
        suggestion="Try a lower Clang version (e.g. 20 -> 12 -> 10)."
    fi

    echo "Error: $error_type"
    echo "Suggestion: $suggestion"
    print_separator
}

if [ "$#" -gt 0 ]; then
    LOG_FILE="$1"
fi

analyze_errors "$LOG_FILE"
