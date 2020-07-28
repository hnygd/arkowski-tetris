;Frame parametres
frameHeight equ 8 * 20
frameWidth equ 8 * 10
frameBorderWidth equ 5
frameBeginningX equ 50
frameBeginningY equ 10

nextPieceFrameHeight equ 8 * 5
nextPieceFrameWidth equ 8 * 5
nextPieceFrameBorderWidth equ 5
nextPieceFrameBeginningX equ 155
nextPieceFrameBeginningY equ 10

boardColor equ 0
pieceSize equ 8

scorePosX equ 160
scorePosY equ 100

gameOverPosX equ 120
gameOverPosY equ 80

; waitFactor*usleepMS should be approx 1sec
; If usleepMS is too long, we will miss keyboard input
; If it is too short, keypresses will be counted several times
waitFactor equ 10
usleepMS equ 100000

section .data
      gameOver: db "GAME OVER",0
      scoreString: db "SCORE",0




section .bss
    	boardState: resb 20 * 10

    	nextPieceType: resb 1
    	pieceType: resb 1
    	pieceCol: resb 1
    	piecePos: resb 4
    	piecePivotPos: resb 1

      temporaryPiecePos: resb 4

    	waitTime: resb 1

    	score: resw 1
    	scoreAsString: resb 6     ; 5 digits+0


extern gl_write,gl_setfont,gl_font8x8,gl_setfontcolors,gl_setwritemode,vga_init,vga_setmode,vga_setcolor,gl_fillbox,gl_setcontextvga,vga_getkey,usleep,rand
extern exit,keyboard_init,keyboard_translatekeys,keyboard_update,keyboard_keypressed,keyboard_close

section .text

global main
main:
        ;Initialization
        sub rsp,8
        call vga_init

        mov rdi, 5              ; SVGALIB 5 = 320x200x256 (see vga.h)
        call vga_setmode
        mov rdi, 5              ; we need to init vgagl with the same mode
        call gl_setcontextvga
        mov rdi,8
        mov rsi,8
        mov rdx, [gl_font8x8]
        call gl_setfont         ; see man gl_write(3)
        mov rdi,2
        call gl_setwritemode
        mov rdi, 0
        mov rsi, 15
        call gl_setfontcolors
        call keyboard_init
        mov rdi, 7

        call drawFrame
        call drawNextPieceFrame
        jmp gameInProgres

endOfGame:
        call delayForLongWhile
        call displayGameOver
        call delayForLongWhile

        ;Return to previous video mode
        call keyboard_close
        mov rdi, 0
        call vga_setmode

        ;Finish program
        ; we can not simply call return because we might be called from within
        ; gameInProgress
        mov rdi, 0
        call exit

;/////DRAWING FUNCTIONS////
;////////////////////////////////////////////////////////////
;Draw Rectangle, rax - begin point, rcx - Height, rbx - Width, rdi - color
drawRect:
    xor rdx, rdx                ; clear dx for ax division
    push rdi                    ; Save colour
    push rcx                    ; Save height for later
    mov rcx, 320                ; divisor in cx

    div cx                      ; divide begin point/320 so we get y in ax and x in dx (remainder)

    mov rdi, rdx                ; x1 (param 1)
    mov rsi, rax                ; y1 (param 2)
    mov rdx, rbx                ; width (param 3)
    pop rcx                     ; height (param 4, fetch again from stack)
    pop r8                      ; Pass colour
    call gl_fillbox
    mov rdi, r8                 ; ...and restore colour
	ret

;////////////////////////////////////////////////////////////
drawFrame:
	mov rdi, 7                    ; colour

	;Gora
	mov rax, frameBeginningY * 320 + frameBeginningX
  mov rcx, frameBorderWidth
  mov rbx, frameWidth + 2 * frameBorderWidth
  call drawRect

	;Lewa
	mov rax, (frameBeginningY + frameBorderWidth) * 320 + frameBeginningX
	mov rcx, frameHeight
	mov rbx, frameBorderWidth
	call drawRect

	;Prawa
	mov rax, (frameBeginningY + frameBorderWidth) * 320 + frameBeginningX + frameWidth + frameBorderWidth
	mov rcx, frameHeight
	mov rbx, frameBorderWidth
	call drawRect

	;Dol
	mov rax, (frameBeginningY + frameHeight + frameBorderWidth) * 320 + frameBeginningX
  mov rcx, frameBorderWidth
  mov rbx, frameWidth + 2 * frameBorderWidth
  call drawRect

  ret

