%define droneSize 24
%define xOffset 0
%define yOffset 4
%define speedOffset 8
%define angleOffset 12
%define scoreOffset 16
%define isAliveOffset 20

%define PI 3.14159265359
%define COR_SCHED 0
%define COR_PRINTER 1
%define COR_TARGET 2


;;should be good
;;moves drones fields to local variables
%macro initFieldValues 0
    ;;get floats values of drone fields
    mov eax, [currDrone]

    mov ebx, [eax+xOffset]   ;ebx hols x position
    mov dword[xPos], ebx

    mov ebx, [eax+yOffset]   ;ebx hols y position
    mov dword[yPos], ebx

    mov ebx, [eax+speedOffset]   ;ebx hols speed
    mov dword[speed], ebx

    mov ebx, [eax+angleOffset]   ;ebx holds angle
    mov dword[angle], ebx
%endmacro

;;should be good
;;moves drone and calculates new fields
%macro moveDrone 0
    initFieldValues
    ;;calc x,y, newSpeed, newAngle
    ;;X
    FINIT
    FLD dword[angle]    ;ST(0) = angle
    FCOS                ;ST(0) = cos(ST0) = cos(angle)
    FMUL dword[speed]   ;ST(0) = speed*cos(angle)
    FADD dword[xPos]    ;ST(0) = x + speed*cos(angle)
    mov dword[temp],0
    FICOM dword[temp]
    jl %%xIsNegative
    mov dword[temp],100
    FICOM dword[temp]
    jg %%xTooLarge
    jmp %%setX
        %%xIsNegative:
            mov dword[temp], 100
            FIADD dword[temp]
            jmp %%setX
        %%xTooLarge:
            mov dword[temp], 100
            FISUB dword[temp]
            jmp %%setX
        %%setX:
            FST dword[xPos]     ;[xPos] = ST(0)

    ;;Y
    FINIT
    FLD dword[angle]    ;ST(0) = angle
    FSIN                ;ST(0) = cos(angle)
    FMUL dword[speed]   ;ST(0) = speed*cos(angle)
    FADD dword[yPos]    ;ST(0) = x + speed*cos(angle)
    mov dword[temp],0
    FICOM dword[temp]
    jl %%yIsNegative
    mov dword[temp],100
    FICOM dword[temp]
    jg %%yTooLarge
    jmp %%setY
        %%yIsNegative:
            mov dword[temp], 100
            FADD dword[temp]
            jmp %%setY
        %%yTooLarge:
            mov dword[temp], 100
            FSUB dword[temp]
            jmp %%setY
        %%setY:
            FST dword[yPos]     ;[xPos] = ST(0)

    ;;newSpeed
    FINIT
    call getRandomNumber
    push eax
    push 10
    push -10
    call convertToFloatInRange
    add esp, 12
    mov dword[temp], eax    ;[temp] = FP in [-10,10] range
    FLD dword[temp]         
    FLD dword[speed]        ;;ST(0) = currSpeed, ST(1) = temp = deltaSpeed
    FADDP 
    mov dword[temp],100
    FICOM dword[temp]              ;flag should be result of comparison (ST(0),100)
    jg %%speedTooLarge
    mov dword[temp],0
    FICOM dword[temp]              ;flag should be result of comparison (ST(0),100)
    jl %%speedIsNegative
    jmp %%setSpeed
        %%speedIsNegative:
            FLDZ
            jmp %%setSpeed
        %%speedTooLarge:
            FILD dword[temp]
        %%setSpeed:
            FST dword[speed]

    ;;newAngle
    FINIT
    call getRandomNumber
    push eax
    push 60
    push -60
    call convertToFloatInRange
    add esp, 12
    push eax
    call convertToRadians
    add esp, 4
    mov dword[temp], eax    ;[temp] = FP in [-pi/3,pi/3] range
    FLD dword[temp]         
    FLD dword[angle]        ;;ST(0) = currAngle, ST(1) = temp = deltaAngle
    FADDP
    mov dword[temp],0
    FICOM dword[temp]              ;flag should be result of comparison (ST(0),100)
    jl %%angleIsNegative
    FCOM dword[twoPi]
    jg %%angleTooLarge
    jmp %%setAngle
        %%angleIsNegative:
            FADD dword[twoPi]
            jmp %%setAngle   
        %%angleTooLarge:
            FSUB dword[twoPi]       ;ST(0) = ST(0) - 2*pi
            jmp %%setAngle
        %%setAngle:
            FST dword[angle]

    storeFieldValues
            
    
    ;;update position
%endmacro

;should be good
;moves local variables (x,y,speed, angle) into drone array
%macro storeFieldValues 0
    mov eax, [currDrone]

    mov ebx, xOffset
    add ebx, eax
    mov ecx, [xPos]
    mov dword[ebx], ecx

    mov ebx, yOffset
    add ebx, eax
    mov ecx, [yPos]
    mov dword[ebx], ecx

    mov ebx, speedOffset
    add ebx, eax
    mov ecx, [speed]
    mov dword[ebx], ecx

    mov ebx, angleOffset
    add ebx, eax
    mov ecx, [angle]
    mov dword[ebx], ecx

%endmacro


section .rodata
    twoPi: dd 6.28318530718
section .bss

section .data
    currDrone:  dd 0
    currId:     dd 0
    xPos:       dd 0
    yPos:       dd 0
    speed:      dd 0
    angle:      dd 0
    tx:         dd 0
    ty:         dd 0
    temp:       dd 0

section .text
    global runDrone
    extern resumeCor
    extern getD
    extern getTargetX
    extern getTargetY
    extern getCurrDroneId
    extern getDrone
    extern getRandomNumber
    extern convertToFloatInRange
    extern convertToRadians
    extern getCo
    extern resume
    extern startCo



runDrone:
    call getCurrDroneId
    mov dword[currId], eax
    push eax
    call getDrone
    mov dword[currDrone], eax
    add esp, 4
    moveDrone
    call mayDestroy
    ;;resume scheduler
    push COR_SCHED
    call getCo
    add esp, 4
    mov ebx, eax
    call resume
    jmp runDrone

mayDestroy:
    call getTargetX
    mov dword[tx],eax
    call getTargetY
    mov dword[ty],eax

    FINIT
    FLD dword[tx]
    FSUB dword[xPos]
    FLD ST0
    FMUL ST0, ST1
    FST dword[temp]

    FINIT
    FLD dword[ty]
    FSUB dword[yPos]
    FLD ST0
    FMUL ST0, ST1

    FLD dword[temp]
    FADD ST0,ST1

    FSQRT       ;ST(0) = sqrt( (xt-xd)^2 + (yt-yd)^2 )
    call getD
    mov dword[temp], eax
    FCOM dword[temp]    ;comp ST(0) with d

    jle destroyTarget
    jmp notInRange
        destroyTarget:
            mov eax, [currDrone]
            add eax, scoreOffset
            inc dword[eax]
            ;;need to resume target
            push COR_TARGET
            call getCo
            add esp, 4
            mov ebx, eax
            call resume

        notInRange:
            push COR_SCHED
            call getCo
            add esp, 4
            mov ebx, eax
            call resume
    ret






    

