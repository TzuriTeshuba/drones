%define xOffset         0
%define yOffset         4
%define speedOffset     8
%define angleOffset     12
%define scoreOffset     16
%define isAliveOffset   20

%define CO_FUNC_OFF     0
%define CO_SP_OFF       4

%define COR_SCHED       0
%define COR_PRINTER     1
%define COR_TARGET      2
%define COR_SIZE        8
%define STK_SIZE        4096
%define PI              3.14159265359
%define twoPi           6.28318530718

;create stack on heap and return pointer in eax
;might need to pass end of stack address
%macro makeStack 0 
    push STK_SIZE
    push 1
    call calloc
    add eax, STK_SIZE
%endmacro

;;assumes numCors and cors has been initialized
%macro makeStacks 0
    mov eax, [numCors]
    push eax
    push 4
    call calloc
    add esp, 8
    mov dword[stacks],eax

    mov dword[index],0
    %%makeStackLoop:
        mov eax, [index]        ;eax = i
        cmp eax, [numCors]      ;cmp i with numCors
        jge %%endMakeStackLoop

        makeStack               
        push eax            ;eax = calloc + STK_SIZE, (store for later)

        mov ebx, eax        ;ebx = calloc ret val + STK+SIZE
        sub ebx, STK_SIZE   ;ebx = ptr to stack = ret from calloc
        mov eax, [index]    ;eax =i
        mov ecx, 4
        mul ecx               ;eax = 4*i
        add eax, [stacks]   ;eax = stacks + 4*i = adrs of stacks[i]
        mov dword[eax], ebx ;stacks[i] = calloc ret value


        push dword[index]
        call getCo          ;eax = adrs of cors[i]
        add esp, 4

        add eax, CO_SP_OFF  ;eax = cors[i].SP
        pop ebx             ;ebx = adrs of start of stack
        mov dword[eax], ebx ;cors[i].SP = adrs of start of stack

        ;;initCo(i)
        push dword[index]
        call getCo                      ;eax = cors + 8*i = cors[i] adrs            
        mov ebx, [eax + CO_FUNC_OFF]    ;ebx = cors[i].func
        mov dword[SPT], esp             ;[SPT] = esp
        mov esp, [eax + CO_SP_OFF]      ;esp = cors[i].SP
        push ebx                        ;push cors[i].func
        pushfd
        pushad
        mov dword[eax + CO_SP_OFF],esp  ;cors[i].func = top of local stack
        mov esp, [SPT]                  ;restore esp

        inc dword[index]
        jmp %%makeStackLoop
    %%endMakeStackLoop:
%endmacro

%macro initFuncs 0
    mov dword[index],0
    %%initFuncLoop:
        mov eax, [index]
        cmp eax, [numCors]
        jge %%endInitFuncLoop

        push dword[index]
        call getCo
        add esp, 4  ;eax = cors[i] adrs = cors[i].func adrs

        ;if (i=0)->scheduler  (i=1)->printer...
        cmp dword[index], COR_SCHED
        je %%initSchedFunc
        cmp dword[index], COR_PRINTER
        je %%initPrinterFunc 
        cmp dword[index], COR_TARGET
        je %%initTargetFunc
        jmp %%initDroneFunc

            %%initSchedFunc:
                mov dword[eax], runScheduler
                jmp %%afterInit
            %%initPrinterFunc:
                mov dword[eax], runPrinter
                jmp %%afterInit
            %%initTargetFunc:
                mov dword[eax], runTarget
                jmp %%afterInit
            %%initDroneFunc:
                mov dword[eax], runDrone
                jmp %%afterInit
        %%afterInit:
        inc dword[index]
        jmp %%initFuncLoop
    %%endInitFuncLoop:
%endmacro

%macro initCors 0
    mov  eax,[numCors]
    push eax
    push COR_SIZE
    call calloc
    mov  dword[cors],eax

    initFuncs
    makeStacks
%endmacro

%macro freeStacks 0
    mov dword[index],0
    %%freeStackLoop:
        mov eax, [index]
        cmp eax, [numCors]
        jge %%endFreeStackLoop
            mov  ebx, 4
            mul  ebx     ;eax = 4*i
            add  eax, [stacks]   ;eax = adrs of stacks[i]
            push dword[eax]
            call free
            add  esp, 4
        inc dword[index]
        jmp %%freeStackLoop
    %%endFreeStackLoop:
        push dword[stacks]
        call free
        add  esp, 4
%endmacro

%macro freeDronesAndCors 0
        push dword[drones]
        call free
        add  esp, 4

        push dword[cors]
        call free
        add  esp, 4
%endmacro

