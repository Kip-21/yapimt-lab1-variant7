.386
.MODEL FLAT, STDCALL
.STACK 4096

EXTERN GetStdHandle@4:PROC
EXTERN ReadConsoleA@20:PROC
EXTERN WriteConsoleA@20:PROC
EXTERN ExitProcess@4:PROC

.DATA
prompt      DB 'Enter x in base 8 (digits 0-7, optional minus): ',0
xLabel      DB 'x (decimal) = ',0
binLabel    DB '11*x*x - 2*x + 1 (binary) = ',0
decLabel    DB '11*x*x - 2*x + 1 (decimal) = ',0
errorText   DB 'Error: invalid octal input or 32-bit overflow.',13,10,0
newLine     DB 13,10,0
inputHandle DD ?
outputHandle DD ?
readCount   DD ?
written     DD ?
inputBuffer DB 64 DUP (?)
outputBuffer DB 34 DUP (?)
textAddress DD ?
textLength  DD ?
position    DD ?
negative    DD ?
digit       DD ?
value       DD ?
x           DD ?
square      DD ?
quadratic   DD ?
linear      DD ?
partial     DD ?
result      DD ?
number      DD ?
base        DD ?
quotient    DD ?
remainder   DD ?

.CODE
; EAX points to a zero-terminated string.
PrintText PROC
    MOV textAddress, EAX
    MOV textLength, 0
countChars:
    MOV EDX, textLength
    CMP BYTE PTR [EAX+EDX], 0
    JE writeText
    INC textLength
    JMP countChars
writeText:
    PUSH 0
    PUSH OFFSET written
    PUSH textLength
    PUSH textAddress
    PUSH outputHandle
    CALL WriteConsoleA@20
    RET
PrintText ENDP

; Read and convert a signed octal integer. Result is stored in x.
ReadOctal PROC
    PUSH 0
    PUSH OFFSET readCount
    PUSH 64
    PUSH OFFSET inputBuffer
    PUSH inputHandle
    CALL ReadConsoleA@20
    TEST EAX, EAX
    JZ inputError
    CMP readCount, 2
    JB inputError
    SUB readCount, 2
    MOV EDX, readCount
    CMP inputBuffer[EDX], 13
    JNE inputError
    CMP inputBuffer[EDX+1], 10
    JNE inputError
    MOV position, 0
    MOV negative, 0
    MOV value, 0
    CMP inputBuffer[0], '-'
    JNE checkDigits
    MOV negative, 1
    INC position
checkDigits:
    MOV EDX, position
    CMP EDX, readCount
    JAE inputError
readDigit:
    MOV EDX, position
    MOVZX EAX, inputBuffer[EDX]
    CMP EAX, '0'
    JB inputError
    CMP EAX, '7'
    JA inputError
    SUB EAX, '0'
    MOV digit, EAX
    MOV EAX, value
    IMUL EAX, 8
    JO inputError
    MOV value, EAX
    ADD EAX, digit
    JO inputError
    MOV value, EAX
    INC position
    MOV EDX, position
    CMP EDX, readCount
    JB readDigit
    CMP negative, 0
    JE storeX
    NEG value
storeX:
    MOV EAX, value
    MOV x, EAX
    RET
ReadOctal ENDP

; Convert number to base 2 or 10, filling the buffer from right to left.
PrintNumber PROC
    MOV position, 33
    MOV outputBuffer[33], 0
    MOV negative, 0
    MOV EAX, number
    CMP EAX, 0
    JGE magnitudeReady
    MOV negative, 1
    NEG EAX
magnitudeReady:
    MOV quotient, EAX
nextDigit:
    MOV EAX, quotient
    XOR EDX, EDX
    DIV base
    MOV quotient, EAX
    MOV remainder, EDX
    ADD EDX, '0'
    DEC position
    MOV ECX, position
    MOV outputBuffer[ECX], DL
    CMP quotient, 0
    JNE nextDigit
    CMP negative, 0
    JE printDigits
    DEC position
    MOV ECX, position
    MOV outputBuffer[ECX], '-'
printDigits:
    MOV EAX, OFFSET outputBuffer
    ADD EAX, position
    CALL PrintText
    MOV EAX, OFFSET newLine
    CALL PrintText
    RET
PrintNumber ENDP

MAIN PROC
    PUSH -10
    CALL GetStdHandle@4
    MOV inputHandle, EAX
    PUSH -11
    CALL GetStdHandle@4
    MOV outputHandle, EAX
    MOV EAX, OFFSET prompt
    CALL PrintText
    CALL ReadOctal

    MOV EAX, OFFSET xLabel
    CALL PrintText
    MOV EAX, x
    MOV number, EAX
    MOV base, 10
    CALL PrintNumber

    ; Store every intermediate value of 11*x*x - 2*x + 1.
    MOV EAX, x
    IMUL EAX, x
    JO inputError
    MOV square, EAX
    IMUL EAX, 11
    JO inputError
    MOV quadratic, EAX
    MOV EAX, x
    IMUL EAX, -2
    JO inputError
    MOV linear, EAX
    ADD EAX, quadratic
    JO inputError
    MOV partial, EAX
    ADD EAX, 1
    JO inputError
    MOV result, EAX

    MOV EAX, OFFSET binLabel
    CALL PrintText
    MOV EAX, result
    MOV number, EAX
    MOV base, 2
    CALL PrintNumber
    MOV EAX, OFFSET decLabel
    CALL PrintText
    MOV EAX, result
    MOV number, EAX
    MOV base, 10
    CALL PrintNumber
    PUSH 0
    CALL ExitProcess@4
MAIN ENDP

inputError:
    MOV EAX, OFFSET errorText
    CALL PrintText
    PUSH 1
    CALL ExitProcess@4
END MAIN
