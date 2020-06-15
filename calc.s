
section .rodata
    _linkSize: db 5
    _hexaFormat: db '%x',10,0
    _calcPrompt: db "calc: ", 0
    _format_string: db "%s", 10, 0	; format string
    _format_string2: db "%s",' '	; format string

    _format_debugPush: db "pushed ", 0
     _format_debugPop: db "popped ", 0

    _overFlowMsg: db 'Error: Operand Stack Overflow', 10,0
    _underFlowMsg: db 'Error: Insufficient Number of Arguments on Stack', 10, 0
    _testMsg: db 'checking', 10, 0


section .bss
    _carry: resb 1
    _operandStack: resd 0xFF
    _topOfStack: resd 1         
    _result: resd 1
    _inputBuffer: resb 80
    _x: resd 1 ;pointer to link
    _y: resd 1
    _char: resb 1
    _next: resd 1
    _curr: resd 1
    _d_curr: resd 1
    _prev: resd 1
    _newHead: resd 1
    _oldHead: resd 1
    _toFree1: resd 1
    _toFree2: resd 1
    _inputLength: resd 1
    _size: resd 1

section .data
    _stackCapacity: dd 5
    _numOperations: dd 0
    ;_size: dd 0
    _idx: dd 0
    _valx: db 0
    _valy: db 0
    _valz: db 0
    _debug: db 0


section .text
    align 16
    global main
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern getchar 
    extern fgets   






;*********************************** User Input ************************************
%macro getUserInput 0
    mov edx, 7              ;edx = numBytes
    mov ecx, _calcPrompt    ;ecx = calcPrompt
    mov ebx, 1              ;ebx = stdout dirent
    mov eax, 4              ;eax = sys_write op code
    int 0x80                ;call the kernel

    ;read relavent byte code to buffer
    mov edx, 80                 ;edx = numBytes
    mov ecx, _inputBuffer     ;ecx = inputBuffer
    mov ebx, 0          ;ebx = stdin dirent
    mov eax, 3       ;eax = sys_read op code
    int 0x80            ;call the kernel to read numBytes to buffer
%endmacro

;verified - convert char buffer to hexa byte rep
%macro convertAsciiToHexa 0
    mov dword[_idx],0
    %%whileLoop:
        mov ebx,_inputBuffer   ;ebx = address of buffer 
        mov ecx, [_idx]         ;ecx holds value of _idx
        mov eax,0
        mov al,[ebx+ecx]        ;al hold value of char at buffer[idx]
        cmp al, 0
        jz %%endWhileLoop
        cmp al, 10
        jz %%endWhileLoop
        mov byte[_char], al
        cmp byte[_char], 60     ;digits less than 60, letters greater than 60
        jl %%ifDigit
        jmp %%ifLetter

    %%ifDigit:
        sub byte[_char], 48
        jmp %%regardless
        
    %%ifLetter:
        sub byte[_char], 55
        jmp %%regardless
    
    %%regardless:
        mov al, [_char]
        mov ebx, _inputBuffer
        mov byte[ebx+ecx], al
        inc dword[_idx]
        jmp %%whileLoop

    %%endWhileLoop:
        mov eax, [_idx]
        mov dword[_inputLength], eax

%endmacro