%macro autoInitProgArgs 0
    mov dword[N], 10
    mov dword[R], 5
    mov dword[K], 100000

    FINIT
    mov     dword[d], 50
    FILD    dword[d]
    FST     dword[d]        ;d = 50.0

    mov eax, [debugIdx]
    mov word[random],ax
%endmacro

section .rodata
    maxRandom:      dd 0xFFFF; 1111 1111 1111 1111
    droneSize:      dd 24       ;x,y,speed,angle,score, isAlive
    argIntFormat:   db '%d', 0
    argFloatFormat: db '%f',0
    greetingMsg:    db 'Drone Battale Royale!', 10, 0

section .bss
    random:         resw 1
    N:              resd 1   ;initial number of drones
    R:              resd 1   ;number of full scheduler cycles between each elimination
    K:              resd 1   ;how many drone steps between game board printings  
    d:              resd 1   ;(float) maximum distance that allows to destroy a target
    drones:         resd 1   ;pointer to drone array
    temp:           resd 1
    result:         resd 1
    dronesLeft:     resd 1
    cors:           resd 1
    corsStack:      resd 1
    numCors:        resd 1
    curr:           resd 1
    SPT:            resd 1
    SPMAIN:         resd 1
    stacks:         resd 1  ;pointer to array of stack pointer
    randomCntr:     resd 1

section .data
    index:          dd 0
    debugIdx:       dd 0

section .text
    global main
    global getN
    global getK
    global getR
    global getD
    global getRandomNumber
    global convertToFloatInRange
    global convertToRadians
    global getDrones
    global getDrone
    global getCo
    global resume
    global endCo
    global myExit
    extern printf
    extern sscanf
    extern calloc
    extern free
    extern runTarget
    extern runPrinter
    extern runScheduler
    extern runDrone
    extern generateTarget

main:
    FINIT
    initArgs:
        mov eax, [esp + 4]  ;eax holds int argc
        mov ebx, [esp + 8]  ;ebx holds char** argv
        cmp eax, 6          ;should be 6 args (progName, N, R, K, d, seed)
        jne endMain

        mov eax, [ebx + 4]      ;eax = pointer to string rep of N
        push N
        push argIntFormat
        push eax
        call sscanf             ;N = (int)argv[1]
        add esp, 12
        mov eax, [N]
        mov dword[dronesLeft], eax

        mov ebx, [esp + 8]
        mov eax, [ebx + 8]
        push R
        push argIntFormat
        push eax
        call sscanf             ;R = (int)argv[2]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 12]
        push K
        push argIntFormat
        push eax
        call sscanf             ;K = (int)argv[3]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push d
        push argFloatFormat
        push eax
        call sscanf             ;d = (int)argv[4]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 20]
        push temp
        push argIntFormat
        push eax
        call sscanf             ;temp = (int)argv[5]
        add esp, 12

        mov eax, [temp]
        mov word [random],ax    ;ax is less sig word of eax
    initTarget:
        call generateTarget

    initDrones:
        push dword[N]
        push dword[droneSize]
        call calloc
        add  esp, 8
        mov  dword[drones],eax
        mov  dword[index], 0
        initDronesWhileLoop:
            ;check condition
            mov eax, [index]
            cmp eax, [N]
            jge endInitDronesWhileLoop

            mov  eax, [droneSize]    ;eax = droneSize
            mul  dword[index]        ;eax = i*droneSize
            add  eax, [drones]       ;eax holds address of drones[i]
            push eax                 ;save for popping later

            add eax, isAliveOffset
            mov dword[eax],1

            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange      ;eax = xPos in [0,100] range
            add  esp, 12
            pop  ebx                        ;ebx holds drones[i] pointer
            mov  ecx, xOffset
            add  ecx, ebx
            mov  dword[ecx], eax            ;init x

            push ebx
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange
            add  esp, 12
            pop  ebx
            mov  ecx, yOffset
            add  ecx, ebx
            mov  dword[ecx], eax            ;init y

            push ebx
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange
            add  esp, 12
            pop  ebx
            mov  ecx, speedOffset
            add  ecx, ebx
            mov  dword[ecx], eax            ;init speed

            push ebx
            call getRandomNumber
            push eax
            push 360
            push 0
            call convertToFloatInRange
            add  esp, 12
            push eax
            call convertToRadians
            add  esp, 4
            pop  ebx
            mov  ecx, angleOffset
            add  ecx, ebx
            mov  dword[ecx], eax            ;init angle

            inc dword[index]
            jmp initDronesWhileLoop

        endInitDronesWhileLoop:
            mov  eax, [N]
            mov  dword[numCors],eax
            add  dword[numCors],3
            initCors
            push COR_SCHED
            call startCo
    endMain:
        mov al, 1
        mov ebx, 0
        int 0x80
        ret

