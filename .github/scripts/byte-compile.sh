#!/bin/bash

# Copyright (c) 2022-2023 Gonzalo Larumbe
# All rights reserved.


clean() {
    echo "Removing .elc files"
    find . -name "*.elc" -exec rm -v {} \;
    echo ""
}


compile() {
    echo "Byte compiling..."
    emacs -Q -nw -batch \
          -L $PWD/tests \
          -l vhdl-ext-tests-setup \
          -l vhdl-ext-tests \
          --eval "(byte-recompile-directory \"$PWD\" 0)"
}

recompile() {
    clean
    compile
}

"$@"
