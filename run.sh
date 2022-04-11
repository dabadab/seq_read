#!/bin/bash
NAME="seq_read"
ASM="$NAME.asm"
PRG="$NAME.prg"
SEQ="hello.seq"
IMG="seqtest.d64"

# compile program
64tass -Wall --cbm-prg -o $PRG -a $ASM || exit 1

# create "hello world!" SEQ file
echo -e -n '\x08\x05\x0c\x0c\x0f\x20\x17\x0f\x12\x0c\x04\x21' > $SEQ

# create disk image with PRG and SEQ file
c1541 -format seqtest,st d64 $IMG -write $PRG $NAME -write $SEQ hello,s -dir

# run VICE
x64 +cart $IMG
#x64 +cart -moncommands break.txt $IMG
