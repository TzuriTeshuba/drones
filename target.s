%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2
%define COR_SIZE 8

section .rodata

section .bss
    targetX: resw 1
    targetY: resw 1

section .data   

section .text
    global runTarget
    global getTargetX
    global getTargetY
    global generateTarget
    extern getRandomNumber
    extern cors
    extern getCo

runTarget:
    call generateTarget
    push COR_TARGET
    call getCo
    add esp, 4
    mov ebx, eax
    call resume
    jmp runTarget;;this line not from slides, but i feel like it should

generateTarget:
    getRandomNumber
    mov word[targetX],ax
    getRandomNumber
    mov word[targetY],ax
    ret

getTargetX:
    mov eax,0
    mov ax, [targetX]
    ret

getTargetY:
    mov eax,0
    mov ax, [targetY]
    ret