;////////////////////////////////////////////////////////////
drawNextPieceFrame:
	mov rdi, 7

	;Gora
	mov rax, nextPieceFrameBeginningY * 320 + nextPieceFrameBeginningX
  mov rcx, nextPieceFrameBorderWidth
  mov rbx, nextPieceFrameWidth + 2 * nextPieceFrameBorderWidth
  call drawRect

	;Lewa
	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth) * 320 + nextPieceFrameBeginningX
	mov rcx, nextPieceFrameHeight
	mov rbx, nextPieceFrameBorderWidth
	call drawRect

	;Prawa
	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth) * 320 + nextPieceFrameBeginningX + nextPieceFrameWidth + nextPieceFrameBorderWidth
	mov rcx, nextPieceFrameHeight
	mov rbx, nextPieceFrameBorderWidth
	call drawRect

	;Dol
	mov rax, (nextPieceFrameBeginningY + nextPieceFrameHeight + nextPieceFrameBorderWidth) * 320 + nextPieceFrameBeginningX
  mov rcx, nextPieceFrameBorderWidth
  mov rbx, nextPieceFrameWidth + 2 * nextPieceFrameBorderWidth
  call drawRect

    ret

;////////////////////////////////////////////////////////////
drawBoardState:
    mov rbx, 200

drawBoardStateLoop1:
        dec rbx
        push rbx

        movzx rdi, byte[boardState + rbx]
        mov rax, rbx

        call drawOneSquare

        pop rbx
        cmp rbx, 0
    jne drawBoardStateLoop1

    ret

;////////////////////////////////////////////////////////////
clearBoard:
  mov rax, (frameBeginningY + frameBorderWidth) * 320 + frameBeginningX + frameBorderWidth
	mov rcx, frameHeight
	mov rbx, frameWidth
	mov rdi, boardColor
	call drawRect

	ret

;////////////////////////////////////////////////////////////
drawTetromino:
    movzx rax, byte[piecePos]
    movzx rdi, byte[pieceCol]
    call drawOneSquare

    movzx rax, byte[piecePos + 1]
    movzx rdi, byte[pieceCol]
    call drawOneSquare

    movzx rax, byte[piecePos + 2]
    movzx rdi, byte[pieceCol]
    call drawOneSquare

    movzx rax, byte[piecePos + 3]
    movzx rdi, byte[pieceCol]
    call drawOneSquare

    ret

;////////////////////////////////////////////////////////////
;rax - PieceNumber, rdi - color
drawOneSquare:

    mov BL, 10
    div BL

    ;AH - X, AL - Y
    mov CX, AX

    ;Calculate Y offset
    mov AL, CL
    xor AH, AH
    mov BX, 320 * pieceSize
    mul BX

    push rax
    ;Calculate X offset
    mov AL, CH
    xor AH, AH
    mov BX, pieceSize
    mul BX

    pop rdx

    ;Move to fit frame
    add AX, DX
    add AX, (frameBeginningY + frameBorderWidth) * 320 + frameBeginningX + frameBorderWidth

    mov BX, pieceSize
    mov CX, pieceSize

    jmp drawRect

;/////GAME FUNCTIONS////
;////////////////////////////////////////////////////////////
gameInProgres: ;-TO DO
    mov byte[waitTime], waitFactor
    call generateNextPieceNumber
placeNext:
    call updateBoard

    call generateNextPiece
    call generateNextPieceNumber
    call setNewDelay
    call writeScore

    jmp checkIfNotEnd

