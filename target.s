%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2
%define COR_SIZE 8

%macro printTarget 0
    call getTargetY
    mov dword[temp],eax
    FLD dword[temp]
    sub esp, 8
    FSTP qword[esp]

    call getTargetX
    mov dword[temp],eax
    FLD dword[temp]
    sub esp, 8
    FSTP qword[esp]

    push targetFormat
    call printf
    add esp, 20
%endmacro

section .rodata
    targetFormat: db 'x: %.4f, y: %.4f',10,0

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
    extern resume
    extern cors
    extern getCo
    extern getCurrDroneId
    extern convertToFloatInRange
    extern greet
    extern printf

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
    printTarget
    ret

getTargetX:
    mov eax, [targetX]
    ret

getTargetY:
    mov eax, [targetY]
    ret