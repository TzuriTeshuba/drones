section .rodata

section .bss
    random: resw 1

section .data


section .text
    global getRandomNumber


;11th, 13th, 14th, 16th bits xor'ed
getRandomNumber:
    mov eax, 0 ;eax = i =0
    
    whileLoop:
        ;;check condition - IMPLEMENT
        cmp eax, 16
        jge endOfWhileLoop
    ;11th bit
        shr word[random], 1 ;shift random by 1 bit
        mov ebx,0
        mov bx, 0x400 ;bx = 0000010000000000
        and bx, [random] ;bx = 0 or 0x800
        div bx, 0x400 ;bx = 0 or 1
    ;13th bit
        mov ecx, 0
        mov cx, 0x1000 ;cx = 0001000000000000
        and cx, [random]
        div cx, 0x1000
        xor bx, cx
    ;14th bit
        mov ecx, 0
        mov cx, 0x2000 ;cx = 0010000000000000
        and cx, [random]
        div cx, 0x2000
        xor bx, cx
    ;16th bit
        mov ecx, 0
        mov cx, 0x8000 ;cx = 1000000000000000
        and cx, [random]
        div cx, 0x8000
        xor bx, cx

        mul bx, 0x8000 ;result is in msb of bx
        or word[random],bx ;random has MSB replaced with result
        inc eax         ;i++
        jmp whileLoop

    endOfWhileLoop:
        