;;completed
%macro listify 0
    mov dword [_oldHead], 0
    mov dword[_idx], 0
    %%whileLoop: ;while(idx<inputLength)
        ;;check condition
        mov eax, [_idx]
        mov ebx, [_inputLength]
        sub ebx, eax    ;ebx = length - idx
        cmp ebx, 0       
        jle %%endWhileLoop
        ;read val from buffer         
        add eax, _inputBuffer            ;let eax = pointer to buffer[idx]
        mov ecx, 0
        mov cl, [eax]                   ;ecx = 0x000000buffer[idx]
        mov byte [_char],cl             ;let char = buffer[idx]
        ;new head points to old head
        push 1
        push 5
        call calloc                     ;eax should hold pointer to newly allocated mem
        add esp, 8
        mov dword [_newHead], eax       ;eax = pointer to newHead
        mov cl, [_char]                 ;cl = currValue
        mov edx, [_newHead]
        mov byte[edx], cl               ;newHead.value = cl = newValue
        mov eax, [_oldHead]             ;eax = pointer to oldHead
        mov dword[edx+1],eax            ;newHead.next = eax = pntr to oldHead
        mov eax, [_newHead]             ;eax = pntr to newHead
        mov dword [_oldHead], eax       ;oldHead = newHead
        inc dword[_idx]                 ;increment buffer index 

        jmp %%whileLoop
    
    %%endWhileLoop:
        pushToStack [_newHead]
        removeTrailingZeros
        peekStack   ;for debug...
        mov eax, [_result]
        debug eax, _format_debugPush

