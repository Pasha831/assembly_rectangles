CODE_SEG	SEGMENT
    ASSUME	CS:CODE_SEG,DS:CODE_SEG,SS:CODE_SEG
    ORG	100H
    .386

    START:
    jmp begin

    CR EQU 0Dh
    LF EQU 0Ah
    seed dw 5
    color dw 0
    x1 dw ?
    x2 dw ?
    y1 dw ?
    y2 dw ?
    symbol dw ?  ; 8 bits of back + 8 bits front
    rowLength dw ?
    columnLength dw ?
    amount dw 0
    count dw 0

    push_all_regs macro
        push	AX
        push	BX
        push	CX
        push	DX
    endm

    pop_all_regs macro
        pop		DX
        pop		CX
        pop		BX
        pop		AX
    endm

    print_letter	macro	letter
        push	AX
        push	DX
        mov	DL, letter
        mov	AH,	02
        int	21h
        pop		DX
        pop		AX
    endm

    print_mes	macro	message
        local	msg, nxt
        push	AX
        push	DX
        mov		DX,	offset msg
        mov		AH,	09h
        int	21h
        pop		DX
        pop		AX
        jmp nxt
    msg	DB message,'$'
    nxt:
 	endm

    println macro
        print_letter CR
        print_letter LF
    endm

    Print_Word_dec	macro	src
        local	l1, l2, ex
        
        push_all_regs

            mov		AX,	src					;	Выводимое число в регисте EAX
            push		-1					;	Сохраним признак конца числа
            mov		cx,	10					;	Делим на 10
        l1:	
            xor		dx,	dx					;	Очистим регистр dx 
            div		cx						;	Делим 
            push		DX						;	Сохраним цифру
            or 			AX,	AX				;	Остался 0? (это оптимальнее, чем  cmp	ax,	0 )
            jne		l1						;	нет -> продолжим
            mov		ah,	2h
        l2:	
            pop		DX						;	Восстановим цифру
            cmp		dx,	-1					;	Дошли до конца -> выход {оптимальнее: or EDX,dx jl ex}
            je			ex
            add		dl,	'0'					;	Преобразуем число в цифру
            int		21h						;	Выведем цифру на экран
            jmp	l2							;	И продолжим
        ex:	
        pop_all_regs
        
    endm

    rand8	proc near
        push cx
        mov	AX,		word ptr	seed
        mov	CX,		8	

        newbit:	mov	BX,		AX
                and	BX,		002Dh
                xor	BH,	BL
                clc
                jpe	shift
                stc
        shift:	rcr	AX,	1
            loop	newbit
            mov	word	ptr	seed,	AX
            mov	AH,	0
        pop cx
        ret
    rand8 endp

    clear_dots macro x1, x2, y1, y2
        mov x1, 0
        mov x2, 0
        mov y1, 0
        mov y2, 0
    endm

    set_number macro point, divisor
        push_all_regs
        call rand8
        mov bl, divisor
        div bl
        mov al, ah
        cbw
        mov point, ax
        pop_all_regs
    endm

    sort_points macro p1, p2
        local pass1
        push_all_regs
        mov ax, p1
        mov bx, p2
        cmp ax, bx
        jle pass1
        mov p1, bx
        mov p2, ax
        pass1:
        pop_all_regs
    endm

    begin:
        ;;; adjust registers to print on screen and clean it
            push 0B800h
            pop es
            xor di, di
            xor ax, ax
            mov cx, 25*80
            repe STOSW
        ;;;
    
        mov amount, 256

        do:
        xor cx, cx
        Print_Word_dec amount
        
        mov ah, 1
        int 21h

        dec amount

        ;;; set a random color (not black!)
            call rand8  ; to skip leading 0 of "random" numbers

            set_number symbol, 14 ; 0 - 14, ...
            inc symbol
            inc symbol  ; ... and then add 1, not to be black

            shl symbol, 11
        ;;;

        ;;; assign x1, x2, y1, y2
            clear_dots x1, x2, y1, y2

            set_number x1, 25
            set_number x2, 25
            set_number y1, 80
            set_number y2, 80
        ;;;

        ;;; sort x1 and x2, y1 and y2; find number of rows and columns to print
            push_all_regs

            sort_points x1, x2
            sort_points y1, y2

            mov ax, y2
            sub ax, y1
            mov columnLength, ax

            mov ax, x2
            sub ax, x1
            mov rowLength, ax

            pop_all_regs
        ;;;

        ;;; print the rectangle on the screen
            mov dx, symbol
            mov di, 80*2

            mov cx, x1
            setx1:
                add di, 160
            loop setx1

            mov bx, y1
            shl bx, 1
            add di, bx

            xor cx, cx
            mov cx, rowLength  ; 5 -> 5 - 0 (x2 - x1)
            cmp cx, 0
            je exit
            continue:
            cmp cx, 0
            je exit
            cycle1:
                push cx

                mov cx, columnLength  ; 1 -> 1 - 0 (y2 - y1)
                cmp cx, 0
                je continue
                cycle2:
                    mov es:di, dx
                    inc di
                    inc di
                loop cycle2

                sub di, columnLength
                sub di, columnLength
                add di, 80*2

                pop cx
            loop cycle1
            exit:
        
        cmp amount, 0
        jne do
    int 20h

CODE_SEG ENDS
    end START