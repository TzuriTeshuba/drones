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

%macro debugFloatConversion 0
    FLD dword[temp]
    sub esp, 8
    FSTP qword[esp]
    push debugRandomFormat
    call printf
    add esp, 12
%endmacro

%macro printHexTemp 0
    push dword[temp]
    push tempHexFormat
    call printf
    add esp, 8
%endmacro
%macro debugFields 0
    pushad

    mov eax, [xPos]
    mov dword[temp], eax
    debugFloatConversion

    mov eax, [yPos]
    mov dword[temp], eax
    debugFloatConversion

    mov eax, [speed]
    mov dword[temp], eax
    debugFloatConversion

    mov eax, [angle]
    mov dword[temp], eax
    debugFloatConversion

    popad
%endmacro
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

    ;debugFields
%endmacro

;;should be good
;;moves drone and calculates new fields
%macro moveDrone 0
    initFieldValues
    ;;calc x,y, newSpeed, newAngle
    ;;X
    FINIT
    FLD     dword[angle]    ;ST(0) = angle
    FCOS                    ;ST(0) = cos(ST0) = cos(angle)
    FMUL    dword[speed]    ;ST(0) = speed*cos(angle)
    FADD    dword[xPos]     ;ST(0) = x + speed*cos(angle)
    FLDZ
    FCOMIP
    ja %%xIsNegative
    mov     dword[temp],100
    FILD    dword[temp]
    FCOMIP  
    jb %%xTooLarge
    jmp %%setX
        %%xIsNegative:
            mov     dword[temp], 100
            FIADD   dword[temp]
            jmp %%setX
        %%xTooLarge:
            mov     dword[temp], 100
            FISUB   dword[temp]
            jmp %%setX
        %%setX:
            FST dword[xPos]     ;[xPos] = ST(0)

    ;;Y
    FINIT
    FLD     dword[angle]    ;ST(0) = angle
    FSIN                    ;ST(0) = cos(ST0) = cos(angle)
    FMUL    dword[speed]    ;ST(0) = speed*cos(angle)
    FADD    dword[yPos]     ;ST(0) = x + speed*cos(angle)
    FLDZ
    FCOMIP
    ja %%yIsNegative
    mov     dword[temp],100
    FILD    dword[temp]
    FCOMIP  
    jb %%yTooLarge
    jmp %%setY
        %%yIsNegative:
            mov     dword[temp], 100
            FIADD   dword[temp]
            jmp %%setY
        %%yTooLarge:
            mov     dword[temp], 100
            FISUB   dword[temp]
            jmp %%setY
        %%setY:
            FST dword[yPos]     ;[yPos] = ST(0)

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
    FLDZ
    FCOMIP
    ja %%speedIsNegative
    mov     dword[temp],100
    FILD    dword[temp]
    FCOMIP  
    jb %%speedTooLarge
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
    FLDZ
    FCOMIP
    ja %%angleIsNegative
    FLD dword[twoPi]
    FCOMIP
    jb %%angleTooLarge
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

    mov ebx, xOffset        ;ebx = xOffset
    add ebx, eax            ;ebx = drone.x adrs
    mov ecx, [xPos]         ;ecx = x
    mov dword[ebx], ecx     ;drone.x = x

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

    ;debugFields
%endmacro


section .rodata
    twoPi: dd 6.28318530718
    tempHexFormat: db 'dTemp: 0x%X',10, 0
    debugRandomFormat: db 'random converted to %f', 10, 0
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
    extern greet
    extern runTarget
    extern printf
    extern generateTarget



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
    ;debug
        ;push ebx
        ;mov dword[temp], ebx
        ;printHexTemp
        ;mov ecx, runTarget
        ;mov dword[temp],ecx
        ;printHexTemp
    ;enddebug
    ;pop ebx
    call resume
    jmp runDrone

mayDestroy:
    call    getTargetX
    mov     dword[tx],eax
    call    getTargetY
    mov     dword[ty],eax

    FINIT
    FLD     dword[tx]
    FSUB    dword[xPos]
    FMUL    ST0, ST0
    FST     dword[temp]

    FINIT
    FLD     dword[ty]
    FSUB    dword[yPos]
    FMUL    ST0, ST0

    FLD     dword[temp]
    FADD    ST0,ST1

    FSQRT       ;ST(0) = sqrt( (xt-xd)^2 + (yt-yd)^2 )

    call    getD
    mov     dword[temp], eax
    FLD     dword[temp]
    FCOMIP       ;comp distance with d

    jae destroyTarget
    jmp notInRange
        destroyTarget:
            mov eax, [currDrone]
            add eax, scoreOffset
            inc dword[eax]
            ;;need to resume target
            ;push COR_TARGET
            ;call getCo
            ;add esp, 4
            ;mov ebx, eax
            ;call resume
        notInRange:
    ret






    

