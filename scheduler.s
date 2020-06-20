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

%macro checkForWinner 0
    cmp dword[numActive],1
    jne %%keepPlaying
    mov dword[index],0
    %%getWinnerWhileLoop:
        

    %%keepPlaying:
%endmacro


%macro eliminateLoser 0
    ;hold min in eax
    ;hold currLoser in ebx
    ;iterate over drones and at end deactivate currLoser
    mov dword[minScore],0x0FFFFFFF
    mov dword[numActive],-1
    mov dword[index],0
    %%forLoop:
        mov eax, [index]
        cmp eax, [N]
        je %%endForLoop
        push eax
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
                        jmp forLoop
    %%endForLoop:
        ;;deactivate loser
        mov eax, [currLoser]
        add eax, isAliveOffset
        mov dword[eax],0
%endmacro
section .rodata
    inValidResumeInputFormat: db 'Error: Tried to resume out of bounds co-routine', 10,0



section .bss

section .data
    numActive:      dd 0
    currLoser:      dd 0
    minScore:       dd 0
    currDroneId:    dd 0
    currRound:      dd 0  
    beginning:      dd 0
    iModk:          dd 0
    iModR:          dd -1
    shouldTerminate:dd 0
    index:          dd 0
    gameOver:       dd 1

section .text
    extern N
    extern getN
    extern getK
    extern getR
    extern getDrone
    extern resume
    extern endCo
    extern cors




initProcesses:
    push ebp            ;;from lab 9
	mov	ebp, esp        ;;from lab 9
	;sub	esp, STK_RES    ;;from lab 9

    initTargetProcess

eliminateLoser:
    ret

checkForWinner:
    ret
;;void resume(int co-routine)
myResume:
    mov ebx, [esp + 4]
    cmp ebx, COR_PRINTER
    je resumePrinter
    cmp ebx, COR_SCHEDULER
    je resumeScheduler
    cmp ebx, COR_TARGET
    je resumeTarget
    call getN
    mov ebx, [esp + 4]
    cmp ebx, eax    ;cmp arg with N
    jge inValidResumeInput
    cmp ebx, COR_TARGET
    jl inValidResumeInput
        resumeDrone:
            push dword[esp+4]
            call resumeDroneCoroutine
            jmp endOfResume
        resumePrinter:
            call printGame
            jmp endOfResume
        resumeScheduler:
            ;;???
        resumeTarget:
            call targetRun
            jmp endOfResume
        inValidResumeInput:
            mov edx, 47                             ;edx = numBytes to write
            mov ecx, inValidResumeInputFormat       ;ecx = char (buffer)
            mov ebx, 2                              ;ebx = stderr
            mov eax, 4                              ;eax = sys_write op code
            int 0x80                                ;call the kernel

    endOfResume:
        pop eax
        ret


/*
(*) start from i=0
(1)if drone (i%N)+1 is active
    (*) switch to the i’th drone co-routine
(2) if i%K == 0 //time to print the game board
    (*) switch to the printer co-routine
(3) if (i/N)%R == 0 && i%N ==0 //R rounds have passed
    (*) find M - the lowest number of targets destroyed, between all of the active drones
    (*) "turn off" one of the drones that destroyed only M targets.
(4) i++
(5) if only one active drone is left
    (*)print The Winner is drone: <id of the drone>
    (*) stop the game (return to main() function or exit)
*/
;;need to check if drone is sctive...
runScheduler:
    call getN
    cmp dword[currDroneId], eax
    jne currDroneIdIsNotN
        currDroneIdIsN:
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
                    inc dword[currDroneId]
                    inc dword[iModk]
                    jmp runScheduler

                currDroneIsActive:
                    mov eax, [currDroneId]
                    add eax, 3
                    push eax
                    call getCo
                    add esp, 4
                    mov ebx, eax    ;ebx = eax = pointer to cor(drone i)
                    call resume
                    inc dword[currDroneId]
    
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
            inc dword[currDroneId]

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
        cmp dword[shouldTerminate],0
        je runScheduler
        jmp endCo