pieceInProgress:
        call clearBoard
        call drawBoardState
        call drawTetromino

        call scoreToString

        call getPlayerInput
        cmp AX, 0x0F0F

        ;AX = FFFF - Place Next Piece
        cmp AX, 0xFFFF
        je placeNext

        call moveOneDown
        cmp AX, 0xFFFF
        je placeNext

    jmp pieceInProgress

;---------
checkIfNotEnd:
    movzx rbx, byte[piecePos]
    mov AL, [boardState + rbx]
    cmp AL, boardColor
    jne endOfGame

    movzx rbx, byte[piecePos + 1]
    movzx rax, byte[boardState + rbx]
    cmp AL, boardColor
    jne endOfGame

    movzx rbx, byte[piecePos + 2]
    movzx rax, byte[boardState + rbx]
    cmp AL, boardColor
    jne endOfGame

    movzx rbx, byte[piecePos + 3]
    movzx rax, byte[boardState + rbx]
    cmp AL, boardColor
    jne endOfGame

    jmp pieceInProgress

;////////////////////////////////////////////////////////////
getPlayerInput:
    movzx rcx, byte[waitTime]
waitForKey:
        dec CX
        cmp CX, 0
        je noInput
; We need to run this in a loop with frequent polling.
; If we just check every second or so if a keyboard has been pressed,
; we miss out on key events with keyboard_update from svgalib

        push rcx                ; we need to save the loop counter across the svgalib calls
  ; the various push/pops are not super-elegant, yes, I know...
        call delayForWhile
        ; we need to ensure that we don't call this too frequently
        ; otherwise the same keypress is returned again
        call keyboard_update
        pop rcx

        mov rdi, 75             ;SCANCODE_CURSORLEFT
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne moveOneLeft

        mov rdi, 97             ;SCANCODE_CURSORBLOCKLEFT
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne moveOneLeft

        mov rdi, 80             ;SCANCODE_CURSORSDOWN
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne downKey

        mov rdi, 100            ;SCANCODE_CURSORBLOCKDOWN
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne downKey

        mov rdi, 77             ;SCANCODE_CURSORRIGHT
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne moveOneRight

        mov rdi, 98             ;SCANCODE_CURSORBLOCKRIGHT
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne moveOneRight

        mov rdi, 72             ;SCANCODE_CURSORUP
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne rotateCounterClockwise

        mov rdi, 95             ;SCANCODE_CURSORBLOCKUP
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne rotateCounterClockwise

        mov rdi, 76             ;SCANCODE_KEYPAD5
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne rotateClockwise

        mov rdi, 1              ;SCANCODE_ESCAPE
        push rcx
        call keyboard_keypressed
        pop rcx
        cmp rax, 0
        jne endOfGame

        jmp waitForKey

noInput:
    xor rax, rax
    ret

downKey:
    inc word[score]
    call moveOneDown
    xor rax, rax
ret

;////////////////////////////////////////////////////////////
generateNextPieceNumber:
    mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth
    mov rcx, nextPieceFrameHeight
    mov rbx, nextPieceFrameWidth
    mov rdi, boardColor
    call drawRect

    ; Random for next piece
    call rand
    xor DX, DX
	  mov CX, 7
	  div CX
	  mov byte[nextPieceType], DL

    mov AH, DL                  ; DOS Code expects next piece type in AH...


genFirstPiece:	;I
    cmp AH, 0
  	jne genSecondPiece

	  mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + 4
    mov rcx, pieceSize
    mov rbx, 4 * pieceSize
    mov rdi, 52
    call drawRect

	ret
genSecondPiece:	;J
	cmp AH, 1
	jne genThirdPiece

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, 3 * pieceSize
    mov rdi, 32
    call drawRect

    mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + 3 * pieceSize
    mov rcx, pieceSize
    mov rbx, pieceSize
    mov rdi, 32
    call drawRect

	ret
genThirdPiece:	;L
    cmp AH, 2
	  jne genForthPiece

  	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, 3 * pieceSize
    mov rdi, 43
    call drawRect

    mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, pieceSize
    mov rdi, 43
    call drawRect

	ret