convertToRadians:
    mov eax, [esp + 4]  ;eax = degrees
    FINIT
    mov dword[temp], eax
    FLD dword[temp]         ;ST0 = degrees
    FLDPI                   ;ST0=pi, ST1 = degrees
    FMUL ST0, ST1           ;ST0 = pi*degrees
    mov dword[temp], 180
    FIDIV dword[temp]       ;ST0 = pi*degrees/180 = radians
    FST dword[temp]
    mov eax, [temp]
    ret

;receives i as args
getCo:
    mov eax, [esp + 4]  ;eax = i
    mov ecx, COR_SIZE   ;ecx = corSize = 8
    mul ecx             ;eax = i*corSize
    add eax, [cors]     ;eax = cors + i*corSize = cors[i] adrs
    ret

;;received i (cor id) as arg
startCo:
    mov eax, [esp+4];
    mov dword[temp],eax;
    pushad                  ;backup regs
    mov dword[SPMAIN],esp   ;[SPMAIN] backs up esp

    mov eax, [temp]         ;eax = cor id = i
    mov ecx, COR_SIZE       ;ecx = 8
    mul ecx                 ;eax = i*corSize = 8*i
    add eax, [cors]         ;eax = cors adrs +8*i
    mov ebx, eax
    jmp do_resume

endCo:
    mov esp, [SPMAIN]
    popad
    call myExit

resume:
    pushfd
    pushad
    mov edx, [curr]
    mov dword[edx + CO_SP_OFF], esp

do_resume:
    mov esp, [ebx + CO_SP_OFF]  ;esp = cors[i].SP
    mov dword[curr],ebx         ;[curr] = cors[i]
    popad                       ;restore previous register values
    popfd                       ;...and flags
    ret                         ;jump to cors[i].func()

getN:
    mov eax, [N]
    ret
getD:
    mov eax, [d]
    ret
getK:
    mov eax, [K]
    ret
getR:
    mov eax, [R]
    ret

getDrones:
    mov eax, [drones]
    ret

;assumes dword of index was pushed
getDrone:
    mov eax, [esp + 4]      ;eax = i
    mov ecx, [droneSize]
    mul ecx                 ;eax = droneSize*i
    add eax, [drones]       ;eax = adrs of drones[i]
    ret

;[random shifted left 1-bit, then 11th, 13th, 14th, 16th bits of [random] are xor'ed and the result is stored MSB of [random]
getRandomNumber:
    mov dword[randomCntr],0
    ;;shl muls by 2, shr divs by 2
    calcRandomhileLoop:
        ;;check condition
        cmp dword[randomCntr], 16
        jge endOfCalcRandomWhileLoop
        shr word[random], 1 ;shift random by 1 bit
    ;6th bit
        mov ebx,1
        shl ebx,5         
        and bx, [random]    
        shr bx, 5
    ;4th bit
        mov ecx, 1
        shl ecx, 3         
        and cx, [random]    
        shr ecx, 3
        xor bx, cx
    ;3th bit
        mov ecx, 1
        shl ecx, 2 
        and cx, [random]
        shr ecx, 2
        xor bx, cx
    ;1th bit
        mov ecx, 1
        and cx, [random]
        xor bx, cx

        shl bx, 15                  ;result is in msb of bx
        or  word[random],bx         ;random has MSB replaced with result
        inc dword[randomCntr]       ;i++
        jmp calcRandomhileLoop

    endOfCalcRandomWhileLoop:
        mov eax, 0
        mov ax, [random]
        ret 
        
;;expect first arg/pop be lower bound, second to be upper bound, third is the raw number
convertToFloatInRange:
    FINIT                       ;initialize x87 FP Subsystem
    mov     ebx, [esp + 4]      ;ebx = lower bound
    mov     eax, [esp + 8]      ;eax = upper bound
    sub     eax, ebx            ;eax = new upper bound (linear translation: [LB,UB] -> [0,UB-LB])
    mov     dword[temp],eax     ;[temp] = NewBound

    FILD    dword[maxRandom]    ;ST(0) = maxRandom = 0x0000FFFF
    FIDIVR  dword[temp]         ;ST(0) = NB / maxRandom
    mov     eax, [esp + 12]      
    mov     dword[temp], eax    ;[temp] = raw number to convert = r
    FIMUL   dword[temp]         ;ST(0) = NB * (r / maxRandom)
    FIADD   dword[esp + 4]      ;undo linear translation: ST(0) = ST(0) + LB
    FST     dword[temp]         ;[temp] = ST(0)
    mov     eax, [temp]         ;eax holds the converted value
    ret

myExit:
    freeStacks
    freeDronesAndCors
    mov al, 1
    mov ebx, 0
    int 0x80

