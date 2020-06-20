%define xOffset 0
%define yOffset 2
%define speedOffset 4
%define angleOffset 6
%define scoreOffset 8
%define isAliveOffset 12
%define DRONE_SIZE 16

section .rodata
    droneFormat: db 'id: %d\tX: %f\tY: %f\tSpeed: %f\tAngle: %f\tScore: %d',10,0
    targetFormat: db 'x: %f, y: %f',10,0
    _hexaFormat: db '%x',10,0
    _deciFormat: db '%d',10,0
    _calcPrompt: db "calc: ", 0
    _format_string: db "%s", 10, 0	; format string
    _format_string2: db "%s",' '	; format string

section .bss
    tempAdrs: resd 1
    
section .data
    index: dd 0

section .text
    global printGame
    extern getDrone
    extern getTargetX
    extern getTargetY
    extern getN
    extern convertToFloatInRange
    extern printf

    

;not good, just prints int value of regs
;void printDrone(int droneId)
%macro printDrone 1
    mov eax, %1
    push eax
    call getDrone   ;eax should hold pointer to drone
    mov dword[tempAdrs],eax
    ;;push id
    mov eax, [tempAdrs]
    add eax, scoreOffset
    mov ebx, 0
    mov bx, [eax]
    push ebx
    push 0
    push 100
    call convertToFloatInRange
    push eax
    ;;push x coordinate float
    mov eax, [tempAdrs]
    add eax, xOffset
    mov ebx, 0
    mov bx, [eax]
    push ebx
    push 0
    push 100
    call convertToFloatInRange
    push eax
    ;;push y coordinate float
    mov eax, [tempAdrs]
    add eax, yOffset
    mov ebx, 0
    mov bx, [eax]
    push ebx
    push 0
    push 100
    call convertToFloatInRange
    push eax
    ;;push speed float
    mov eax, [tempAdrs]
    add eax, speedOffset
    mov ebx, 0
    mov bx, [eax]
    push ebx
    push 0
    push 100
    call convertToFloatInRange
    push eax
    ;;push angle float
    mov eax, [tempAdrs]
    add eax, angleOffset
    mov ebx, 0
    mov bx, [eax]
    push ebx
    push 0
    push 360
    call convertToFloatInRange
    push eax
    ;;push score int
    mov eax, [tempAdrs + scoreOffset]
    push eax

    push droneFormat
    call printf
%endmacro

%macro printTarget 0
    getTargetY
    push eax
    push 100
    push 0
    call convertToFloatInRange
    push eax

    getTargetX
    push eax
    push 100
    push 0
    call convertToFloatInRange
    push eax

    push targetFormat
    call printf
%endmacro

printGame:
    ;print target x,y -> stats of all drones -> suspend own process -> repeat
    printTarget
    mov dword[index],0
    dronePrintForLoop:
        ;while index < N
        getN
        cmp dword[index],eax
        jge, endDronePrintForLoop
        ;print drones[i]
        mov eax, [index]
        printDrone eax
        inc dword[index]
        jmp dronePrintForLoop
    endDronePrintForLoop:
        ret