genForthPiece:	;O
	cmp AH, 3
	jne genFifthPiece

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize + 4
    mov rcx, 2 * pieceSize
    mov rbx, 2 * pieceSize
    mov rdi, 45
    call drawRect

	ret
genFifthPiece:	;S
	cmp AH, 4
	jne genSixthPiece

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + 2 * pieceSize
    mov rcx, pieceSize
    mov rbx, 2 * pieceSize
    mov rdi, 48
    call drawRect

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, 2 * pieceSize
    mov rdi, 48
    call drawRect

	ret
genSixthPiece:	;T
	cmp AH, 5
	jne genSeventhPiece

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, 3 * pieceSize
    mov rdi, 34
    call drawRect

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + 2 * pieceSize
    mov rcx, pieceSize
    mov rbx, pieceSize
    mov rdi, 34
    call drawRect

	ret
genSeventhPiece: ;Z

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + pieceSize
    mov rcx, pieceSize
    mov rbx, 2 * pieceSize
    mov rdi, 40
    call drawRect

	mov rax, (nextPieceFrameBeginningY + nextPieceFrameBorderWidth + 2 * pieceSize + 4) * 320 + nextPieceFrameBeginningX + nextPieceFrameBorderWidth + 2 * pieceSize
    mov rcx, pieceSize
    mov rbx, 2 * pieceSize
    mov rdi, 40
    call drawRect

	ret
;---------------------
generateNextPiece:
	mov AH, byte[nextPieceType]
	mov byte[pieceType], AH
	mov byte[piecePivotPos], 3


firstPiece:	;I
	cmp AH, 0
	jne secondPiece

	mov byte[piecePos], 13
	mov byte[piecePos + 1], 14
	mov byte[piecePos + 2], 15
	mov byte[piecePos + 3], 16
	mov byte[pieceCol], 52

	ret
secondPiece:	;J
	cmp AH, 1
	jne thirdPiece

	mov byte[piecePos], 13
	mov byte[piecePos + 1], 14
	mov byte[piecePos + 2], 15
	mov byte[piecePos + 3], 25
	mov byte[pieceCol], 32

	ret
thirdPiece:	;L
    cmp AH, 2
	jne forthPiece

	mov byte[piecePos], 13
	mov byte[piecePos + 1], 14
	mov byte[piecePos + 2], 15
	mov byte[piecePos + 3], 23
	mov byte[pieceCol], 43

	ret
forthPiece:	;O
	cmp AH, 3
	jne fifthPiece

	mov byte[piecePos], 14
	mov byte[piecePos + 1], 15
	mov byte[piecePos + 2], 24
	mov byte[piecePos + 3], 25
	mov byte[pieceCol], 45

	ret
fifthPiece:	;S
	cmp AH, 4
	jne sixthPiece

	mov byte[piecePos], 14
	mov byte[piecePos + 1], 15
	mov byte[piecePos + 2], 23
	mov byte[piecePos + 3], 24
	mov byte[pieceCol], 48

	ret
sixthPiece:	;T
	cmp AH, 5
	jne seventhPiece

	mov byte[piecePos], 13
	mov byte[piecePos + 1], 14
	mov byte[piecePos + 2], 15
	mov byte[piecePos + 3], 24
	mov byte[pieceCol], 34

	ret
seventhPiece:	;Z
	mov byte[piecePos], 13
	mov byte[piecePos + 1], 14
	mov byte[piecePos + 2], 24
	mov byte[piecePos + 3], 25
	mov byte[pieceCol], 40

	ret
;///////////////////////////////////////////////////////////
solidifyPiece:
    movzx rbx, byte[piecePos]
    mov AL, byte[pieceCol]
    mov byte[boardState + rbx], AL

    movzx rbx, byte[piecePos + 1]
    mov byte[boardState + rbx], AL

    movzx rbx, byte[piecePos + 2]
    mov byte[boardState + rbx], AL

    movzx rbx, byte[piecePos + 3]
    mov byte[boardState + rbx], AL

    ret
