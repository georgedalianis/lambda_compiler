#!/bin/bash
FNAME="$1"
NFNAME=${FNAME/.la/.c}
./build_compiler.sh
./mycompiler < "$1" > "$NFNAME"
echo "Compile step ended"
exit 0