%endmacro
;*********************************** END User Input *********************************
;*********************************** Operations *************************************
;;completed
%macro popAndPrint 0
    popFromStack                ;popped list is now in result
    mov eax, [_result]          ;eax = address of the lists head
    mov dword[_toFree1], eax    ;save the head for freeing later
    cmp eax, 0
    jz %%endPopAndPrint
    mov dword[_curr],eax        ;curr = list.head address
    push 0;
    %%pushWhileLoop:
    ;while(next not null)push value to stack (seperately push last)
    mov eax, [_curr]            ;ebx = address of curr
    mov eax, [eax]              ;ebx = 0x0curr.value //SegFault
    cmp al,9                    ;check if value reps letter decimal number
    jle %%ifNumberBase
    jmp %%ifLetterBase

    %%ifNumberBase:
        add al, 48
        jmp %%regardlessBase

    %%ifLetterBase:
        add al, 55
        jmp %%regardlessBase
    
    %%regardlessBase:
        push eax    ;eax should have zero(s) as MSB!
        mov eax, [_curr] ;eax = address of curr
        mov eax,[eax+1] ;eax = address of curr.next
        mov dword [_curr], eax ; curr points to address of curr.next
        ;;now check if next is null
        cmp eax,0 ;check if next's address is NULL
        jnz %%pushWhileLoop
        
    %%printWhileLoop:
        pop eax
        cmp eax, 0          ;check if you popper NULL
        jz %%popAndPrintEnd
        mov [_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        jmp %%printWhileLoop 
    %%popAndPrintEnd:
        mov al, 10
        mov byte[_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        ;now free the popped list
        freeOne
    %%endPopAndPrint:
%endmacro

%macro numHexaDigits 0
    popFromStack
    mov eax, [_result]
    mov dword[_toFree1], eax    ;save the head for freeing later
    cmp eax, 0
    jz %%endNumHexaDigits
    mov dword[_y],eax       ;x hold address of 1st head

    ;push new list of value 0 to opStack
    push 1
    push 5
    call calloc             ;eax should hold pointer to newly allocated mem
    add esp, 8              ;reset stack pointer after c call
    pushToStack eax         ;top of opStack holds result

    %%whileLoop: ;while(cuur != null)
        mov eax, [_y]       ;eax = address of y
        mov eax, [eax+1]    ;eax = y.next
        mov dword[_y],eax   ;y=y.next
        incTop
        cmp dword[_y],0     ;check if y is null
        jz %%endWhileLoop
        jmp %%whileLoop  
    %%endWhileLoop:
        ;now debug and free
        peekStack
        mov eax, [_result]
        debug eax, _format_debugPush
        freeOne

    %%endNumHexaDigits:           
%endmacro

;stores pointer M[ebx]+M[ecx] in eax
%macro myAdd 0
    tryDoublePop
    cmp dword[_x],0
    jz %%endOfAdd

    push 1
    push 5
    call calloc             ;eax should hold pointer to newly allocated mem
    mov dword[_curr],eax    ;curr = new link() adrs
    add esp, 8              ;reset stack pointer after c call
    pushToStack eax

    mov byte[_carry],0      ;reset the carry
    mov dword[_prev],0      ;prev init to null
    ;loop starts here
    %%whileLoop:            ;while( x != null | y != null | carry != 0)
        ;mov eax, 0
        mov eax, [_x]       ;eax holds address of x
        add eax, [_y]       ;eax holds (address of X + address of y)
        mov ebx,0
        mov bl, [_carry]
        add eax, ebx        ;eax holds ((adrs of x) + (adrs of y) + carry)
        cmp eax, 0          ;all positive so if their sum is 0 then they are individually zero
        jz %%endWhileLoop
        %%calcx:
            mov eax, [_x]   ;eax holds address of x
            cmp eax, 0      ;if x is null
            jz %%xIsNull    ;then jmp

            %%xIsNotNull:
                mov bl, [eax] ;bl holds x.val
                jmp %%calcy

            %%xIsNull:
                mov bl, 0
        %%calcy:
            mov eax, [_y]   ;eax holds address of y
            cmp eax, 0      ;if x is null
            jz %%yIsNull    ;then jmp

            %%yIsNotNull:
                mov cl, [eax] ;cl holds y.val
                jmp %%applyValues

            %%yIsNull:
                mov cl, 0

        %%applyValues:          ;bl holds x.val, cl holds y.val
             add bl, cl         ;bl holds x.val + y.val
             add bl, [_carry]   ;bl = x.val + y.val + carry
             cmp bl, 0x10
             jge %%carry

            %%dontCarry:
                mov byte[_carry],0 ;set carry to zero
                jmp %%carryOrNot

            %%carry:
                mov byte[_carry],1      ;set carry to 1
                sub bl, 0x10            ;update the value
                jmp %%carryOrNot

            %%carryOrNot:
                mov eax, [_curr]        ;eax holds address of curr
                mov byte[eax],bl        ;curr.value = bl = (x.val+y.val+carry)%0x10
                mov dword[_prev], eax   ;prev = curr
                push 1
                push 5
                call calloc             ;eax should hold pointer to newly allocated mem
                mov dword[_curr],eax    ;curr = adrs new link()
                add esp, 8              ;reset stack pointer after c call
                mov ecx, [_prev]        ;ecx = adrs of prev
                mov dword[ecx +1],eax   ;prev.next = curr
                
                ;;;now we advance x and y if they are not null
                cmp dword[_x],0         ;check if x = null
                jz %%checkAdvancey

                %%advancex:
                    mov eax, [_x]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_x],eax   ;x=x.next
                %%checkAdvancey:
                    cmp dword[_y],0     ;check if y is null
                    jz %%whileLoop
                %%advancey:
                    mov eax, [_y]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_y],eax   ;x=x.next
                    jmp %%whileLoop                
        
        %%endWhileLoop:
            ;;first free last link we dont need
            mov eax, [_curr]    ;eax = curr
            push eax
            call free
            add esp, 4          ;reset stack pointer after c call
            mov eax, [_prev]    ;eax = adrs of prev
            mov dword[eax+1],0  ;prev.next = null
            peekStack           ;for debug...
            mov eax, [_result]
            debug eax, _format_debugPush
            freeBoth
    %%endOfAdd:
%endmacro


