	; constants
	LOGICAL = 1          ; logical filenumber (valid range: 1-255)
	LOAD_ADDRESS = $0400 ; where to load data

	; ***************
	; -1. BASIC stub
	; ***************

	; "10 sys 2062"
	* = $0801
	.byte $0c, $08, $0a, $00, $9e, $20, $32, $30, $36, $32, $00, $00, $00 ; sys 2062
	; the assembly code after this line will be at $080e (2062 in decimal)


	; ******************
	; 0. cosmetic stuff
	; ******************

	; clear screen
	jsr $ff81
	; set border and background white
	lda #$01
	sta $d020
	sta $d021

	; *****************
	; 1. OPEN THE FILE
	; *****************

	; set file parameters
	; A: logical filenumber
	; X: device number
	; Y: secondary address
	lda #LOGICAL  ; logical filenumber (valid range: 1-255)
        ldx #$18      ; device: 8
	ldy #$02      ; secondary address: 2 (valid range for serial bus devices: 2-14 (0 and 1 are reserved for load and save, 15 is command channel))
        jsr $ffba     ; call SETLFS

	; set filename
	; A: file name length
	; X/Y: pointer to file name
	lda #filename_end-filename ; file name length
        ldx #<filename  ; file name pointer low byte
        ldy #>filename  ; file name pointer high byte
        jsr $ffbd       ; call SETNAM

	; open file
	; no error: carry bit is 0
	; error happened: carry bit is 1 and A contains the error code
	jsr $ffc0 ; call OPEN
	bcs error ; jump to error if carry is 1

	; set our file as default input
	ldx #LOGICAL
	jsr $ffc6  ; call CHKIN

	; ***********
	; 2. READING
	; ***********

	; we will just put all the read bytes to the screen

	ldy #$00 ; this is the index relative to the beginning of the screen

read_loop:
	; check current device (set by CHKIN) status
	; no error: zero bit is 1, A is 0
	; error happened: zero bit is 0 and A contains the error code
	jsr $ffb7 ; call READST
	bne eof_or_error ; if zero bit is 0 quit reading

	; read a byte from default input (set by CHKIN)
	; result is stored in A
	jsr $ffcf ; call CHRIN

	; put byte to the screen and increase index by 1
	; the READST and CHRIN routines do not change Y so we don't have to save and restore it
	sta LOAD_ADDRESS,y
	iny

	; try to get next byte
	jmp read_loop


eof_or_error:
	; check if it's a real error or we are just at the end of the file
	; if it's an EOF bit 6 ($40) is set
	sta error_code_tmp ; save error code
	and #$40
	bne close ; bit 6 was set, just close the file

	lda error_code_tmp ; restore error code
	jmp error ; we have a real error, handle it


	; ****************
	; 3. CLOSING FILE
	; ****************
close:
	; close file
	; A: logical filenumber
	lda #LOGICAL  ; logical filenumber 2
	jsr $ffc3     ; call CLOSE

	; reset default input and output to keyboard and screen and reset serial bus
	jsr $ffcc     ; call CLRCHN

	jmp * ; infinite loop



	; ******************
	; +1. ERROR HANDLER
	; ******************
error:
	; "print" error code
	sta $0400

	; set border to red to indicate error
	lda #$02
	sta $d020

	jmp close ; try to close file anyway

error_code_tmp:
	.byte $00

filename:
	.text "hello"
filename_end:
