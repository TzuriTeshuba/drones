%define xOffset 0
%define yOffset 2
%define speedOffset 4
%define angleOffset 6
%define scoreOffset 8
%define isAliveOffset 12
%define DRONE_SIZE 16

%define THREAD_SIZE 4000
%define COR_SCHEDULER -1
%define COR_PRINTER -2
%define COR_TARGET -3

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
        call getN
        mov ebx, eax
        mov eax, [index]
        cmp eax, ebx
        je %%endForLoop
        push ebx
        call getDrone
        mov ebx, eax
        add ebx, isAliveOffset
        cmp dword[ebx],0
        je %%droneNotActive
        jmp %%droneIsActive
            %%droneNotActive:
                inc dword[index]
                jmp %%forLoop
            %%droneIsActive:
                inc dword[numActive]
                mov ebx, eax
                add ebx, scoreOffset
                mov ebx, [ebx]
                cmp ebx, minScore
                jl %%updateLoser
                inc dword[index]
                jmp %%forLoop
                    %%updateLoser:
                        mov dword[minScore], ebx
                        mov dword[currLoser], eax
                        inc dword[index]
                        jmp %%forLoop
    %%endForLoop:
        ;;deactivate loser
        mov eax, [currLoser]
        add eax, isAliveOffset
        mov dword[eax],0
%endmacro
section .rodata
    inValidResumeInputFormat: db 'Error: Tried to resume out of bounds co-routine', 10,0
    winnerFormat: db 'The winner is Drone #%d',10,0

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


;;void setCurrDrone(int droneId)
getCurrDroneId:
    mov eax, [currDroneId]
    ret

isDroneActive:
    push dword[currDroneId]
    call getDrone
    add eax, isAliveOffset
    mov eax, [eax]


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
        cmp dword[gameOver],0
        je runScheduler
        jmp endCo







