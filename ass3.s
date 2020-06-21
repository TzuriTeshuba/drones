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
    mov dword[index],0

    %%makeStackLoop:
        mov eax, [index]
        cmp eax, [numCors]
        jge %%endMakeStackLoop

        makeStack
        add eax, STK_SIZE
        push eax

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
    mov eax,[numCors]
    push eax
    push COR_SIZE
    call calloc
    mov dword[cors],eax

    initFuncs
    makeStacks
%endmacro

%macro printGreeting 0
    push greetingMsg
    call printf
    add esp, 4
%endmacro

%macro printCors 0
    mov dword[index],0
%endmacro

;;assumes arg is in temp
%macro debugFloatConversion 0
    FLD dword[temp]
    sub esp, 8
    FSTP qword[esp]
    push debugRandomFormat
    call printf
    add esp, 12
%endmacro
%macro printTemp 0
    push dword[temp]
    push tempFormat
    call printf
    add esp, 8
%endmacro
%macro debugProgArgs 0
    push dword[temp]
    FLD dword[d]
    sub esp, 8
    FSTP qword[esp]
    push dword[K]
    push dword[R]
    push dword[N]
    push argsFormat
    call printf
    add esp, 28
%endmacro

section .rodata
    maxRandom:      dd 0xFFFF; 1111 1111 1111 1111
    droneSize:      dd 24       ;x,y,speed,angle,score, isAlive
    argIntFormat:   db '%d', 0
    argFloatFormat: db '%f',0
    argsFormat:     db 'N: %d, R: %d, K: %d, d: %f, seed(temp): %d', 10, 0
    greetingMsg:    db 'Drone Battale Royale!', 10, 0
    tempFormat:     db 'Temp: %d',10, 0
    debugRandomFormat: db 'random converted to %f', 10, 0

section .bss
    random:     resw 1
    N:          resd 1   ;initial number of drones
    R:          resd 1   ;number of full scheduler cycles between each elimination
    K:          resd 1   ;how many drone steps between game board printings  
    d:          resd 1   ;(float) maximum distance that allows to destroy a target
    drones:     resd 1   ;pointer to drone array
    temp:       resd 1
    result:     resd 1
    dronesLeft: resd 1
    cors:       resd 1
    corsStack:  resd 1
    numCors:    resd 1
    curr:       resd 1
    SPT:        resd 1
    SPMAIN:     resd 1
    debugVar:   resd 1
    stacks:     resd 1  ;pointer to array of stack pointer

section .data
    index: dd 0
    determNum: dd 0

section .text
    global greet
    global main
    global resume
    global getRandomNumber
    global getDrones
    global getDrone
    global getN
    global getK
    global getR
    global getD
    global startCo
    global endCo
    global myExit
    global convertToFloatInRange
    global convertToRadians
    global getCo
    extern printf
    extern sscanf
    extern malloc
    extern calloc
    extern free
    extern generateTarget
    extern runTarget
    extern runPrinter
    extern runScheduler
    extern runDrone

;;return esp after func calls
main:
    ;printGreeting
    FINIT
    initArgs:
        mov eax, [esp + 4] ;eax holds int argc
        mov ebx, [esp + 8] ;ebx holds char** argv
        cmp eax, 6  ;should be 6 args (progName, N, R, K, d, seed)
        jne endMain


        mov eax, [ebx + 4] ;eax = pointer to string rep of N
        push N
        push argIntFormat
        push eax
        call sscanf         ;N = (int)argv[1]
        add esp, 12
        mov eax,[N]
        mov dword[dronesLeft], eax

        mov ebx, [esp + 8]
        mov eax, [ebx + 8]
        push R
        push argIntFormat
        push eax
        call sscanf         ;R = (int)argv[2]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 12]
        push K
        push argIntFormat
        push eax
        call sscanf         ;K = (int)argv[3]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push d
        push argFloatFormat
        push eax
        call sscanf         ;d = (int)argv[4]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 20]
        push temp
        push argIntFormat
        push eax
        call sscanf         ;temp = (int)argv[5]
        add esp, 12

        mov eax, [temp]
        mov word [random],ax ;ax is less sig word of eax
    
    initTarget:
        call generateTarget

    initDrones:
        push dword[N]
        push dword[droneSize]
        call calloc
        add esp, 8
        mov dword[drones],eax
        ;debug
            ;mov dword[temp],eax
            ;printTemp
        ;enddebug
        mov dword[index], 0
        initDronesWhileLoop:
            ;check condition
            mov eax, [index]
            cmp eax, [N]
            jge endInitDronesWhileLoop

            mov edx, 0;;TODO - check edx is 0 after multiplying
            mov eax, [droneSize]
            mul dword[index]
            add eax, [drones]   ;eax holds address of drones[index]
            push eax
            ;debug
                ;mov dword[temp], eax
                ;printTemp
            ;enddebug
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange  ;eax = xPos in [0,100] range
            add esp, 12
            pop ebx                     ;ebx holds drones[i] pointer
            mov ecx, xOffset
            add ecx, ebx
            mov dword[ecx], eax         ;init x

            push ebx
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange
            add esp, 12
            pop ebx
            mov ecx, yOffset
            add ecx, ebx
            mov dword[ecx], eax   ;init y

            push ebx
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange
            add esp, 12
            pop ebx
            mov ecx, speedOffset
            add ecx, ebx
            mov dword[ecx], eax   ;init speed

            push ebx
            call getRandomNumber
            push eax
            push 360
            push 0
            call convertToFloatInRange
            add esp, 12
            push eax
            call convertToRadians
            add esp, 4
            pop ebx
            mov ecx, angleOffset
            add ecx, ebx
            mov dword[ecx], eax   ;init angle

            mov ecx, isAliveOffset
            add ecx, ebx
            mov dword[ecx],1

            inc dword[index]
            jmp initDronesWhileLoop

        endInitDronesWhileLoop:
            mov eax, [N]
            mov dword[numCors],eax
            add dword[numCors],3
            initCors
            push COR_SCHED
            call startCo
    endMain:
    ret