%macro duplicate 0
    peekStack
    mov eax, [_result]
    mov dword[_x],eax
    cmp dword[_size],0
    jnz %%stackNotEmpty
    stackIsEmpty:
        popFromStack    ;just because it will print the error
        jmp %%endOfAdd
    
    %%stackNotEmpty:
    push 1
    push 5
    call calloc             ;eax should hold pointer to newly allocated mem
    mov dword[_curr],eax    ;curr = new link() adrs
    add esp, 8              ;reset stack pointer after c call
    pushToStack eax

    mov dword[_prev],0      ;prev init to null
    ;loop starts here
    %%whileLoop:            ;while( x != null)
        cmp dword[_x], 0    
        jz %%endWhileLoop
        %%calcx:
            mov eax, [_x]   ;eax holds address of x
            mov ebx, 0
            mov bl, [eax] ;bl holds x.val

            %%carryOrNot:
                mov eax, [_curr]        ;eax holds address of curr
                mov byte[eax],bl        ;curr.value = bl = x.val
                mov dword[_prev], eax   ;prev = curr
                push 1
                push 5
                call calloc             ;eax should hold pointer to newly allocated mem
                mov dword[_curr],eax    ;curr = adrs new link()
                add esp, 8              ;reset stack pointer after c call
                mov ecx, [_prev]        ;ecx = adrs of prev
                mov dword[ecx +1],eax   ;prev.next = curr
                
                ;;;now we advance x

                %%advancex:
                    mov eax, [_x]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_x],eax   ;x=x.next
                    jmp %%whileLoop
               
        
        %%endWhileLoop:
            ;;first free last link we dont need
            mov eax, [_curr]    ;eax = curr
            push eax
            call free
            add esp, 4          ;reset stack pointer after c call
            mov eax, [_prev]    ;eax = adrs of prev
            mov dword[eax+1],0  ;prev.next = null

    %%endOfAdd:
%endmacro

%macro bitwiseOr 0
    tryDoublePop
    cmp dword[_x],0
    jz %%endOfAnd

    push 1
    push 5
    call calloc             ;eax should hold pointer to newly allocated mem
    mov dword[_curr],eax    ;curr = new link() adrs
    add esp, 8              ;reset stack pointer after c call
    pushToStack eax

    mov dword[_prev],0      ;prev init to null
    ;loop starts here
    %%whileLoop:            ;while( x != null | y != null | carry != 0)
        ;mov eax, 0
        mov eax, [_x]       ;eax holds address of x
        add eax, [_y]       ;eax holds (address of X + address of y)
        cmp eax, 0          ;all positive so if their sum is 0 then they are individually zero
        jz %%endWhileLoop
        %%calcx:
            mov eax, [_x]   ;eax holds address of x
            cmp eax, 0      ;if x is null
            jz %%xIsNull    ;then jmp

            %%xIsNotNull:
                mov bl, [eax] ;bl holds x.val
                jmp %%calcy

            %%xIsNull:
                mov bl, 0
        %%calcy:
            mov eax, [_y]   ;eax holds address of y
            cmp eax, 0      ;if x is null
            jz %%yIsNull    ;then jmp

            %%yIsNotNull:
                mov cl, [eax] ;cl holds y.val
                jmp %%applyValues

            %%yIsNull:
                mov cl, 0

        %%applyValues:              ;bl holds x.val, cl holds y.val
            or bl, cl             ;bl holds x.val & y.val
            mov eax, [_curr]        ;eax holds address of curr
            mov byte[eax],bl        ;curr.value = bl = (x.val+y.val+carry)%0x10
            mov dword[_prev], eax   ;prev = curr
            push 1
            push 5
            call calloc             ;eax should hold pointer to newly allocated mem
            mov dword[_curr],eax    ;curr = adrs new link()
            add esp, 8              ;reset stack pointer after c call
            mov ecx, [_prev]        ;ecx = adrs of prev
            mov dword[ecx +1],eax   ;prev.next = curr
            
            ;;;now we advance x and y if they are not null
            cmp dword[_x],0         ;check if x = null
            jz %%checkAdvancey
                %%advancex:
                    mov eax, [_x]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_x],eax   ;x=x.next
                %%checkAdvancey:
                    cmp dword[_y],0     ;check if y is null
                    jz %%whileLoop
                %%advancey:
                    mov eax, [_y]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_y],eax   ;x=x.next
                    jmp %%whileLoop                
        
        %%endWhileLoop:
            ;;first free last link we dont need
            mov eax, [_curr]    ;eax = curr
            push eax
            call free
            add esp, 4          ;reset stack pointer after c call
            mov eax, [_prev]    ;eax = adrs of prev
            mov dword[eax+1],0  ;prev.next = null
            peekStack           ;for debug...
            mov eax, [_result]
            debug eax, _format_debugPush
            freeBoth
    %%endOfAnd:
