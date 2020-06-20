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



%macro initCors 0
    mov eax,[N]
    add eax, 3
    push eax
    push COR_SIZE
    call calloc
    mov dword[cors],eax

    mov eax, [N]
    add eax, 3
    push eax
    mov eax, STK_SIZE
    call calloc
    mov dword[corsStack], eax

    mov ebx, [cors]
    ;;cors[0] is scheduler
    mov dword[ebx], runScheduler
    mov eax, STK_SIZE
    add eax, [corsStack]
    mov dword[ebx+CO_SP_OFF],eax

    ;;cors[1] is printer
    mov dword[ebx +COR_PRINTER*COR_SIZE], runPrinter
    mov eax, STK_SIZE
    mov ecx, COR_PRINTER + 1
    mul ecx
    add eax, [corsStack]
    mov dword[ebx+COR_PRINTER*COR_SIZE+CO_SP_OFF], eax

    ;;cors[2] is target
    mov dword[ebx +COR_TARGET*COR_SIZE], runTarget
    mov eax, STK_SIZE
    mov ecx, COR_TARGET+1
    mul ecx
    add eax, [corsStack]
    mov dword[ebx+COR_TARGET*COR_SIZE+CO_SP_OFF], eax

    mov dword[index],0
    %%initDroneCorsWhileLoop:
        ;check condition (index < N+3)
        mov eax, [index]
        cmp eax, [N]
        jge %%endInitDroneCorsWhileLoop

        ;;cors[i+3] is drone i
        mov eax, [index]
        add eax, 3
        mov ecx, COR_SIZE
        mul ecx
        add eax, [cors]
        mov dword[eax], runDrone

        mov eax, [index]
        add eax, 4
        mov ecx, STK_SIZE
        mul ecx
        add eax, [corsStack]

        mov dword[ebx+CO_SP_OFF], eax

        inc dword[index]
        jmp %%initDroneCorsWhileLoop
    %%endInitDroneCorsWhileLoop:
    %%initStacks:
        mov dword[index],0
        %%initStacksForLoop:
            mov eax, [index];;was ebx
            cmp eax, [numCors];;eas ebx
            jge %%endInitStacksForLoop

            ;;initCo(i)
            mov ecx, COR_SIZE
            mul ecx
            add eax, [cors]
            mov ebx, [eax + CO_FUNC_OFF]
            mov dword[SPT], esp
            mov esp, [eax + CO_SP_OFF]
            push ebx
            pushfd
            pushad
            mov dword[eax + CO_SP_OFF],esp
            mov esp, [SPT]


            inc dword[index]
            jmp %%initStacksForLoop

        %%endInitStacksForLoop:


%endmacro

%macro printGreeting 0
    push greetingMsg
    call printf
    add esp, 4
%endmacro

%macro debugProgArgs 0
    push dword[temp]
    push dword[d]
    push dword[K]
    push dword[R]
    push dword[N]
    push argsFormat
    call printf
    add esp, 24
%endmacro

section .rodata
    maxRandom:      dt 0xFFFF.0
    droneSize:      dd 24       ;x,y,speed,angle,score, isAlive
    argIntFormat:   db '%d', 0
    argFloatFormat: db '%f',0
    argsFormat:     db 'N: %d, R: %d, K: %d, d: %f, seed(temp): %d', 10, 0
    greetingMsg:    db 'Drone Battale Royale!', 10, 0
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

section .data
    index: dd 0

section .text
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
    printGreeting
    FINIT
    initArgs:
        mov eax, [esp + 4] ;eax holds int argc
        mov ebx, [esp + 8] ;ebx holds char** argv
        cmp eax, 6  ;should be 6 args (progName, N, R, K, d, seed)
        jne endMain

        mov eax, [ebx + 4] ;eax = pointer to string rep of N
        push eax
        push argIntFormat
        push N
        call sscanf         ;N = (int)argv[1]
        add esp, 12
        mov eax,[N]
        mov dword[dronesLeft], eax

        mov ebx, [esp + 8]
        mov eax, [ebx + 8]
        push eax
        push argIntFormat
        push R
        call sscanf         ;R = (int)argv[2]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 12]
        push eax
        push argIntFormat
        push K
        call sscanf         ;K = (int)argv[3]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push eax
        push argFloatFormat
        push d
        call sscanf         ;d = (int)argv[4]
        add esp, 12

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push eax
        push argIntFormat
        push temp
        call sscanf         ;temp = (int)argv[5]
        add esp, 12

        mov eax, [temp]
        mov word[random],ax ;ax is less sig word of eax
        debugProgArgs
    
    initTarget:
        call generateTarget

    initDrones:
        push dword[N]
        push dword[droneSize]
        call calloc
        mov dword[drones],eax

        mov dword[index], 0
        initDronesWhileLoop:
            ;check condition
            mov eax, [index]
            cmp eax, [N]
            jge endInitDronesWhileLoop

            mov edx, 0;;TODO - check edx is 0 after multiplying
            mov eax, [droneSize]
            mul dword[index]
            add eax, [drones]   ;ebx holds address of drones[index]

            push eax
            call getRandomNumber
            push eax
            push 100
            push 0
            call convertToFloatInRange
            add esp, 12
            pop ebx
            mov ecx, xOffset
            add ecx, ebx
            mov dword[ecx], eax   ;init x

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
        push 0
        call startCo
    endMain:
    ret

convertToRadians:
ret
;receives i as args
getCo:
    mov eax, [ebp + 8]
    mov ecx, COR_SIZE
    mul ecx
    add eax, [cors]
    ret


;;received i (cor id) as arg
startCo:
    pushad                  ;backup regs
    mov dword[SPMAIN],esp   ;[SPMAIN] backs up esp
    mov eax, [ebp+8]        ;ebx = cor id = i
    mov ecx, COR_SIZE
    mul ecx                 ;ebx = i*corSize
    add eax, [cors]         ;ebx = cors[i]
    mov ebx, eax
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

    

;11th, 13th, 14th, 16th bits xor'ed 
;stores result in [random] and in eax
getRandomNumber:
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

        mov eax, 0
        mov ax, 0x8000
        mul bx              ;result is in msb of ax
        or word[random],ax  ;random has MSB replaced with result
        inc edx             ;i++
        jmp calcRandomhileLoop

    endOfCalcRandomWhileLoop:
        mov eax, 0
        mov ax, [random]
        ret 
        
;;expect first arg/pop be lower bound, second to be upper bound, third is the raw number
convertToFloatInRange:
    finit               ;initialize x87 FP Subsystem
    mov ebx, [esp + 8] ;ebx = lower bound
    mov eax, [esp + 12] ;eax = upper bound
    sub eax, ebx        ;eax = new upper bound (linear translation: [LB,UB] -> [0,UB-LB])
    mov dword[temp],eax

    FLD tword[maxRandom]    ;ST(0) = maxRandom = 0xFFFF
    FIDIVR dword[temp]     ;ST(0) = NB / maxRandom
    mov eax, [esp + 16]
    mov dword[temp], eax    ;[temp] = raw number to convert = r
    FIMUL dword[temp]       ;ST(0) = NB * (r / maxRandom)
    FIADD dword[esp + 4]    ;undo linear translation: ST(0) = ST(0) + LB
    FST dword[temp]         ;[temp] = ST(0)
    mov eax, [temp]         ;eax holds the converted value
    ret

myExit:
    push dword[drones]
    call free
    add esp, 4

    push dword[cors]
    call free
    add esp, 4

    push dword[corsStack]
    call free
    add esp, 4


theENDDD: