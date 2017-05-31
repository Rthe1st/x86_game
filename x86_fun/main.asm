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
screenbuffer BYTE 90 dup("!"), 54 dup(90 dup("~"));from bottom of screen up, cause it made looping easy
currentBottomLine dword 54
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
mov eax, dword ptr currentBottomLine
mov screenBufferOffset, 54
mov ecx, dword ptr currentBottomLine
sub dword ptr screenBufferOffset, ecx
draweert:
push eax
mov ecx, eax
push eax
call getBufferElement
push OFFSET lengthofwrite
add ecx, screenBufferOffset
cmp ecx, 54
jle blah
sub ecx, 54
blah: shl ecx, 16;move y cord into higher byte
push ecx
xor ebx, ebx
mov bx, 90
push ebx
push eax
push dword ptr consoleHandle
call WriteConsoleOutputCharacterA@20
pop eax
sub eax, 1
cmp eax, -1
jne checkAgainstBottomLine
mov eax, 54
push eax
push 100
call Sleep@4
pop eax
checkAgainstBottomLine:
cmp currentBottomLine, eax
jne draweert
sub currentBottomLine, 1
jle resetDrawer
jmp predraw
resetDrawer: mov currentBottomLine, 54
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

end setup