%endmacro

%macro bitwiseAnd 0
    tryDoublePop
    cmp dword[_x],0
    jz %%endOfAnd

    push 1
    push 5
    call calloc             ;eax should hold pointer to newly allocated mem
    mov dword[_curr],eax    ;curr = new link() adrs
    add esp, 8              ;reset stack pointer after c call
    pushToStack eax

    mov dword[_prev],0      ;prev init to null
    ;loop starts here
    %%whileLoop:            ;while( x != null | y != null | carry != 0)
        ;mov eax, 0
        mov eax, [_x]       ;eax holds address of x
        add eax, [_y]       ;eax holds (address of X + address of y)
        cmp eax, 0          ;all positive so if their sum is 0 then they are individually zero
        jz %%endWhileLoop
        %%calcx:
            mov eax, [_x]   ;eax holds address of x
            cmp eax, 0      ;if x is null
            jz %%xIsNull    ;then jmp

            %%xIsNotNull:
                mov bl, [eax] ;bl holds x.val
                jmp %%calcy

            %%xIsNull:
                mov bl, 0
        %%calcy:
            mov eax, [_y]   ;eax holds address of y
            cmp eax, 0      ;if x is null
            jz %%yIsNull    ;then jmp

            %%yIsNotNull:
                mov cl, [eax] ;cl holds y.val
                jmp %%applyValues

            %%yIsNull:
                mov cl, 0

        %%applyValues:              ;bl holds x.val, cl holds y.val
            and bl, cl             ;bl holds x.val & y.val
            mov eax, [_curr]        ;eax holds address of curr
            mov byte[eax],bl        ;curr.value = bl = (x.val+y.val+carry)%0x10
            mov dword[_prev], eax   ;prev = curr
            push 1
            push 5
            call calloc             ;eax should hold pointer to newly allocated mem
            mov dword[_curr],eax    ;curr = adrs new link()
            add esp, 8              ;reset stack pointer after c call
            mov ecx, [_prev]        ;ecx = adrs of prev
            mov dword[ecx +1],eax   ;prev.next = curr
            
            ;;;now we advance x and y if they are not null
            cmp dword[_x],0         ;check if x = null
            jz %%checkAdvancey
                %%advancex:
                    mov eax, [_x]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_x],eax   ;x=x.next
                %%checkAdvancey:
                    cmp dword[_y],0     ;check if y is null
                    jz %%whileLoop
                %%advancey:
                    mov eax, [_y]       ;eax = address of x
                    mov eax, [eax+1]    ;eax = x.next
                    mov dword[_y],eax   ;x=x.next
                    jmp %%whileLoop                
        
        %%endWhileLoop:
            ;;first free last link we dont need
            mov eax, [_curr]    ;eax = curr
            push eax
            call free
            add esp, 4          ;reset stack pointer after c call
            mov eax, [_prev]    ;eax = adrs of prev
            mov dword[eax+1],0  ;prev.next = null
            removeTrailingZeros
            peekStack           ;for debug...
            mov eax, [_result]
            debug eax, _format_debugPush
            freeBoth
    %%endOfAnd:

%endmacro

;uses x
%macro incTop 0
    peekStack
    mov eax, [_result]
    mov dword[_x],eax


    %%whileLoop: ;while(carry != 0)
        mov eax, [_x]
        add byte[eax], 1
        cmp byte[eax], 0x10
        jl %%endWhileLoop
        mov byte[eax],0

    %%advancex:
        mov eax, [_x]       ;eax = address of x
        mov eax, [eax+1]    ;eax = x.next
        cmp eax, 0          ;check if x.next = null
        jz %%addMsb
        mov dword[_x],eax   ;x=x.next
        jmp %%whileLoop
    
    %%addMsb:
        push 1
        push 5
        call calloc             ;eax should hold pointer to newly allocated mem
        add esp, 8              ;reset stack pointer after c call
        mov ebx, [_x]           ; ebx holds address of x
        mov dword[ebx+1],eax    ;x.next = eax = calloc
        mov byte[eax], 1        ;x.next.value =1
    %%endWhileLoop:
