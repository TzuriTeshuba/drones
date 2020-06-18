section .rodata
    %define xOffset 0
    %define yOffset 2
    %define speedOffset 4
    %define angleOffset 6
    %define scoreOffset 8
    %define isAliveOffset 12
    %define pidOffset 16
    droneSize: dd 20 ;pid(dword),x,y,speed,angle,score, isAlive, pid
    argFormat: db '%d', 0
section .bss
    random: resw 1
    N: resd 1   ;initial number of drones
    R: resd 1   ;number of full scheduler cycles between each elimination
    K: resd 1   ;how many drone steps between game board printings  
    d: resd 1   ;(float) maximum distance that allows to destroy a target
    drones: resd 1    ;pointer to drone array
    temp: resd 1

section .data
    index: dd 0

section .text
    global random
    global getRandomNumber
    global getDrones
    global getDrone
    global getN
    extern sscanf
    extern malloc
    extern calloc
    extern free
    extern generateTarget

main:
    initArgs:
        mov eax, [esp + 4] ;eax holds int argc
        mov ebx, [esp + 8] ;ebx holds char** argv
        cmp eax, 6  ;should be 6 args (progName, N, R, K, d, seed)
        jne endMain
        mov eax, [ebx + 4] ;eax = pointer to string rep of N
        push eax
        push argFormat
        push N
        call sscanf         ;N = (int)argv[1]

        mov ebx, [esp + 8]
        mov eax, [ebx + 8]
        push eax
        push argFormat
        push R
        call sscanf         ;R = (int)argv[2]

        mov ebx, [esp + 8]
        mov eax, [ebx + 12]
        push eax
        push argFormat
        push K
        call sscanf         ;K = (int)argv[3]

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push eax
        push argFormat
        push d
        call sscanf         ;d = (int)argv[4]

        mov ebx, [esp + 8]
        mov eax, [ebx + 16]
        push eax
        push argFormat
        push temp
        call sscanf         ;temp = (int)argv[5]
        mov eax, [temp]
        mov word[random],ax ;ax is less sig word of eax
    
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

            mov ebx, [droneSize]
            mul ebx, [index]
            add ebx, [drones]   ;ebx holds address of drones[index]

            push ebx
            call getRandomNumber
            pop ebx
            mov word[ebx + xOffset], ax   ;init x

            push ebx
            call getRandomNumber
            pop ebx
            mov word[ebx + yOffset], ax   ;init y

            push ebx
            call getRandomNumber
            pop ebx
            mov word[ebx + speedOffset], ax   ;init speed

            push ebx
            call getRandomNumber
            pop ebx
            mov word[ebx + angleOffset], ax   ;init angle

            mov dword[ebx + isAliveOffset],1

            inc dword[index]
            jmp initDronesWhileLoop

        endInitDronesWhileLoop:

    endMain:
    ret

getN:
    mov eax, [N]
    ret

getDrones:
    mov eax, [drones]
    ret

;assumes dword of index was pushed
;SHOULD NOT USE ecx
getDrone:
    call getDrones
    mov ebx, eax
    pop eax
    add eax, ebx*droneSize

    

;11th, 13th, 14th, 16th bits xor'ed 
;stores result in [random] and in eax
getRandomNumber:
    mov eax, 0 ;eax = i =0
    
    calcRandomhileLoop:
        ;;check condition - IMPLEMENT
        cmp eax, 16
        jge endOfWhileLoop
    ;11th bit
        shr word[random], 1 ;shift random by 1 bit
        mov ebx,0
        mov bx, 0x400 ;bx = 0000010000000000
        and bx, [random] ;bx = 0 or 0x800
        div bx, 0x400 ;bx = 0 or 1
    ;13th bit
        mov ecx, 0
        mov cx, 0x1000 ;cx = 0001000000000000
        and cx, [random]
        div cx, 0x1000
        xor bx, cx
    ;14th bit
        mov ecx, 0
        mov cx, 0x2000 ;cx = 0010000000000000
        and cx, [random]
        div cx, 0x2000
        xor bx, cx
    ;16th bit
        mov ecx, 0
        mov cx, 0x8000 ;cx = 1000000000000000
        and cx, [random]
        div cx, 0x8000
        xor bx, cx

        mul bx, 0x8000 ;result is in msb of bx
        or word[random],bx ;random has MSB replaced with result
        inc eax         ;i++
        jmp whileLoop

    endOfCalcRandomWhileLoop:
        mov eax, 0
        mov ax, [random]
        ret 
        

theENDDD:



