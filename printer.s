section .rodata
    droneFormat: db 'id: %d\tX: %d\tY: %d\tSpeed: %d\tAngle: %d\tScore: %d',10,0
    targetFormat: db 'x: %d, y: %d',10,0
    _hexaFormat: db '%x',10,0
    _deciFormat: db '%d',10,0
    _calcPrompt: db "calc: ", 0
    _format_string: db "%s", 10, 0	; format string
    _format_string2: db "%s",' '	; format string

section .bss
    
section .data
    index: dd 0

section .text
    global printGame
    extern getDrone
    extern getTargetX
    extern getTargetY
    extern getN
    extern printf

    

;not good, just prints int value of regs
%macro printDrone 1
    mov eax, %1
    push eax
    call getDrone   ;eax should hold pointer to drone
    push dword[eax] ;push id
    mov ebx, 0
    mov bx, [eax+12]
    push ebx        ;push x coordinate 
    mov bx, [eax+10] 
    push ebx        ;push y coordinate
    mov bx, [eax+8] 
    push ebx        ;push speed
    mov bx, [eax+6]
    push ebx        ;push angle
    mov bx, [eax+4]
    push ebx        ;push scores
    push droneFormat
    call printf
%endmacro

%macro printTarget 0
    getTargetX
    mov ebx, eax
    getTargetY
    push eax
    push ebx
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
        ;;
        ;;suspend process
        ;;
        jmp printGame