%endmacro

;*********************************** END Operations ****************************************
;*********************************** Poppin and Pushin *************************************

;attempts to pop 2 elements, first to x, then to y. also stores them in toFree1 and toFree2
;in case of failure- notifies the user, returns stack to initial state, and [_x]=0
%macro tryDoublePop 0
    popFromStack
    mov eax, [_result]
    mov dword[_x],eax       ;x hold address of 1st head
    mov dword[_toFree1],eax
    cmp eax, 0
    jz %%endTryDoublePop

    popFromStack
    mov eax, [_result]
    mov dword[_y],eax       ;y hold address of 2nd head
    mov dword[_toFree2],eax
    cmp eax, 0
    jz %%putBackX
    jmp %%endTryDoublePop

    %%putBackX:
        mov eax, [_x]
        pushToStack eax
        mov dword[_x],0

    %%endTryDoublePop:

%endmacro

;;pops top element into result register and decrements top of stack
%macro popFromStack 0
    cmp dword[_size],0
    je %%underFlow

    mov eax, [_topOfStack]      ;eax = address of top-most element
    mov eax, [eax]              ;eax = value of top-most element = address of some list's head
    mov dword[_result], eax 
    sub dword[_topOfStack], 4
    sub dword[_size],1
    debug eax, _format_debugPop
    jmp %%complete

    %%underFlow:
        mov edx, 49          ;edx = numBytes to write
        mov ecx, _underFlowMsg      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        mov dword[_result],0
    
    %%complete:

%endmacro

%macro pushToStack 1
    ;; %1 is pointer to push
    mov ecx, %1
    mov eax, [_size]
    mov ebx, [_stackCapacity]
    cmp eax, ebx
    je %%overFlow

    mov ebx, [_topOfStack]      ;ebx = address of current top element
    add ebx, 4                  ;ebx = address of first available place in op stack
    mov [_topOfStack],ebx       ;top of stack holds address of first available space
    mov eax, ecx                 ;eax = %1 = arg1 = pointer to push
    mov dword[ebx], eax         ;first available spot filled filled arg1
    add dword[_size],1
    jmp %%complete

    %%overFlow:
        freeList ecx        ;free the list if it cant be pushed
        mov edx, 30          ;edx = numBytes to write
        mov ecx, _overFlowMsg      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        mov dword[_result],0
    
    %%complete:

%endmacro


%macro peekStack 0
    mov eax, [_topOfStack]
    mov eax, [eax]
    mov dword[_result],eax
%endmacro
;****************************** END Poppin and Pushin *********************************
;*********************************** Destructors **************************************
;precondition - number/list of interest is at top of stack
%macro removeTrailingZeros 0
    peekStack
    mov eax, [_result]      ;eax = top element = address of top list head
    mov dword[_curr], eax   ;curr = adrs of list head
    mov dword[_x],eax       ;x reps last non-zero (LNZ)

    %%whileLoop: ;while(curr != null)
        ;check condition
        cmp dword[_curr],0
        jz %%endWhileLoop

        mov eax, [_curr]    ;eax = adrs of curr
        mov bl, [eax]       ;bl = curr.val
        cmp bl, 0
        jg %%updateLNZ
        jmp %%zeroOrNot

        %%updateLNZ:
            mov dword[_x], eax  ;LNZ holds address of curr
        %%zeroOrNot:
            mov ebx,[eax +1]    ;curr = curr.next
            mov dword[_curr],ebx
            jmp %%whileLoop
    %%endWhileLoop:
        mov eax, [_x]       ;eax = adrs of LNZ
        mov ebx, [eax +1]   ;ebx = adrs of first trailing zero link (or null)
        mov dword[eax+1],0  ;disconnect trailing zeros
        freeList ebx        ;free sub-list of trailing zeros
