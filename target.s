section .rodata

section .bss
    targetX: resw 1
    targetY: resw 1

section .data   

section .text
    global getTargetX
    global getTargetY
    global generateTarget
    extern getRandomNumber

targetRun:
     call generateTarget
     ;;
     ;;SUSPEND PROCESS
     ;;
     jmp targetRun

generateTarget:
    getRandomNumber
    mov word[targetX],ax
    getRandomNumber
    mov word[targetY],ax
    ret

getTargetX:
    mov eax,0
    mov ax, [targetX]
    ret

getTargetY:
    mov eax,0
    mov ax, [targetY]
    ret