.686P ; Pentium Pro or later
.MODEL flat, stdcall ;Use windows API calling convention
.STACK 4096 ;define a 4K stack
option casemap :none;No Upper case lower case mapping
extern AllocConsole@0: PROC
extern GetStdHandle@4: PROC
extern WriteConsoleA@20: PROC
extern GetConsoleScreenBufferInfo@8: PROC
extern FillConsoleOutputCharacterA@20:PROC
extern WriteConsoleOutputCharacterA@20:PROC
extern Sleep@4:PROC
.data
lengthofwrite dword ?;dw is half the size of dword, lolwat
consoleHandle dword ?
screenbuffer BYTE 90 dup("!"), 24 dup(90 dup("~"));from bottom of screen up, cause it made looping easy
maxRow dword 24
numberOfRows dword 25
currentBottomLine dword 24
screenBufferOffset dword 0
;this isnt used atm, but useful if we want to scale to console size
consoleInfo struct;https://msdn.microsoft.com/en-us/library/windows/desktop/ms682093(v=vs.85).aspxBYTE
	windowSize word 2 DUP(?)
	cursorPosition word 2 DUP(?)
	attritubes word ?
	window word 4 DUP(?)
	maxWindowSize word 2 DUP(?)
consoleInfo ends
consoleInfoInstance consoleInfo {}
.code
setup: push ebp
mov ebp, esp
call AllocConsole@0
push -11
call GetStdHandle@4
mov dword ptr consoleHandle, eax
push OFFSET consoleInfoInstance
push dword ptr consoleHandle
call GetConsoleScreenBufferInfo@8
predraw: 
mov screenBufferOffset, 25;numberOfRows
mov ecx, dword ptr currentBottomLine
sub dword ptr screenBufferOffset, ecx
push currentBottomLine
call drawScreen
push 100
call Sleep@4
push currentBottomLine
call getBufferElement
sub currentBottomLine, 1
jg dontresetDrawer
mov currentBottomLine, 24;maxRow
dontresetDrawer: 
jmp predraw
pop ebp
ret
getBufferElement:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	mov edx, 90
	mul edx
	add eax, OFFSET screenbuffer
	pop ebp
	ret 4
getWrittingCords:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	add eax, screenBufferOffset;maybe make this a parameter
	cmp eax, maxRow
	jle within_limit
	sub eax, numberOfRows
	within_limit: shl eax, 16;move y cord into higher byte
	pop ebp
	ret 4
moveCurrentLinePosition:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	sub eax, 1
	cmp eax, -1
	jne dontreset
	mov eax, maxRow
	dontreset:
	pop ebp
	ret 4
drawScreen:
	push ebp
	mov ebp, esp
	nextLine:
		push OFFSET lengthofwrite
			push [ebp + 8]
			call getWrittingCords
		push eax
		push 90
			push [ebp + 8]
			call getBufferElement
		push eax
		push dword ptr consoleHandle
		call WriteConsoleOutputCharacterA@20
		push [ebp + 8]
		call moveCurrentLinePosition
	mov [ebp + 8], eax
	cmp currentBottomLine, eax
	jne nextLine
	pop ebp
	ret 4
end setup