%endmacro
%macro freeStack 0
    %%whileLoop: ;while(size > 0)pop and free
        cmp dword[_size],0
        jz %%endWhileLoop
        popFromStack
        mov eax, [_result]
        freeList eax
        jmp %%whileLoop
    %%endWhileLoop:
%endmacro
%macro freeBoth 0
    mov eax, [_toFree1]  
    freeList eax        ;free second list
    mov eax, [_toFree2]
    freeList eax        ;free second list
%endmacro
%macro freeOne 0
    mov eax, [_toFree1]
    freeList eax
%endmacro
;use curr and next to free links one by one recursively
%macro freeList 1
    mov eax, %1             ;eax  holds adrs of head of list to free
    cmp eax, 0
    jz %%endWhileLoop
    mov dword[_curr],eax    ;curr holds adrs of head of list to free
    mov eax, [eax+1]        ;eax  holds adrs of head.next
    mov dword[_next],eax    ;next holds adrs of head.next

    %%whileLoop: ;while(curr != null)
        ;check condition
        cmp dword[_curr],0  ;check if curr is null
        jz %%endWhileLoop

        mov eax, [_curr]        ;eax holds adrs of curr
        mov eax, [eax+1]        ;eax holds adrs of curr.next
        mov dword[_next],eax    ;next = curr.next
        push dword[_curr]       ;push curr for free()
        call free               ;free(curr)
        add esp, 4              ;return stack pointer
        mov eax, [_next]        ;eax = adrs of next
        mov dword[_curr],eax    ;curr = next
        jmp %%whileLoop
    %%endWhileLoop:
%endmacro
;*********************************** END Destructors ***********************************