;///////////////// - TO DO
updateBoard:
    mov DL, 20
updateBoardLoop:
        dec DL
        call clearOneRow
        cmp DL, 0
    jne updateBoardLoop

    ret
clearOneRow:
;DL - row To clear
    mov BL, 10
    mov AL, DL
    mul BL

    xor rbx, rbx
    mov BX, AX

    mov CX, 10
clearOneRowLoop1:
        cmp byte[boardState + rbx], boardColor
        je notclearOneRow
        inc BX

    loop clearOneRowLoop1

    add word[score], 100

    cmp DL, 0
    je notclearOneRow

    push rdx
clearOneRowLoop2:
        dec DL
        call moveRowDown
        cmp DL, 1
        jne clearOneRowLoop2

    pop rdx
    jmp clearOneRow
notclearOneRow:
    ret

moveRowDown:
;DL - beginRow
    mov BL, 10
    mov AL, DL
    mul BL

    xor rbx, rbx
    mov BX, AX

    mov CX, 10
moveRowDownLoop:
        mov AL, byte[boardState + rbx]
        mov byte[boardState + rbx + 10], AL
        mov byte[boardState + rbx], boardColor

        inc BX
    loop moveRowDownLoop

    ret
;///////////////// - TO DO
moveOneDown:
    xor rax, rax
    mov rbx, 10
    xor DL, DL

    ;Check Frame Collision
    cmp byte[piecePos], 19 * 10
    jae cantMoveOneDown
    cmp byte[piecePos + 1], 19 * 10
    jae cantMoveOneDown
    cmp byte[piecePos + 2], 19 * 10
    jae cantMoveOneDown
    cmp byte[piecePos + 3], 19 * 10
    jae cantMoveOneDown

    ;Check Space Collsion
    xor rbx, rbx
    mov BL, byte[piecePos]
    add BL, 10
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneDown
    mov BL, byte[piecePos + 1]
    add BL, 10
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneDown
    mov BL, byte[piecePos + 2]
    add BL, 10
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneDown
    mov BL, byte[piecePos + 3]
    add BL, 10
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneDown

    add byte[piecePos], 10
    add byte[piecePos + 1], 10
    add byte[piecePos + 2], 10
    add byte[piecePos + 3], 10

    add byte[piecePivotPos], 10

    xor rax, rax
    ret
cantMoveOneDown:
    call solidifyPiece
    mov rax, 0xFFFF
    ret
;-----------------------------------
moveOneLeft:
    mov BL, 10

    ;Check Frame Collision
    xor AX, AX
    mov AL, byte[piecePos]
    div BL
    cmp AH, 0
    je cantMoveOneLeft
    xor AX, AX
    mov AL, byte[piecePos + 1]
    div BL
    cmp AH, 0
    je cantMoveOneLeft
    xor AX, AX
    mov AL, byte[piecePos + 2]
    div BL
    cmp AH, 0
    je cantMoveOneLeft
    xor AX, AX
    mov AL, byte[piecePos + 3]
    div BL
    cmp AH, 0
    je cantMoveOneLeft

    ;Check Space Collsion
    xor rbx, rbx
    mov BL, byte[piecePos]
    dec BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneLeft
    mov BL, byte[piecePos + 1]
    dec BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneLeft
    mov BL, byte[piecePos + 2]
    dec BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneLeft
    mov BL, byte[piecePos + 3]
    dec BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneLeft

    dec byte[piecePos]
    dec byte[piecePos + 1]
    dec byte[piecePos + 2]
    dec byte[piecePos + 3]

    dec byte[piecePivotPos]

cantMoveOneLeft:
    xor AX, AX
    ret
