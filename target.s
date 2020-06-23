%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2
%define COR_SIZE 8

section .rodata

section .bss

section .data   
    targetX:    dd 0
    targetY:    dd 0
    temp:       dd 0

section .text
    global runTarget
    global getTargetX
    global getTargetY
    global generateTarget
    extern getRandomNumber
    extern getCurrDroneId
    extern convertToFloatInRange
    extern resume
    extern getCo

runTarget:
    call generateTarget
    call getCurrDroneId
    add eax, 3
    push eax
    call getCo
    add esp, 4
    mov ebx, eax
    call resume
    jmp runTarget;;this line not from slides, but i feel like it should

generateTarget:
    call getRandomNumber
    push eax
    push 100
    push 0
    call convertToFloatInRange
    add esp,12
    mov dword[targetX],eax

    call getRandomNumber
    push eax
    push 100
    push 0
    call convertToFloatInRange
    add esp,12
    mov dword[targetY],eax
    ret

getTargetX:
    mov eax, [targetX]
    ret

getTargetY:
    mov eax, [targetY]
    ret