greet:
    printGreeting
    ret
convertToRadians:
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
    ;;correct address [cors] = ebx
    jmp do_resume
endCo:
    mov esp, [SPMAIN]
    popad
    ;;ret?????
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
    ;debug
    ; pop ecx
    ; mov dword[temp], ecx
    ; push ecx
    ; printTemp
    ; mov ecx, runScheduler
    ; mov dword[temp],ecx
    ; printTemp
    ;enddebug
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
;SHOULD NOT USE ecx
getDrone:
    mov eax, [ebp + 8]      ;eax = i
    mov ecx, [droneSize]
    mul ecx    ;eax = droneSize*i
    add eax, [drones]       ;eax = adrs of drones[i]
    ret

    



;DETERMINISTIC VERSION 1,2,3,4...
getRandomNumber:
    inc dword[determNum]
    mov eax, [determNum]
    mov word[random], ax
    ret


;11th, 13th, 14th, 16th bits xor'ed 
;stores result in [random] and in eax
getRandomNumber2:
    mov edx, 0 ;eax = i =0
    
    calcRandomhileLoop:
        ;;check condition - IMPLEMENT
        cmp edx, 16
        jge endOfCalcRandomWhileLoop
        shr word[random], 1 ;shift random by 1 bit
    ;11th bit
        mov ebx,0
        mov bx, 0x400 ;bx = 0000010000000000
        and bx, [random] ;bx = 0 or 0x800
        shr bx, 10
    ;13th bit
        mov ecx, 0
        mov cx, 0x1000 ;cx = 0001000000000000
        and cx, [random]
        shr cx, 12
        xor bx, cx
    ;14th bit
        mov ecx, 0
        mov cx, 0x2000 ;cx = 0010000000000000
        and cx, [random]
        shr cx, 13
        xor bx, cx
    ;16th bit
        mov ecx, 0
        mov cx, 0x8000 ;cx = 1000000000000000
        and cx, [random]
        shr cx, 15
        xor bx, cx

        shl bx,15              ;result is in msb of ax
        or word[random],ax  ;random has MSB replaced with result
        inc edx             ;i++
        jmp calcRandomhileLoop

    endOfCalcRandomWhileLoop:
    ;debug
        ;mov eax, 0
        ;mov ax, [random]
        ;mov dword[temp], eax
        ;printTemp
    ;enddebug
        mov eax, 0
        mov ax, [random]
        ret 
        
;;expect first arg/pop be lower bound, second to be upper bound, third is the raw number
convertToFloatInRange:
    finit               ;initialize x87 FP Subsystem
    mov ebx, [esp + 4]  ;ebx = lower bound
    mov eax, [esp + 8] ;eax = upper bound
    sub eax, ebx        ;eax = new upper bound (linear translation: [LB,UB] -> [0,UB-LB])
    mov dword[temp],eax ;[temp] = NewBound

    FILD dword[maxRandom]   ;ST(0) = maxRandom = 0x7FFF
    FIDIVR dword[temp]      ;ST(0) = NB / maxRandom
    mov eax, [esp + 12]     ;
    mov dword[temp], eax    ;[temp] = raw number to convert = r
    FIMUL dword[temp]       ;ST(0) = NB * (r / maxRandom)
    FIADD dword[esp + 4]    ;undo linear translation: ST(0) = ST(0) + LB
    FST dword[temp]         ;[temp] = ST(0)
    mov eax, [temp]         ;eax holds the converted value
    ret

myExit:
    ;printGreeting
    push dword[drones]
    call free
    add esp, 4

    push dword[cors]
    call free
    add esp, 4

theENDDD: