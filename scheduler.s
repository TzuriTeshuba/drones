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
section .rodata
    inValidResumeInputFormat: db 'Error: Tried to resume out of bounds co-routine', 10,0



section .bss

section .data
    currDroneId: dd 0
    currRound: dd 0  
    beginning: dd 0
    iModk: dd 0
    iModR: dd -1
    shouldTerminate: dd 0

section .text
    extern N
    extern getN
    extern getK
    extern getR
    global resume



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
resume:
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
runScheduler:
    call getN
    cmp dword[currDroneId], eax
    jne currDroneIdIsNotN
        currDroneIdIsN:
            mov dword[currDroneId],0
        currDroneIdIsNotN:
            resume dword[currDroneId]
            inc dword[currDroneId]
    
    call getK
    cmp dword[iModk], eax
    jne iModKisNotK
        iModKisK:
            mov dword[iModk],0
            resume COR_PRINTER
        iModKisNotK:
            inc dword[currDroneId]

    ;;how many rounds passed
    cmp dword[currDroneId],0
    jne endLoop
        newRound:
            inc dword[currRound]
            call getR
            cmp eax, [currRound]
            jne endLoop
            call eliminateLoser
            call checkForWinner

    endLoop:
        cmp dword[shouldTerminate],0
        je runScheduler
        ret







