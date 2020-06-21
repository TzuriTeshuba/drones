%define xOffset 0
%define yOffset 2
%define speedOffset 4
%define angleOffset 6
%define scoreOffset 8
%define isAliveOffset 12
%define DRONE_SIZE 16

%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2

;not good, just prints int value of regs
;void printDrone(int droneId)
%macro printDrone 1
    mov eax, %1
    ;;push id
    push eax
    call getDrone           ;eax should hold pointer to drone
    mov dword[tempAdrs],eax ;eax hold pointer to drone

    ;;push x coordinate float
    mov eax, [tempAdrs]
    add eax, xOffset    ;eax = adrs of drones[i].x
    push dword[eax]
    ;;push y coordinate float
    mov eax, [tempAdrs]
    add eax, yOffset
    push dword[eax]
    ;;push speed float
    mov eax, [tempAdrs]
    add eax, speedOffset
    push dword[eax]
    ;;push angle float
    mov eax, [tempAdrs]
    add eax, angleOffset
    push dword[eax]
    ;;push score int
    mov eax, [tempAdrs]
    add eax, scoreOffset
    push dword[eax]
    ;;push format
    push droneFormat
    call printf
    add esp, 28
%endmacro

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
    droneFormat:        db 'id: %d\tX: %f\tY: %f\tSpeed: %f\tAngle: %f\tScore: %d',10,0
    targetFormat:       db 'x: %f, y: %f',10,0
    _hexaFormat:        db '%x',10,0
    _deciFormat:        db '%d',10,0
    _calcPrompt:        db "calc: ", 0
    _format_string:     db "%s", 10, 0	; format string
    _format_string2:    db "%s",' '	; format string

section .bss
    tempAdrs:   resd 1
    temp:       resd 1
    
section .data
    index: dd 0

section .text
    global printGame
    global runPrinter
    extern getDrone
    extern getTargetX
    extern getTargetY
    extern getN
    extern convertToFloatInRange
    extern getCo
    extern resume
    extern printf

    
runPrinter:
    ;print target x,y -> stats of all drones -> suspend own process -> repeat
    printTarget
    mov dword[index],0
    dronePrintForLoop:
        ;while index < N
        call getN
        cmp dword[index],eax
        jge endDronePrintForLoop
        ;print drones[i]
        mov eax, [index]
        printDrone eax
        inc dword[index]
        jmp dronePrintForLoop
    endDronePrintForLoop:
        push COR_SCHED
        call getCo
        add esp, 4
        mov ebx, eax
        call resume



