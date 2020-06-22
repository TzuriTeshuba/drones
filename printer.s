%define xOffset 0
%define yOffset 4
%define speedOffset 8
%define angleOffset 12
%define scoreOffset 16
%define isAliveOffset 20
%define DRONE_SIZE 24

%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2

;void printDrone(int droneId)
%macro printDrone 0
    push dword[index]                ;push id for getDrone
    call getDrone           ;eax should hold pointer to drone
    add esp, 4
    mov dword[tempAdrs],eax ;eax hold pointer to drone
    add eax, isAliveOffset
    cmp dword[eax],0
    je %%statusNotActive
            push ActiveFormat
            jmp %%statusActiveOrNot
        %%statusNotActive:
            push notActiveFormat       
    %%statusActiveOrNot:
    FINIT

    ;;push score int
    mov eax, [tempAdrs]
    add eax, scoreOffset
    push dword[eax]

    ;;push angle float
    mov eax, [tempAdrs]
    add eax, angleOffset    ;eax = adrs of drones[i].angle
    push dword[eax]
    call convertRadiansToDegrees
    add esp, 4
    mov dword[temp], eax ;temp = degrees
    FLD dword[temp]
    sub esp, 8
    FSTP qword[esp]

    ;;push speed float
    FINIT
    mov eax, [tempAdrs]
    add eax, speedOffset    ;eax = adrs of drones[i].x
    FLD dword[eax]
    sub esp, 8
    FSTP qword[esp]

    ;;push y coordinate float
    FINIT
    mov eax, [tempAdrs]
    add eax, yOffset    ;eax = adrs of drones[i].x
    FLD dword[eax]
    sub esp, 8
    FSTP qword[esp]

    ;;push x coordinate float
    FINIT
    mov eax, [tempAdrs]
    add eax, xOffset    ;eax = adrs of drones[i].x
    FLD dword[eax]
    sub esp, 8
    FSTP qword[esp]

    ;;push id
    push dword[index]
    ;;push format
    push droneFormat
    call printf


    add esp, 48
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
    droneFormat:        db "id: %d  X: %.3f  Y: %.3f  Speed: %.3f  Angle: %.3f  Score: %d  Status: %s", 10, 0
    ActiveFormat:       db 'ACTIVE',0
    notActiveFormat:    db 'LOST',0
    targetFormat:       db 'target) x: %f, y: %f',10,0
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
    extern greet

convertRadiansToDegrees:
    mov eax, [esp + 4]      ;eax = radians
    FINIT
    mov dword[temp], eax
    FLD dword[temp]         ;ST0 = radians
    mov dword[temp], 180
    FIMUL dword[temp]       ;ST0 =  180*radians
    FLDPI                   ;ST0=pi, ST1 = 180*radians
    FDIVR ST0, ST1           ;ST0 = pi*degrees
    FST dword[temp]
    mov eax, [temp]
    ret

printGame:
    ;print target x,y -> stats of all drones -> suspend own process -> repeat
    printTarget
    mov dword[index],0
    dronePrintForLoop:
        ;while index < N
        call getN
        cmp dword[index],eax
        jge endDronePrintForLoop
        ;print drones[i]
        printDrone
        inc dword[index]
        jmp dronePrintForLoop
    endDronePrintForLoop:
        ret


runPrinter:
    ;print target x,y -> stats of all drones -> resume scheduler -> repeat
    call printGame
    ;;resume scheduler
    push COR_SCHED
    call getCo
    add esp, 4
    mov ebx, eax
    call resume
    jmp runPrinter