;-----------------------------------
moveOneRight:
    mov BL, 10

    ;Check Frame Collision
    xor AX, AX
    mov AL, byte[piecePos]
    div BL
    cmp AH, 9
    je cantMoveOneRight
    xor AX, AX
    mov AL, byte[piecePos + 1]
    div BL
    cmp AH, 9
    je cantMoveOneRight
    xor AX, AX
    mov AL, byte[piecePos + 2]
    div BL
    cmp AH, 9
    je cantMoveOneRight
    xor AX, AX
    mov AL, byte[piecePos + 3]
    div BL
    cmp AH, 9
    je cantMoveOneRight

    ;Check Space Collsion
    xor rbx, rbx
    mov BL, byte[piecePos]
    inc BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneRight
    mov BL, byte[piecePos + 1]
    inc BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneRight
    mov BL, byte[piecePos + 2]
    inc BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneRight
    mov BL, byte[piecePos + 3]
    inc BL
    cmp byte[boardState + rbx], boardColor
    jne cantMoveOneRight

    inc byte[piecePos]
    inc byte[piecePos + 1]
    inc byte[piecePos + 2]
    inc byte[piecePos + 3]

    inc byte[piecePivotPos]

cantMoveOneRight:
    ret

rotateClockwise:
    ;CheckBoard
    mov rbx, 4

rotateClockwiseLoop1:
        dec BX
        push rbx

        xor AX, AX
        mov BL, 10
        mov AL, byte[piecePivotPos]
        div BL

        pop rbx
        cmp AH, 0
        jb cantRotateClockwise
        cmp AH, 6
        ja cantRotateClockwise
        cmp AL, 16
        ja cantRotateClockwise

        mov CX, AX
        xor AX, AX

        mov AL, byte[piecePos + rbx]
        push rbx

        mov BL, 10
        sub AL, byte[piecePivotPos]
        div BL
        mov DX, AX

        ;AH - X, AL - Y
        mov AH, DL
        cmp byte[pieceType], 0
        je rotateClockwiseSpc
        mov AL, 3
rotateClockwiseSpcBack:
        sub AL, DH
        mov DX, AX

        mov AL, DL
        mov BL, 10
        mul BL
        add AL, DH

        pop rbx
        add AL, byte[piecePivotPos]
        mov byte[temporaryPiecePos + rbx], AL

        cmp BX, 0
    jne rotateClockwiseLoop1

    xor rbx, rbx
    mov BL, byte[temporaryPiecePos]
    cmp byte[boardState + rbx], boardColor
    jne cantRotateClockwise
    mov BL, byte[temporaryPiecePos + 1]
    cmp byte[boardState + rbx], boardColor
    jne cantRotateClockwise
    mov BL, byte[temporaryPiecePos + 2]
    cmp byte[boardState + rbx], boardColor
    jne cantRotateClockwise
    mov BL, byte[temporaryPiecePos + 3]
    cmp byte[boardState + rbx], boardColor
    jne cantRotateClockwise

    mov AL, byte[temporaryPiecePos]
    mov byte[piecePos], AL
    mov AL, byte[temporaryPiecePos + 1]
    mov byte[piecePos + 1], AL
    mov AL, byte[temporaryPiecePos + 2]
    mov byte[piecePos + 2], AL
    mov AL, byte[temporaryPiecePos + 3]
    mov byte[piecePos + 3], AL

cantRotateClockwise:
    xor AX, AX
    ret

rotateClockwiseSpc:
    mov AL, 4
    jmp rotateClockwiseSpcBack
;/////////////////
rotateCounterClockwise:
    ;CheckBoard
    mov rbx, 4

rotateCounterClockwiseLoop1:
        dec BX
        push rbx

        xor AX, AX
        mov BL, 10
        mov AL, byte[piecePivotPos]
        div BL

        pop rbx
        cmp AH, 0
        jb cantRotateCounterClockwise
        cmp AH, 6
        ja cantRotateCounterClockwise
        cmp AL, 16
        ja cantRotateCounterClockwise

        mov CX, AX
        xor AX, AX

        mov AL, byte[piecePos + rbx]
        push rbx

        mov BL, 10
        sub AL, byte[piecePivotPos]
        div BL
        mov DX, AX

        ;AH - X, AL - Y
        mov AL, DH
        cmp byte[pieceType], 0
        je rotateCounterClockwiseSpc
        mov AH, 3
