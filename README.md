# Lambda-to-C Transpiler

This project implements a source-to-source compiler (transpiler) that translates programs written in the fictional programming language **Lambda** into equivalent C99 code. It was developed as part of the course **Theory of Computation (PLH 402)** at the Technical University of Crete.

## Overview

The Lambda language includes features such as:
- Basic and compound types (`integer`, `scalar`, `str`, `bool`, `comp`)
- Control structures (`if`, `while`, `for`)
- User-defined functions and methods
- Array comprehensions
- Comments, macros, and string literals

The transpiler performs lexical and syntax analysis using **Flex** and **Bison**, then generates equivalent C code.

## How to Use

### Step 1: Convert `.la` to `.c`

From the root directory of the project, run the following command:

```bash
./compile.sh examples/useless.la
If there are no syntax errors, a new file useless.c will be generated.

The compile.sh script automatically rebuilds the mycompiler binary before each run.

Step 2: Compile .c to executable
Navigate to the examples/ directory and compile the C file:

gcc -o useless useless.c
./useless
Examples
You can find example Lambda programs inside the examples/ folder:

useless.la

example1.la

example2.la

These files serve as test cases to verify both the lexical and syntax correctness of the compiler.
Requirements
To run and build the project, you will need:

A Linux environment (or WSL on Windows)

flex
bison
gcc
make 
