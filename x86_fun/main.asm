.686P ; Pentium Pro or later
.MODEL flat, stdcall ;Use windows API calling convention
.STACK 4096 ;define a 4K stack
option casemap :none;No Upper case lower case mapping
;extern CryptGenRandom@12: PROC
;extern CryptAcquireContextA@20: PROC
extern AllocConsole@0: PROC
extern GetStdHandle@4: PROC
extern WriteConsoleA@20: PROC
extern GetConsoleScreenBufferInfo@8: PROC
extern FillConsoleOutputCharacterA@20:PROC
extern WriteConsoleOutputCharacterA@20:PROC
extern LoadLibraryA@4:PROC
extern GetProcAddress@8:PROC
extern GetNumberOfConsoleInputEvents@8:PROC
extern ReadConsoleInputA@16:PROC
;includelib msvcrt.lib
extern Sleep@4:PROC
;extern rand: PROC
extern FlushConsoleInputBuffer@4:PROC
extern ReadConsoleA@20:PROC
extern ReadConsoleOutputCharacterA@20:PROC
extern MessageBoxA@16:PROC
.data
lengthofwrite dword ?;dw is half the size of dword, lolwat
consoleHandle dword ?
screenbuffer BYTE 25 dup(88 dup(" "));from bottom of screen up, cause it made looping easy
maxRow dword 24
numberOfRows dword 25
currentBottomLine dword 24
screenBufferOffset dword 0
;for crypto lib
cryptoServiceProvider dword ?
dllToLoad BYTE "msvcrt.dll",0
dllAddress DWORD ?
randName BYTE "rand",0
srandName BYTE "srand",0
randAddress dword ?
srandAddress dword ?
;this isnt used atm, but useful if we want to scale to console size
consoleInfo struct;https://msdn.microsoft.com/en-us/library/windows/desktop/ms682093(v=vs.85).aspx
	windowSize word 2 DUP(?)
	cursorPosition word 2 DUP(?)
	attritubes word ?
	window word 4 DUP(?)
	maxWindowSize word 2 DUP(?)
consoleInfo ends
consoleInfoInstance consoleInfo {}
inputRecord struct
	eventType word ?
	bKeyDown dword ?
	wRepeatCount WORD ?
	wVirtualKeyCode WORD ?
	wVirtualScanCode WORD ? 
	AsciiChar byte ?
	dwControlKeyState DWORD ? 
	extraspace byte 50 dup(?);hack incase I fuck up the type
inputRecord ends
inputRecordInstances inputRecord {}
;for character
characterX dword 20
characterImage BYTE "#"
unreadInputCount DWORD ?
unreadInput BYTE 50 DUP(?)
consoleInputHandle dword ?
readInputCount dword ?
thingAtCharacterPos dword ?
deathText byte "You hit a wall",0
.code
setup: push ebp
mov ebp, esp
call loadAndSeed
call AllocConsole@0
push -11
call GetStdHandle@4
mov dword ptr consoleHandle, eax
push OFFSET consoleInfoInstance
push dword ptr consoleHandle
call GetConsoleScreenBufferInfo@8
push -10
call GetStdHandle@4
mov dword ptr consoleInputHandle, eax
predraw: 
mov screenBufferOffset, 25;numberOfRows
mov ecx, dword ptr currentBottomLine
sub dword ptr screenBufferOffset, ecx
push currentBottomLine
call takeUserInput
call drawScreen
call takeUserInput
call checkForDeath
call takeUserInput
call drawCharacter
;consider looping through this twice to make user "faster"
call takeUserInput
push 100
call Sleep@4
push currentBottomLine
call makeNewLine
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
	mov edx, 88
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
		push 88
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
loadAndSeed:
	push ebp
	mov ebp, esp
	push OFFSET dllToLoad
	call LoadLibraryA@4
	mov dllAddress, eax
	push OFFSET randName
	push dllAddress
	call GetProcAddress@8
	mov randAddress, eax
	push OFFSET srandName
	push dllAddress
	call GetProcAddress@8
	mov srandAddress, eax
	;push 2;I swear srand is supposed to take a seed param? https://msdn.microsoft.com/en-us/library/aa272944(v=vs.60).aspx
	call eax
	pop ebp
	ret
getRandom:
	push ebp
	mov ebp, esp
	mov eax, randAddress
	call eax
	pop ebp
	ret
mapToAscii:
	push ebp
	mov ebp, esp
	call getRandom
	sub eax, 27000;I have no idea how the result of rand is working (i.e what the upper bound is)
	jg block
	mov eax, "    "
	jmp skipblock
	block:
		mov eax, "----"
	skipblock:
		pop ebp
	ret
makeNewLine:
	push ebp
	mov ebp, esp
	call getRandom
	cmp eax, 4000;I have no idea how the result of rand is working (i.e what the upper bound is)
	jg nonewline
	push [ebp + 8]
	call getBufferElement
	mov ebx, eax
	mov ecx, -1
	writeOnLine: add ecx, 1
		push ebx;not a parameter, just so mapToAscii doesnt wipe it
		push ecx
		call mapToAscii
		pop ecx
		pop ebx
		mov [ebx + ecx*4], eax
		cmp ecx, 21;88/4 - 4 (line length / dword size)
		jne writeOnLine
	nonewline: pop ebp
	ret 4
drawCharacter:
	push ebp
	mov ebp, esp
		push OFFSET lengthofwrite
		mov eax, 24;y cord
		shl eax, 16
		or ax, word ptr characterX;x cord
		push eax
		push 1
		push OFFSET characterImage
		push dword ptr consoleHandle
		call WriteConsoleOutputCharacterA@20
	pop ebp
	ret
takeUserInput:
	push ebp
	mov ebp, esp
	push OFFSET unreadInputCount
	push consoleInputHandle
	call GetNumberOfConsoleInputEvents@8
	cmp unreadInputCount, 0
	je charactermoveDone
	push OFFSET readInputCount
	push 1
	push OFFSET inputRecordInstances
	push consoleInputHandle
	call ReadConsoleInputA@16
	cmp inputRecordInstances.eventType, 1
	jne charactermoveDone
	cmp inputRecordInstances.bKeyDown, 0
	je charactermoveDone
	;+2 is a hack because I've obviously got my reocrd struct wrong
	cmp word ptr [inputRecordInstances.wVirtualKeyCode + 2], 37;0x25
	jne checkRight
	sub characterX, 1
	jmp charactermoveDone
	checkRight: 
	cmp word ptr [inputRecordInstances.wVirtualKeyCode + 2], 39;0x27
	jne charactermoveDone
	add characterX, 1
	charactermoveDone:
	push consoleInputHandle
	call FlushConsoleInputBuffer@4
	pop ebp
	ret
checkForDeath:
	push ebp
	mov ebp, esp
		push OFFSET lengthofwrite
		mov eax, 24;y cord
		shl eax, 16
		or ax, word ptr characterX;x cord
		push eax
		push 1
		push OFFSET thingAtCharacterPos
		push dword ptr consoleHandle
	call ReadConsoleOutputCharacterA@20
	cmp thingAtCharacterPos, "-"
	jne alive
	push 0
	push OFFSET deathText
	push OFFSET deathText
	push 0
	call MessageBoxA@16
	alive: pop ebp
	ret
end setup