rotateCounterClockwiseSpcBack:
        sub AH, DL
        mov DX, AX

        mov AL, DL
        mov BL, 10
        mul BL
        add AL, DH

        pop rbx
        add AL, byte[piecePivotPos]
        mov byte[temporaryPiecePos + rbx], AL

        cmp BX, 0
    jne rotateCounterClockwiseLoop1

    ;xor BX, BX
    movzx r8, byte[temporaryPiecePos]
    cmp byte[boardState + r8], boardColor
    jne cantRotateCounterClockwise
    movzx r8, byte[temporaryPiecePos + 1]
    cmp byte[boardState + r8], boardColor
    jne cantRotateCounterClockwise
    movzx r8, byte[temporaryPiecePos + 2]
    cmp byte[boardState + r8], boardColor
    jne cantRotateCounterClockwise
    movzx r8, byte[temporaryPiecePos + 3]
    cmp byte[boardState + r8], boardColor
    jne cantRotateCounterClockwise

    mov AL, byte[temporaryPiecePos]
    mov byte[piecePos], AL
    mov AL, byte[temporaryPiecePos + 1]
    mov byte[piecePos + 1], AL
    mov AL, byte[temporaryPiecePos + 2]
    mov byte[piecePos + 2], AL
    mov AL, byte[temporaryPiecePos + 3]
    mov byte[piecePos + 3], AL

cantRotateCounterClockwise:
    xor AX, AX
    ret

rotateCounterClockwiseSpc:
    mov AH, 4
    jmp rotateCounterClockwiseSpcBack
;/////////////////
;Delay for one/10 second (loop in input is 10 times)
delayForWhile:
    mov rdi, usleepMS
    call usleep

    ret
;--------------------
delayForLongWhile:
    mov rdi, 0x000F8480
    call usleep

    ret
;/////////////////
setNewDelay:
    cmp byte[waitTime], 1
    jb noSetNewDelat

    mov AX, word[score]

    xor DX, DX
    mov BX, 1000
    div BX

    mov DX, AX
    mov AX, 10

    cmp AX, DX
    jl set1Delay
    sub AX, DX

    mov byte[waitTime], AL
noSetNewDelat:
    ret

set1Delay:
    mov byte[waitTime], 1
    ret
;/////////////////
scoreToString:
    xor DX, DX
    mov AX, word[score]
    mov BX, 10000
    div BX
    add AX, 48
    mov byte[scoreAsString], AL

    mov AX, DX
    xor DX, DX
    mov BX, 1000
    div BX
    add AX, 48
    mov byte[scoreAsString + 1], AL

    mov AX, DX
    xor DX, DX
    mov BX, 100
    div BX
    add AX, 48
    mov byte[scoreAsString + 2], AL

    mov AX, DX
    xor DX, DX
    mov BX, 10
    div BX
    add AX, 48
    mov byte[scoreAsString + 3], AL
    add DX, 48
    mov byte[scoreAsString + 4], DL
    mov byte[scoreAsString + 5], 0 ; 0 for C string end

    mov BX, 5
    mov DL, 24

    mov rdi, scorePosX
    mov rsi, scorePosY-15
    mov rdx, scoreString
    call gl_write

    mov rdi, scorePosX                 ; x of position
    mov rsi, scorePosY                 ; y of position
    mov rdx, scoreAsString      ; position of string (=1 character)
    call gl_write

  ret
;////////////////////////
writeScore:

    mov rdi, scorePosX
    mov rsi, scorePosY-15
    mov rdx, scoreString
    call gl_write

    mov rdi, scorePosX                 ; x of position
    mov rsi, scorePosY                 ; y of position
    mov rdx, scoreAsString      ; position of string (=1 character)
    call gl_write

    ret

;----------------
displayGameOver:
	xor rax, rax
	mov rcx, 200
	mov rbx, 320
	mov rdi, boardColor
	call drawRect

    mov rdi, gameOverPosX                 ; x of position
    mov rsi, gameOverPosY                 ; y of position
    mov rdx, gameOver           ; position of string (=1 character)
    call gl_write

ret


