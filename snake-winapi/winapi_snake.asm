option casemap:none

; External functions
extern GetStdHandle:proc
extern WriteConsoleOutputW:proc
extern GetAsyncKeyState:proc
extern Sleep:proc
extern SetConsoleOutputCP:proc

; Constants
B_WIDTH equ 200 
B_HEIGHT equ 28

C_WHITE equ 0fh
C_BLACK equ 0

CELL_FOOD equ 2
CELL_SNAKE equ 1
CELL_EMPTY equ 0

CHAR_SNAKE equ 0023h        ; '#'
CHAR_FOOD equ 25CFh         ; '●'
CHAR_EMPTY equ 0020h        ; ' '
CHAR_WALL        equ 2551h  ; '║' 
CHAR_CEIL        equ 2550h  ; '═' 
CHAR_FLOOR       equ 2550h  ; '═' 
CHAR_TOP_RIGHT   equ 2557h  ; '╗'
CHAR_TOP_LEFT    equ 2554h  ; '╔'
CHAR_BOTTOM_RIGHT equ 255Dh ; '╝'
CHAR_BOTTOM_LEFT  equ 255Ah ; '╚'


KEY_PRESSED equ 8000h

DELAY_MS equ 100

INIT_LENGTH equ 10

CHAR_INFO_SIZE equ 4
B_INDEX_SIZE equ 8

STD_OUTPUT_HANDLE equ -11
CP_UTF8 equ 65001
VK_UP equ 26h
VK_DOWN equ 28h
VK_LEFT equ 25h
VK_RIGHT equ 27h

; Structures
COORD struct
    X dw ?
    Y dw ?
COORD ends

SMALL_RECT struct
    Left dw ?
    Top dw ?
    Right dw ?
    Bottom dw ?
SMALL_RECT ends

CHAR_INFO struct
    UnicodeChar dw ?
    Attributes dw ?
CHAR_INFO ends

.data
bufCoord COORD			<0, 0>
bufSize COORD			<B_WIDTH, B_HEIGHT>
writeRegion	SMALL_RECT	<0, 0, B_WIDTH - 1, B_HEIGHT - 1>
hConsole qword			0 

buffer CHAR_INFO		<CHAR_TOP_LEFT, C_WHITE>, B_WIDTH-2 dup(<CHAR_CEIL, C_WHITE>), <CHAR_TOP_RIGHT, C_WHITE>, B_HEIGHT-2 dup(<CHAR_WALL, C_WHITE>, B_WIDTH-2 dup(<CHAR_EMPTY, C_BLACK>), <CHAR_WALL, C_WHITE>), <CHAR_BOTTOM_LEFT, C_WHITE>, B_WIDTH-2 dup(<CHAR_FLOOR, C_WHITE>), <CHAR_BOTTOM_RIGHT, C_WHITE>

board db				B_WIDTH dup(CELL_SNAKE), B_HEIGHT-2 dup(CELL_SNAKE, B_WIDTH-2 dup(CELL_EMPTY), CELL_SNAKE), B_WIDTH dup(CELL_SNAKE)
snake dq				B_WIDTH*B_HEIGHT dup(0)
seed dq					12345678

.code
public main
main:
mov r14, 1										; int8_t dirx = 1
mov r15, 0										; int8_t diry = 0
mov rbx, (B_WIDTH*8) + 10						; uint64_t board_head = starting position
mov rsi, 0										; uint64_t snake_idx_head = 0
mov rdi, 0										; uint64_t snake_idx_tail = 0

mov r12, 0										; uint8_t helper1 = 0;
mov r13, 0										; uint64_t helper2 = 0;

mov rcx, STD_OUTPUT_HANDLE						; hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
call GetStdHandle
mov hConsole, rax

; Set console to UTF-8 mode
mov rcx, CP_UTF8
call SetConsoleOutputCP	

main_loop:
; write head to memory and console
	lea rax, buffer
	mov word ptr [rax + rbx*CHAR_INFO_SIZE], CHAR_SNAKE		; buffer[board_head].Char.UnicodeChar = CHAR_SNAKE;
	mov word ptr [rax + rbx*CHAR_INFO_SIZE + 2], C_WHITE		; buffer[board_head].Attributes = C_WHITE;
	lea rax, board
	mov [rax + rbx], byte ptr CELL_SNAKE		; board[board_head] = CELL_SNAKE;
	lea rax, snake
	mov [rax + (rsi * B_INDEX_SIZE)], rbx		; snake[snake_idx_head++] = board_head;
	
	;snake_idx_head = (snake_idx_head + 1) % (B_WIDTH * B_HEIGHT);
	inc rsi
	mov rcx, B_WIDTH*B_HEIGHT
	mov rax, rsi
	div rcx
	mov rsi, rdx		

; move to next head
	; board_head += dirx + (diry * B_WIDTH);
	add rbx, r14                    ; board_head += dirx
	mov rax, r15                    ; rax = diry
	mov rcx, B_WIDTH
	imul rax, rcx                   ; rax = diry * B_WIDTH
	add rbx, rax                    ; board_head += diry * B_WIDTH


