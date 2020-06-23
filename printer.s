%define xOffset 0
%define yOffset 4
%define speedOffset 8
%define angleOffset 12
%define scoreOffset 16
%define isAliveOffset 20
%define DRONE_SIZE 24
%define BOARD_SIZE 626

%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2

;assumes index = currDroneId
%macro printDrone 0
    mov eax, [index]
    push dword[index]                ;push id for getDrone
    call getDrone                   ;eax should hold pointer to drone
    add esp, 4
    mov dword[tempAdrs],eax         ;eax hold pointer to drone
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
    mov dword[temp], eax    ;temp = degrees
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
    add eax, yOffset        ;eax = adrs of drones[i].x
    FLD dword[eax]
    sub esp, 8
    FSTP qword[esp]

    ;;push x coordinate float
    FINIT
    mov eax, [tempAdrs]
    add eax, xOffset        ;eax = adrs of drones[i].x
    FLD dword[eax]
    sub esp, 8
    FSTP qword[esp]

    ;;push id
    mov eax, [index]
    add eax, 1
    push eax
    ;;push format
    push droneFormat
    call printf
    add esp, 48
%endmacro

%macro printThreeLines 0
    push newLineFormat
    call printf
    call printf
    call printf
    add esp, 4
%endmacro

%macro printTarget 0
    call getTargetY
    mov  dword[temp],eax
    FLD  dword[temp]
    sub  esp, 8
    FSTP qword[esp]

    call getTargetX
    mov  dword[temp],eax
    FLD  dword[temp]
    sub  esp, 8
    FSTP qword[esp]

    push targetFormat
    call printf
    add  esp, 20
%endmacro

%macro printGameBoard 0
    pushad
    ;allocate memory for board
    push BOARD_SIZE ;25^2+1
    push 1
    call calloc
    add esp, 8
    mov dword[gameBoard], eax

    ;;add target to board
    %%placeTarget:
        FINIT
        call getTargetX     ;eax = (float)target.x
        mov dword[x],eax    ;x = (float)target.x
        FLD dword[x]        ;ST0 =(float)target.x
        mov dword[temp], 4  ;temp =4
        FIDIV dword[temp]   ;ST0 = (float)target.x / 4
        FISTP dword[x]      ;x = (int)target.x / 4
        call getTargetY
        mov dword[y],eax
        FLD dword[y]
        mov dword[temp], 4
        FIDIV dword[temp]
        FISTP dword[y]      ;y = (int)target.y /4

        mov eax, [y]            ;eax = y
        mov ebx, 25     
        mul ebx                 ;eax = 25*y
        add eax, [x]            ;eax = 25*y + x
        add eax, [gameBoard]    ;eax = gameboard[25*y+x] adrs
        mov dword[eax], 0xFF    ;gameBoard[25*y+x] = 0xFF

    ;;add drones to board
    mov dword[index],0
    %%placeDronesLoop:
        call getN
        cmp dword[index], eax
        jge %%endPlaceDronesLoop

        push dword[index]
        call getDrone
        add esp, 4
        mov dword[tempAdrs], eax

        FINIT
        mov eax, [tempAdrs]
        add eax, xOffset
        mov eax, [eax]
        mov dword[x],eax    ;x = (float)target.x
        FLD dword[x]        ;ST0 =(float)target.x
        mov dword[temp], 4  ;temp =4
        FIDIV dword[temp]   ;ST0 = (float)target.x / 4
        FISTP dword[x]      ;x = (int)target.x / 4
        mov eax, [tempAdrs]
        add eax, yOffset
        mov eax, [eax]
        mov dword[y],eax    ;x = (float)target.x
        FLD dword[y]        ;ST0 =(float)target.x
        mov dword[temp], 4  ;temp =4
        FIDIV dword[temp]   ;ST0 = (float)target.x / 4
        FISTP dword[y]      ;x = (int)target.x / 4

        mov eax, [y]            ;eax = y
        mov ebx, 25     
        mul ebx                 ;eax = 25*y
        add eax, [x]            ;eax = 25*y + x
        add eax, [gameBoard]    ;eax = gameboard[25*y+x] adrs
        mov ebx, [index]
        add ebx, 1
        mov dword[eax], ebx     ;gameBoard[25*y+x] = drone id


        inc dword[index]
        jmp %%placeDronesLoop
    %%endPlaceDronesLoop:

    mov dword[index],0
    %%printLoop:
        ;;New Line if needed
        mov ebx, 25         ;ebx =25
        mov edx, 0          ;edx = 
        mov eax, [index]    ;eax = i
        div ebx             ;ea-x = i/25, edx i%25
        cmp edx,0
        je %%newLine
        jmp %%noNewLine
            %%newLine:
                push newLineFormat
                call printf
                add  esp, 4
            %%noNewLine:

        cmp dword[index],BOARD_SIZE
        jge %%endPrintLoop
        mov eax, [index]
        add eax, [gameBoard]    ;eax = gameBoard + index
        mov ebx,0
        mov bl, [eax]           ;ebx = value at gameBoard[index]
        mov ecx, pawnFormat
        cmp ebx, 0              ;if 0 then reformat to space
        je %%reformatNull
        cmp ebx, 0xFF
        je %%reformatTarget
        jmp %%formattingComplete
        %%reformatNull:
            mov ebx, '.'
            mov ecx, CharFormat
            jmp %%formattingComplete
        %%reformatTarget:
            mov ebx, '$'
            mov ecx, CharFormat
            jmp %%formattingComplete
        %%formattingComplete:
            push ebx
            push ecx
            call printf
            add esp, 8

        inc dword[index]
        jmp %%printLoop
    %%endPrintLoop:
        push dword[gameBoard]
        call free
        add  esp, 4
        popad
%endmacro

section .rodata
    droneFormat:        db "id: %2X  X: %7.2f  Y: %7.2f  Speed: %7.3f  Angle: %7.2f  Score: %4d  Status: %s", 10, 0
    ActiveFormat:       db 'ACTIVE',0
    notActiveFormat:    db 'LOST',0
    targetFormat:       db 'Target x: %.2f, Target y: %.2f',10,0
    pawnFormat:         db " %X ",0
    CharFormat:         db " %c ",0
    newLineFormat:      db "",10,0

section .bss
    tempAdrs:   resd 1
    temp:       resd 1
    gameBoard:  resd 1
    
section .data
    index: dd 0
    x:     dd 0
    y:     dd 0

section .text
    global runPrinter
    extern free
    extern calloc
    extern printf
    extern getDrone
    extern getTargetX
    extern getTargetY
    extern getN
    extern convertToFloatInRange
    extern getCo
    extern resume

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
        ;printGameBoard
        printThreeLines
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

