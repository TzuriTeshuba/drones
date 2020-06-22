%define xOffset 0
%define yOffset 4
%define speedOffset 8
%define angleOffset 12
%define scoreOffset 16
%define isAliveOffset 20
%define DRONE_SIZE 24

%define THREAD_SIZE 4096
%define COR_SCHEDULER 0
%define COR_PRINTER 1
%define COR_TARGET 2

%macro printHexTemp 0
    push dword[temp]
    push tempHexFormat
    call printf
    add esp, 8
%endmacro
;;checks if there is a winner. if yes: prints winner and sets gameOver flag and exit program
;;pre-condition: numActive holds number of active drones
%macro checkForWinner 0
    cmp dword[numActive],1
    jne %%keepPlaying
    mov dword[index],0
    %%getWinnerWhileLoop:
        push dword[index]
        call getDrone
        add esp, 4
        cmp dword[eax+isAliveOffset],0
        je %%notTheWinner
        jmp %%foundWinner
            %%notTheWinner:
                inc dword[index]
                jmp %%getWinnerWhileLoop
            %%foundWinner:
                push dword[index]
                push winnerFormat
                call printf
                add esp, 8
                mov dword[gameOver],1
                call myExit
    %%keepPlaying:
%endmacro

;;deactivates drone with lowest score. if multiple, than one with lowest id
%macro eliminateLoser 0
    ;hold min in eax
    ;hold currLoser in ebx
    ;iterate over drones and at end deactivate currLoser
    mov dword[minScore],0x0FFFFFFF
    mov dword[numActive],-1
    mov dword[index],0
    %%forLoop:
        call    getN                ;eax = N
        mov     ebx, eax            ;ebx = N
        mov     eax, [index]        ;eax = i
        cmp     eax, ebx            ;if i<= N endForLoop
        je %%endForLoop 
        push    eax                 ;push i
        call    getDrone            ;eax = drones[i] adrs
        add     esp,4   
        mov     ebx, eax            ;ebx = drones[i] adrs
        add     ebx, isAliveOffset  ;ebx = drones[i].status adrs
        cmp     dword[ebx],0        ;if status = 0 => not active
        je %%droneNotActive
        jmp %%droneIsActive
            %%droneNotActive:
                inc dword[index]    ;i++
                jmp %%forLoop       ;try next drone
            %%droneIsActive:
                inc dword[numActive];numActive++
                mov ebx, eax        ;ebx = drones[i] adrs
                add ebx, scoreOffset;ebx = drones[i].score adrs
                mov ebx, [ebx]      ;ebx = drones[i].score
                cmp ebx, minScore   ;if score < minScore => you currLoser
                jl %%updateLoser
                inc dword[index]    ;else i++ and try next drone
                jmp %%forLoop
                    %%updateLoser:
                        mov dword[minScore], ebx    ;minScore = drones[i].score
                        mov dword[currLoser], eax   ;currLoser = drones[i] adrs 
                        inc dword[index]            ;i++
                        jmp %%forLoop               ;try next drone
    %%endForLoop:
        ;;deactivate loser
        mov eax, [currLoser]    ;eax = adrs of loser
        add eax, isAliveOffset  ;eax = loser.status adrs
        mov dword[eax],0        ;loser.status = 0
%endmacro
section .rodata
    inValidResumeInputFormat: db 'Error: Tried to resume out of bounds co-routine', 10,0
    winnerFormat: db 'The winner is Drone #%d',10,0
    tempHexFormat: db 'sTemp: 0x%X',10, 0

section .bss

section .data
    numActive:      dd 0
    currLoser:      dd 0
    minScore:       dd 0
    currDroneId:    dd 0
    currRound:      dd 0  
    iModk:          dd 0
    beginning:      dd 0
    index:          dd 0
    gameOver:       dd 0
    temp:           dd 0
    counter:        dd 0

section .text
    global getCurrDroneId
    global runScheduler
    extern getN
    extern getK
    extern getR
    extern getDrone
    extern resume
    extern getCo
    extern endCo
    extern cors
    extern setCurrDrone
    extern printf
    extern myExit
    extern greet
    extern runDrone
    extern runPrinter
    extern printGame


;;void setCurrDrone(int droneId)
getCurrDroneId:
    mov eax, [currDroneId]
    ret

isDroneActive:
    push dword[currDroneId]
    call getDrone
    add esp, 4
    add eax, isAliveOffset
    mov eax, [eax]
    ret


; (*) start from i=0
; (*)if drone (i%N)+1 is active
;     (*) switch to the i’th drone co-routine
; (*) if i%K == 0 //time to print the game board
;     (*) switch to the printer co-routine
; (*) if (i/N)%R == 0 && i%N ==0 //R rounds have passed
;     (*) find M - the lowest number of targets destroyed, between all of the active drones
;     (*) "turn off" one of the drones that destroyed only M targets.
; (*) i++
; (*) if only one active drone is left
;     (*)print The Winner is drone: <id of the drone>
;     (*) stop the game (return to main() function or exit)
runScheduler:
    call getN                       ;eax = N
    cmp dword[currDroneId], eax     ;cmp currDroneId with N
    jne currDroneIdIsNotN           ;if less than N...
        currDroneIdIsN:             ;else id>=N, let id=0 and increment round
            mov dword[currDroneId],0    
            inc dword[currRound]
        currDroneIdIsNotN:
            push dword[currDroneId]
            call isDroneActive
            add esp, 4
            cmp eax, 0
            je currDroneNotActive
            jmp currDroneIsActive
                currDroneNotActive:
                    jmp printerCheck

                currDroneIsActive:
                    mov eax, [currDroneId]
                    add eax, 3
                    push eax
                    call getCo
                    add esp, 4
                    mov ebx, eax    ;ebx = eax = pointer to cor(drone i)
                        ;debug
                            ;push ebx
                            ;mov dword[temp], ebx
                            ;printHexTemp
                            ;mov ecx, runDrone
                            ;mov dword[temp],ecx
                            ;printHexTemp
                            ;pop ebx
                        ;enddebug
                    call resume
    printerCheck:
        call getK
        cmp dword[iModk], eax
        jne iModKisNotK
            iModKisK:
                mov dword[iModk],0
                push COR_PRINTER
                call getCo
                add esp, 4
                mov ebx, eax
                call resume
            iModKisNotK:
    ;;how many rounds passed
    cmp dword[currDroneId],0
    jne endLoop
        newRound:
            call getR
            cmp eax, [currRound]
            jne endLoop
            mov dword[currRound], 0
            eliminateLoser
            checkForWinner

    endLoop:
        inc dword[currDroneId]
        inc dword[iModk]
        inc dword[counter]

        cmp dword[counter], 100
        jge endCo

        cmp dword[gameOver],0
        je runScheduler
        jmp endCo