;%1 is list, %2 string format
%macro debug 2
    cmp byte[_debug],0
    jz %%endPopAndPrint
    mov eax, %1          ;eax = address of the lists head
    push eax
    
    mov edx, 7          ;edx = numBytes to write
    mov ecx, %2         ;ecx = char (buffer)
    mov ebx, 2          ;ebx = stderr
    mov eax, 4          ;eax = sys_write op code
    int 0x80            ;call the kernel to write numBytes to victim

    pop eax          ;eax = address of the lists head
    cmp eax, 0
    jz %%endPopAndPrint
    mov dword[_d_curr],eax        ;curr = list.head address
    push 0;
    %%pushWhileLoop:
        ;while(next not null)push value to stack (seperately push last)
        mov eax, [_d_curr]            ;ebx = address of curr
        mov eax, [eax]              ;ebx = 0x0curr.value //SegFault
        cmp al,9                    ;check if value reps letter decimal number
        jle %%ifNumberBase
        jmp %%ifLetterBase

    %%ifNumberBase:
        add al, 48
        jmp %%regardlessBase

    %%ifLetterBase:
        add al, 55
        jmp %%regardlessBase
    
    %%regardlessBase:
        push eax    ;eax should have zero(s) as MSB!
        mov eax, [_d_curr] ;eax = address of curr
        mov eax,[eax+1] ;eax = address of curr.next
        mov dword [_d_curr], eax ; curr points to address of curr.next
        ;;now check if next is null
        cmp eax,0 ;check if next's address is NULL
        jnz %%pushWhileLoop
        
    %%printWhileLoop:
        pop eax
        cmp eax, 0          ;check if you popper NULL
        jz %%popAndPrintEnd
        mov [_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 2          ;ebx = stderr
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
        jmp %%printWhileLoop 
    %%popAndPrintEnd:
        mov al, 10
        mov byte[_char], al
        mov edx, 1          ;edx = numBytes to write
        mov ecx, _char      ;ecx = char (buffer)
        mov ebx, 2          ;ebx = stderr
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
    %%endPopAndPrint:
%endmacro


%macro testPrint 0
        mov edx, 10          ;edx = numBytes to write
        mov ecx, _testMsg      ;ecx = char (buffer)
        mov ebx, 1          ;ebx = stdout
        mov eax, 4          ;eax = sys_write op code
        int 0x80            ;call the kernel to write numBytes to victim
%endmacro

;TODO
;%1 holds char* for capacity
%macro changeCapacity 1
    mov ecx, %1
    mov ebx, 0  ;ebx = index = 0
    mov dword[_stackCapacity],0
    %%whileLoop:
		mov edx, 0					;reset edx
		mov eax, 0
		mov al,[ecx+ebx]		    ;store the next byte from the input in al
		mov byte[_char], al			;place the next char of the sring in char
		cmp byte[_char], 0			;if the char is null or next line dont do anything
		je %%endWhileLoop
		cmp byte[_char], 10
		je %%endWhileLoop
		        
        mov eax, dword[_stackCapacity]			;put sum in eax
		mov edx, 16					;put 16 in edx - the multyplier
		mul edx						;multiply sum by 16, eax=lower part of product  edx=upper part of product
		mov dword [_stackCapacity], eax		;keep the product in capacity

		mov edx, 0					;get rid of garbage
		mov dl, byte[_char]			;get ascii val of char into char
        cmp byte[_char], 60         ;digits less than 60, letters greater than 60
        jl %%ifDigit
        jmp %%ifLetter

        %%ifDigit:
            sub dl, 48
            jmp %%regardless
            
        %%ifLetter:
            sub dl, 55
            jmp %%regardless   

        %%regardless:
            add dword[_stackCapacity], edx			;sum = sum+char, edx still holds the right value of char
            inc ebx
            jmp %%whileLoop
    %%endWhileLoop:
%endmacro

main:
    ;push ebp
    ;mov ebp, esp
    mov eax, [esp+4]    ;eax = argCount
    cmp eax, 1          ;check if ony arg is progName
    je beginning

    ;arg order progName, capacity, debug
    ;check if the debug is on
    mov ebx, [esp+8]   ;ebx = argv = char**
    mov ecx, [ebx+4]      ;ecx=2nd arg pointer
    cmp byte[ecx],'-'  ;check if 1st arg is -d debug
    jnz firstArgIsCapacity
    mov byte[_debug],1  ;set debug = true
    jmp beginning       ;if 1st arg is debug, then no cpacity is specified

    firstArgIsCapacity:
        changeCapacity ecx
        cmp dword[esp+4],3  ;if we have anoher arhs, it must be debug
        jnz beginning
        mov byte[_debug],1

    beginning:
        ;set topOfStack to hold address of stack-1
        mov eax, _operandStack
        sub eax, 4
        mov dword [_topOfStack],eax

        ;mov dword[_stackCapacity],5
        mov dword[_size],0

    runloop:
        getUserInput
        mov eax, 0
        mov al, [_inputBuffer]   ;eax = LSByte
        cmp al, 'q'
        jz endOfProgram

        cmp al, 'p'
        jz calcPrint

        cmp al, '+'
        jz calcAdd

        cmp al, 'd'
        jz calcDuplicate

        cmp al, '&'
        jz calcAnd

        cmp al, '|'
        jz calcOr

        cmp al, 'n'
        jz calcCount

        jmp receiveOperand

    calcCount:
        inc dword[_numOperations]
        numHexaDigits
        jmp runloop

    calcAnd:
        inc dword[_numOperations]
        bitwiseAnd
        jmp runloop

    calcOr:
        inc dword[_numOperations]
        bitwiseOr
        jmp runloop

    calcDuplicate:
        inc dword[_numOperations]
        duplicate
        jmp runloop

    calcPrint:
        inc dword[_numOperations]
        popAndPrint
        jmp runloop

    calcAdd:
        inc dword[_numOperations]
        myAdd
        jmp runloop

    receiveOperand:
        convertAsciiToHexa
        listify
        jmp runloop

    endOfProgram:
        freeStack
        push dword[_numOperations]
        push _hexaFormat
        call printf
        add esp, 8
        mov eax, [_numOperations] 
        