; save cell type
	lea rax, board
	mov r12b, byte ptr [rax + rbx]		; cell_type = board[board_head];
	cmp r12b, CELL_SNAKE						; if (cell_type == CELL_SNAKE)
	je main_end									; return -1;

	cmp r12b, CELL_FOOD							;	if (cell_type == CELL_FOOD) 
	je skip_tail_clear							;	do not clear tail


	; rax = length = 
	;	(snake_idx_head - snake_idx_tail + (B_WIDTH * B_HEIGHT)) %
	;	(B_WIDTH * B_HEIGHT);

	mov rax, rsi			; snake_idx_head - snake_idx_tail					
	sub rax, rdi								
	
	add rax, B_WIDTH*B_HEIGHT			; + size
	xor rdx, rdx
	mov rcx, B_WIDTH*B_HEIGHT ; divisor
	div rcx						
	mov rax, rdx				; % size
	
	cmp rax, INIT_LENGTH						; if (length <= INIT_LENGTH)
	jbe skip_tail_clear							; do not clear tail

	; clear tail
	lea rax, snake
	mov r13, [rax + (rdi * B_INDEX_SIZE)]			;tail_pos = snake[snake_idx_tail];
		; snake_idx_tail = (snake_idx_tail + 1) % (B_WIDTH * B_HEIGHT);
	inc rdi
	mov rcx, B_WIDTH*B_HEIGHT
	mov rax, rdi
	div rcx
	mov rdi, rdx
	
	lea rax, buffer
	mov word ptr [rax + r13*CHAR_INFO_SIZE], CHAR_EMPTY		; buffer[tail_pos].Char.UnicodeChar = CHAR_EMPTY;
	mov word ptr [rax + r13*CHAR_INFO_SIZE + 2], C_BLACK		; buffer[tail_pos].Attributes = C_BLACK;
	lea rax, board
	mov [rax + r13], byte ptr CELL_EMPTY						; board[tail_pos] = CELL_EMPTY;

skip_tail_clear:
	; draw console		
	sub rsp, 40									; shadow + alignment
												; WriteConsoleOutputW(
	mov rcx, hConsole							;	hConsole,
	lea rdx, buffer								;	buffer,					
	mov r8d, bufSize							;	bufSize,
	mov r9d, bufCoord							;	bufCoord,
	lea rax, writeRegion
    mov [rsp + 32], rax							;	&writeRegion);
	call WriteConsoleOutputW					; Unicode version
	
	call set_dir_from_keys

	push rdx
	push rcx
	push r8
	call calc_food_pos ; food pos in rax
	pop r8
	pop rcx
	pop rdx

    ; store food cell
	lea rcx, board
    mov byte ptr [rcx + rax], CELL_FOOD
	lea rcx, buffer
    mov word ptr [rcx + rax*CHAR_INFO_SIZE], CHAR_FOOD
    mov word ptr [rcx + rax*CHAR_INFO_SIZE + 2], C_WHITE

	; sleep	
	mov rcx, DELAY_MS							; Sleep(DELAY_MS);
	call Sleep

	jmp main_loop

main_end:
ret

;
; checks if arrow pressed, if so, update direction
; regs in use: rax, rcx
; output in: dirx - r14, diry -r15
; assume B_WIDTH is power of two (so W_SHIFT = log2(B_WIDTH))
;
set_dir_from_keys:
	sub rsp, 40									; align stack + shadow space
	
	; read keys
	mov rcx, VK_UP
	call GetAsyncKeyState
	test ax, KEY_PRESSED						
	jnz key_up						 
				
	mov rcx, VK_DOWN
	call GetAsyncKeyState
	test ax, KEY_PRESSED					
	jnz key_down						 
		
	mov rcx, VK_LEFT
	call GetAsyncKeyState
	test ax, KEY_PRESSED					
	jnz key_left						 
		
	mov rcx, VK_RIGHT
	call GetAsyncKeyState
	test ax, KEY_PRESSED		 
	jnz key_right					 
		
	jmp done_keys 

key_up:
    mov r14, 0									; dirx = 0
    mov r15, -1									; diry = -1
    jmp done_keys

key_down:
    mov r14, 0				
    mov r15, 1				
    jmp done_keys

key_left:
    mov r14, -1
    mov r15, 0
    jmp done_keys

key_right:
    mov r14, 1
    mov r15, 0
    jmp done_keys

done_keys:
	add rsp, 40									; restore stack
	ret

;
; calcs to rax a random place on board. this idx has to be: 
;  
; -  idx % B_WIDTH != 0				(left wall)
; -  idx % B_WIDTH != B_WIDTH -1		(right wall)
; -  idx > B_WIDTH						(floor)
; -  idx < B_WIDTH * (B_HEIGHT-1)		(ceiling)
;
; and should be random for all other cases
; regs in use: rax, rdx, rcx, r8
; assume B_WIDTH is power of two (so W_SHIFT = log2(B_WIDTH))
;
calc_food_pos:
    ; --- Generate random number ---
    mov rax, [seed]           ; load seed
    mov rcx, 6364136223846793005
    mul rcx                    ; rax * rcx -> rdx:rax
    add rax, 1                 ; add increment
    mov [seed], rax            ; store new seed
    ; rax now holds random number

    ; --- Constrain to valid range (exclude top/bottom row) ---
    mov r8, B_WIDTH*(B_HEIGHT-2)  ; valid rows count * width
    xor rdx, rdx
    div r8                      ; rax / r8, remainder in rdx
    mov rax, rdx                ; rax = random number in range 0..(B_WIDTH*(B_HEIGHT-2)-1)

    add rax, B_WIDTH            ; shift down one row to skip top row

    ; --- Constrain to exclude left/right columns ---
		; Calculate column = rax % B_WIDTH
	mov rcx, rax
	xor rdx, rdx
	push rax                        ; save rax
	mov rax, rcx
	mov rcx, B_WIDTH
	div rcx                         ; rdx = rax % B_WIDTH
	mov rcx, rdx                    ; rcx = column index
	pop rax                         ; restore rax

    ; If column is leftmost (0), shift right by 1
    cmp rcx, 0
    jne skip_left
    inc rax
    mov rcx, 1
skip_left:

    ; If column is rightmost (B_WIDTH-1), shift left by 1
    cmp rcx, B_WIDTH-1
    jne skip_right
    dec rax
skip_right:

    ret

end
