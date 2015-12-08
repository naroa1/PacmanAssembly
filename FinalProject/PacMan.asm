INCLUDE Irvine32.inc
.data
	BoardStart db 28 DUP(31 DUP(1))	;Blank map before being written to
	Splash db 76 DUP(6 DUP (1))

	InputFile db "Pacman Map.txt", 0		;Name of the file, needs to go in the same folder as the project solution (Irvine/Examples/Project_Sample). Can change location later
	InputSplash db "SplashScreen.txt", 0
	MapFileHandle dd 0						;The file handle variable before being set
	SplashFileHandle dd 0
	BufferSize = 1000						;The max number of bytes to read, the actual number is a bit over 900
	FileOutputBuffer db BufferSize DUP(?)	;The buffer array where the contents of the file are read
	BytesRead dd 0							;After reading, the number of actual bytes read

	counter db 0							;Counter for drawing the map of the board
	WallPiece db 178						;Placeholder ascii values for each potential position on the board
	PelletPiece db 248						;These can be changed later on
	PowerPelletPiece db 15					;
	Teleport1Piece db 174					;
	Teleport2Piece db 175					;
	FruitPiece db 234						;

	Bar db 124
	UnderScore db 95						
	FSlash db 92
	BSlash db 47
	CParen db 41
	OParen db 40
	apost db 45
	period db 46

	char BYTE ?
	w BYTE "w"
	a BYTE "a"
	s BYTE "s"
	d BYTE "d"
	r BYTE "r"
	printScore BYTE "Score: ",0
	printTotal BYTE "Total: ",0
	printSteps BYTE "Steps: ",0
	printRound BYTE "Round: ",0
	loseMessage BYTE "You have lost. Try better next time. Your final score was a pitiful ",0		;Victory and defeat messages.
	winMessage1 BYTE "You have won that round. Your score was: ",0
	winMessage2 BYTE "You have won the game. Your final score was: ",0
	continueMessage BYTE "Press any key to continue",0

	xCor DB 17
	yCor DB 13

	RoundNumber DB 1
	CurrentLoc DW 489
	NextLoc DW 489
	theOk DB 0
	score DD 0
	totalScore DD 0
	steps DD 60				;Some new variables. Steps is the default step counter.
	FruitThreshhold DD 10	;This is used for the semi-random fruit spawning.
	FruitSpawnLoc1 DD 401
	FruitSpawnLoc2 DD 410	;The locations of the fruit spawns, in terms of the array.
	AlternateSpawnLoc db 1	;Used to alternate between the two spawn locations.
	gameOver DB 0
	gameWon DB 0		;Game victory and loss variables.

	rulesMain BYTE "Game Rules:",0
	rulesMove BYTE "Use W, A, S, and D to control PACMAN.",0
	rulesReset BYTE "Press R to reset the game.",0
	rulesSteps1 BYTE "When you move to a blank space, you lose 1 step.",0
	rulesSteps2 BYTE "If your step counter reaches 0, you lose.",0
	rulesWin1 BYTE "If you eat every pellet, you win the round.",0
	rulesWin2 BYTE "There are 3 rounds, with the difficulty going up.",0
	rulesWin3 BYTE "If you complete all 3 rounds, you win the game.",0
.code
main PROC
	Call Randomize		;Called at the start of the program once to randomize things.
	mov eax, 0
	mov ebx, 0

	Call openSplashFile
	mov eax, splashFileHandle
	Call ReadSplash
	Call ShowSplash

	mov dh, 10
	mov dl, 10
	call gotoXY
	mov edx, offset continueMessage
	call writeString
	StillWaiting:
		mov eax, 100; sets the delay to a 100ms delay
		call Delay; creates delay
		call readKey; reads immediate keyboard input
		jz StillWaiting

	Call OpenMapFile				;These 4 lines call their respective procedures for getting the map from the file into the array BoardStart
	mov eax, MapFileHandle			;This line and the previous one open the file and put the handle into eax
	Call ReadDefaultMap				;Read the contents of the array from the opened file into the array FileOutputBuffer
	Call ResetGameState		;This is its own procedure so that you can reset back to this position.

	exit
main ENDP

ShowSplash Proc
Call resetVariables
Call WriteSplashToArray
Call GenerateSplash
Call DrawSplash
RET
ShowSplash ENDP

ResetGameState PROC
	Call clrscr
	Call resetVariables		;Resets all of the variables to default when resetting the game.
	Call WriteMapToArray			;Copies the array from FileOutputBuffer into BoardStart
	Call DrawMap					;Changes the values from 1, 2, 3 etc into the correct ascii values for the symbols we want drawn

	mov eax, 0
	mov ebx, 0
	mov ecx, lengthof BoardStart		;Everything else is a loop to draw the board onscreen once the file reading is done
	PrintLoop:
		mov al, BoardStart[ebx]
		call drawColor
		call writeChar
		add counter, 1
		add ebx, 1
		cmp counter, 28		;This value is the "x" dimension of the array to be drawn
		je nextLine
		Loop PrintLoop
		jmp endPrintLoop
	nextLine:
		Call crlf
		mov counter, 0
		Loop PrintLoop

	endPrintLoop:
	Call drawRules

	call moveIt
	ret
ResetGameState endp

drawColor proc
	CMP al, wallPiece
	jne checkIfPellet
	mov eax, lightBlue
	call setTextColor
	mov al, wallPiece
	jmp theEnd

	checkIfPellet:
		CMP al, pelletPiece
		jne checkIfPPellet
		mov eax, lightGray
		call setTextColor
		mov al, pelletPiece
		jmp theEnd

	checkIfPPellet:
		CMP al, powerPelletPiece
		jne checkIfTeleport
		mov eax, brown
		call setTextColor
		mov al, powerPelletPiece

	checkIfTeleport:
		CMP al, Teleport1Piece
		jne checkOtherTP
		mov eax, lightGreen
		call setTextColor
		mov al, Teleport1Piece
		jmp theEnd
		checkOtherTP:
			CMP al, Teleport2Piece
			jne theEnd
			mov eax, lightGreen
			call setTextColor
			mov al, Teleport2Piece
	theEnd:
		RET
drawColor ENDP

ResetVariables PROC		;Resets all of the game variables to defaults.
	mov xCor, 17
	mov yCor, 13
	mov CurrentLoc, 489
	mov NextLoc, 489
	mov theOk, 0
	mov score, 0
	mov steps, 50
	mov FruitThreshhold, 10
	mov FruitSpawnLoc1, 401
	mov FruitSpawnLoc2, 410
	mov AlternateSpawnLoc, 1
	mov gameOver, 0
	mov gameWon, 0
	ret
ResetVariables endp

DrawRules PROC
	mov eax, lightGray
	Call setTextColor

	mov dh, 3
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesMain
	Call writestring

	mov dh, 4
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesMove
	Call writestring

	mov dh, 5
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesReset
	Call writestring

	mov dh, 6
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesSteps1
	Call writestring

	mov dh, 7
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesSteps2
	Call writestring

	mov dh, 8
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesWin1
	Call writestring

	mov dh, 9
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesWin2
	Call writestring

	mov dh, 10
	mov dl, 30
	Call gotoXY
	mov edx, offset rulesWin3
	Call writestring
	ret
DrawRules endp

OpenSplashFile PROC
	mov edx, offset InputSplash		;Put the name of the file into edx
	Call OpenInputFile					;Call the open procedure. If the file opens correctly, a handle value will be generated and put into eax
	cmp eax, INVALID_HANDLE_VALUE		;If the file fails to open, eax will contain the preset constant INVALID_HANDLE_VALUE. Check against that value to see if the file opened correctly
	jz FileOpenFailed
	mov SplashFileHandle, eax				;Assuming the file opened correctly, puts the generated handle value into a variable
	ret
	FileOpenFailed:		;If the file did not open correctly, you can put an error message or something here
	RET
OpenSplashFile ENDP

ReadSplash proc
	mov edx, offset FileOutputBuffer	;Prepare the buffer for input
	mov ecx, 1000						;This is the max number of bytes to read from the file. The read pointer will remain at this point to continue of the procedure is called again.
	Call ReadFromFile					;Call the ReadFromFile procedure. If the read is successful, then the buffer array will contain the contents of the file, and eax will contain the number of bytes read
	jc ReadFailed				;If the carry flag is set, then there is an error
	jnc ReadSuccess				;Otherwise, continue
	ReadFailed:
	Call WriteWindowsMsg		;This will write the most recent error in plaintext for you
	ret
	ReadSuccess:
	mov BytesRead, eax			;Assuming the read works, move the number of bytes read, stored in eax, into a variable
	RET
ReadSplash ENDP

WriteSplashToArray PROC
	mov edx, 0					;A simple loop procedure to put the new contents of FileOutputBuffer into BoardStart
	mov ecx, BytesRead
	FillLoop:
		mov al, FileOutputBuffer[edx]
		sub al, 48	;The readFromFile procedure gets ascii values, where 1 = 49, 2 = 50, etc, so I subtracted 48 from the number to get the actual value
		mov Splash[edx], al
		add edx, 1
		Loop FillLoop
	ret
WriteSplashToArray endp

GenerateSplash PROC
	mov edx, 0
	mov ecx, lengthof Splash	;Another simple loop to replace each entry in the array with the ascii value corresponding to that position on the board.
	ChangeLoop:
		mov al, Splash[edx]
		cmp al, 1
		je Change1
		cmp al, 2
		je Change2
		cmp al, 3
		je Change3
		cmp al, 4
		je Change4
		cmp al, 5
		je Change5
		cmp al, 6
		je Change6
		cmp al, 7
		je Change7
		cmp al, 8
		je Change9
		cmp al, 9
		je Change9
		endChange: ; modify loop to check to see what is being placed for making color
			mov Splash[edx], al
			add edx, 1
		Loop ChangeLoop
		ret

	Change1:
		mov al, Bar
		jmp endChange
	Change2:
		mov al, UnderScore
		jmp endChange
	Change3:
		mov al, FSlash
		jmp endChange
	Change4:
		mov al, BSlash
		jmp endChange
	Change5:
		mov al, CParen
		jmp endChange
	Change6:
		mov al, OParen
		jmp endChange
	Change7:
		mov al, Apost
		jmp endChange
	Change8:
		mov al, period
		jmp endChange
	Change9:
		mov al, 0
		jmp endChange
	ret
GenerateSplash endp

DrawSplash Proc
	mov eax, 0
	mov ebx, 0
	mov ecx, lengthof Splash		;Everything else is a loop to draw the board onscreen once the file reading is done
	PrintLoop:
		mov al, Splash[ebx]
		call drawColor
		call writeChar
		add counter, 1
		add ebx, 1
		cmp counter, 76	;This value is the "x" dimension of the array to be drawn
		je nextLine
		Loop PrintLoop
		jmp endPrintLoop
	nextLine:
		Call crlf
		mov counter, 0
		Loop PrintLoop

	endPrintLoop:
RET
DrawSplash ENDP

OpenMapFile PROC
	mov edx, offset InputFile			;Put the name of the file into edx
	Call OpenInputFile					;Call the open procedure. If the file opens correctly, a handle value will be generated and put into eax
	cmp eax, INVALID_HANDLE_VALUE		;If the file fails to open, eax will contain the preset constant INVALID_HANDLE_VALUE. Check against that value to see if the file opened correctly
	jz FileOpenFailed
	mov MapFileHandle, eax				;Assuming the file opened correctly, puts the generated handle value into a variable
	ret
	FileOpenFailed:		;If the file did not open correctly, you can put an error message or something here
	ret
OpenMapFile endp

ReadDefaultMap PROC
	mov edx, offset FileOutputBuffer	;Prepare the buffer for input
	mov ecx, 1000						;This is the max number of bytes to read from the file. The read pointer will remain at this point to continue of the procedure is called again.
	Call ReadFromFile					;Call the ReadFromFile procedure. If the read is successful, then the buffer array will contain the contents of the file, and eax will contain the number of bytes read
	jc ReadFailed				;If the carry flag is set, then there is an error
	jnc ReadSuccess				;Otherwise, continue
	ReadFailed:
	Call WriteWindowsMsg		;This will write the most recent error in plaintext for you
	ret
	ReadSuccess:
	mov BytesRead, eax			;Assuming the read works, move the number of bytes read, stored in eax, into a variable
	ret
ReadDefaultMap endp

WriteMapToArray PROC
	mov edx, 0					;A simple loop procedure to put the new contents of FileOutputBuffer into BoardStart
	mov ecx, BytesRead
	FillLoop:
		mov al, FileOutputBuffer[edx]
		sub al, 48	;The readFromFile procedure gets ascii values, where 1 = 49, 2 = 50, etc, so I subtracted 48 from the number to get the actual value
		mov BoardStart[edx], al
		add edx, 1
		Loop FillLoop
	ret
WriteMapToArray endp

DrawMap PROC
	mov edx, 0
	mov ecx, lengthof BoardStart	;Another simple loop to replace each entry in the array with the ascii value corresponding to that position on the board.
	ChangeLoop:
		mov al, BoardStart[edx]
		cmp al, 1
		je Change1
		cmp al, 2
		je Change2
		cmp al, 3
		je Change3
		cmp al, 4
		je Change4
		cmp al, 5
		je Change5
		cmp al, 6
		je Change6
		endChange: ; modify loop to check to see what is being placed for making color
			mov BoardStart[edx], al
			add edx, 1
		Loop ChangeLoop
		ret

	Change1:
		mov al, WallPiece
		jmp endChange
	Change2:
		mov al, PelletPiece
		jmp endChange
	Change3:
		mov al, PowerPelletPiece
		jmp endChange
	Change4:
		mov al, Teleport1Piece
		jmp endChange
	Change5:
		mov al, Teleport2Piece
		jmp endChange
	Change6:
		mov al, 0
		jmp endChange
	ret
DrawMap endp

setDifficultyLevel PROC
	cmp roundNumber, 1
	je Round1
	cmp roundNumber, 2
	je Round2
	cmp roundNumber, 3
	je Round3
	Round1:
		mov steps, 60
		jmp endDiff
	Round2:
		mov steps, 50
		jmp endDiff
	Round3:
		mov steps, 40
	endDiff:
	ret
setDifficultyLevel endp

moveIt proc
	mov edx, 0
	mov eax, Yellow
	call setTextColor

	Call setDifficultyLevel

	theMove:
		Call printTheScore
		Call printStepCounter			;The game will show the score and step counter at the start of each move, and will also call the checkGameWon procedure.
		Call checkGameWon		;See this procedure for more information
		cmp gameOver, 1
		je EndGame		;2 new variables, gameOver = 1 will lead to the end screen, gameWon = 1 will lead to the victory screen
		cmp gameWon, 1
		je Victory
		mov dh, xCor; row info
		mov dl, yCor; column info
		call gotoXY
		mov al, 2; an ascii symbol.
		call writeChar; prints ascii symbol
		call gotoXY

	StillWaiting:
		mov eax, 100; sets the delay to a 100ms delay
		call Delay; creates delay
		call readKey; reads immediate keyboard input
		jz StillWaiting
		mov char, al
		mov eax, 0
		mov al, char
		CMP al, w
		je Up
		CMP al, s
		je down
		CMP al, a
		je left
		CMP al, d
		je right
		CMP al, r		;Check to see if the R button is pressed, to reset the game.
		je Reset
		jmp theMove; makes sure that any mis input won’t make the cursor move up

	up:
		sub nextLoc, 28
		call checkPerm
		cmp theOk, 1
		;movzx eax, theOK
		;call writeInt
		jne theMove
		call drawBlank
		dec Xcor
		jmp theMove

	down:
		add nextLoc, 28
		call checkPerm
		cmp theOk, 1
		jne theMove
		call drawBlank
		inc Xcor
		jmp theMove

	left:
		dec nextLoc
		call checkPerm
		cmp theOk, 1
		jne theMove
		call drawBlank
		dec yCor
		jmp theMove

	right:
		inc nextLoc
		call checkPerm
		cmp theOk, 1
		jne theMove
		call drawBlank
		inc yCor
		jmp theMove

	Reset:
		mov dx, 0		;When R is pressed, the cursor is set to 0,0 to redraw the board, and the text color is set to the console's default lightGray color.
		Call gotoXY
		mov eax, lightblue
		Call SetTextColor
		mov roundNumber, 1
		mov totalScore, 0
		Call resetGameState	;Then, the game resets back to the start, printing the board again.

	endGame:
		call clrscr
		mov edx, offset loseMessage	;Prints the lose message, from the .data section, and then the score.
		Call writeString
		mov eax, totalScore
		Call writeDec
		Call crlf
		mov eax, 5000
		call delay
		RET
	
	Victory:
		cmp roundNumber, 3
		jl nextRound
		jge finalVictory
		nextRound:
			call clrscr
			mov edx, offset WinMessage1	;Prints the win message, from the .data section, and then the score.
			Call writeString
			mov eax, score
			Call writeDec
			Call crlf
			mov eax, 5000
			call delay
			add roundNumber, 1
			Call resetGameState
			RET
		finalVictory:
			call clrscr
			mov edx, offset WinMessage2	;Prints the win message, from the .data section, and then the score.
			Call writeString
			mov eax, totalScore
			Call writeDec
			Call crlf
			mov eax, 5000
			call delay
	RET
moveIt ENDP

drawBlank proc
	mov al, 32
	call writeChar
	call gotoXY
	RET
drawBlank ENDP

printStepCounter PROC
	call DrawBlank
	mov dh, 31				;Functions the same as the printScore procedure, but prints the steps at the bottom right corner.
	mov dl, 19
	Call gotoXY
	mov edx, offset printSteps
	Call writeString
	mov dh, 31
	mov dl, 26
	Call gotoXY
	mov eax, 0
	mov eax, steps
	Call writeDec
	ret
printStepCounter endp

printTheScore proc
	call drawBlank
	mov dh, 31
	mov dl, 0
	call gotoXY
	mov edx, offset printScore
	call writeString
	mov dh, 31
	mov dl, 7
	call gotoXY
	mov eax, 0
	mov eax, score
	call writeDec

	call drawBlank
	mov dh, 32
	mov dl, 0
	call gotoXY
	mov edx, offset printTotal
	call writeString
	mov dh, 32
	mov dl, 7
	call gotoXY
	mov eax, 0
	mov eax, totalScore
	call writeDec

	call drawBlank
	mov dh, 32
	mov dl, 19
	call gotoXY
	mov edx, offset printRound
	call writeString
	mov dh, 32
	mov dl, 26
	call gotoXY
	mov eax, 0
	mov al, roundNumber
	call writeDec
	RET
printTheScore endP

randomFruitSpawn PROC
	mov eax, 0
	mov eax, score				;This is a bit complicated, but basically it calls a random number between 1 and the current score.
	Call randomRange				;If this number is greater than the current FruitThreshhold, a fruit is spawned, alternating between the two possible locations.
	cmp eax, FruitThreshhold			
	jge SpawnFruit
	jl NoFruit
	SpawnFruit:
		add FruitThreshhold, 35		;Whenever a fruit is spawned, the threshhold increases, so that as the game goes on the odds of a fruit spawning is variable.
		cmp AlternateSpawnLoc, 1
		je Loc1
		jne Loc2
		Loc1:
			mov ebx, FruitSpawnLoc1
			mov boardStart[ebx], 234
			mov AlternateSpawnLoc, 2
			mov dh, 14
			mov dl, 9
			call gotoXY				;Places the fruit at the spawn location, swaps the spawn location for the next fruit, then moves the cursor back to the current location.
			mov eax, lightRed
			call setTextColor
			mov al, fruitPiece
			Call writeChar
			mov dh, xCor
			mov dl, yCor
			Call gotoXY
			mov eax, yellow
			call setTextColor
			ret
		Loc2:
			mov ebx, FruitSpawnLoc2		;Same as above.
			mov boardStart[ebx], 234
			mov AlternateSpawnLoc, 1
			mov dh, 14
			mov dl, 18
			call gotoXY
			mov eax, lightRed
			call setTextColor
			mov al, fruitPiece
			Call writeChar
			mov dh, xCor
			mov dl, yCor
			Call gotoXY
			mov eax, yellow
			call setTextColor
			ret
	NoFruit:
		
	ret
randomFruitSpawn endp

checkGameWon PROC
	mov ebx, 0
	mov ecx, lengthof BoardStart
	checkerLoop:
		cmp BoardStart[ebx], 248		;Iterates through the board, checking to see if there are any remaining pellets or power pellets.
		je notEmpty
		cmp BoardStart[ebx], 15
		je notEmpty				;If there are any pellets or power pellets, the loop breaks.
		add ebx, 1
		Loop checkerLoop
								;If the loop reaches its end without breaking, there are no remaining pellets or power pellets on the board, and the gamestate is set to "won"
	mov GameWon, 1
	notEmpty:
		
	ret
checkGameWon endp

checkPerm proc
	movzx ebx, nextLoc
	movzx eax, BoardStart[ebx]
	CMP eax, 178
	jz noStopIt
	jnz checkPellet

	noStopIt:
		movzx eax, currentLoc; sets ax to the current location of pacman
		mov nextLoc, ax; sets it so after the move he is in the same spot
		mov theOk, 0
		RET

	checkPellet:
		CMP eax, 248; compares the location to the pellet value
		jnz checkPPellet; not pellet? try power pellet
		inc score; score +1
		inc totalScore
		mov BoardStart[ebx], 0;Clear the array value storing the pellet so that continuosly walking over a blank spot incs score
		mov currentLoc, bx
		mov theOk, 1; makes the move OK
		call printTheScore; prints score on bottom right
		call printStepCounter
		Call randomFruitSpawn
		RET

	checkPPellet:
		CMP eax, 15; comapres the location to power pellet value
		jnz checkFruit; not pp? check if it's a fruit
		add score, 5; Woohoo 5 points
		add totalScore, 5
		add steps, 10			;Add 10 to the step counter as well, as a bonus
		mov BoardStart[ebx], 0	;Clear the array value storing the pellet so that continuosly walking over a blank spot incs score
		mov currentLoc, bx
		mov theOk, 1; makes the move OK
		call printTheScore; prints score on bottom right
		call printStepCounter
		Call randomFruitSpawn
		RET

	checkFruit:
		CMP eax, 234
		jnz checkLeftTeleport ;Not a fruit, check if it's one of the teleporters
		add score, 20		;If it's a fruit, add 20 points, but don't change the step counter
		add totalScore, 20
		mov BoardStart[ebx], 0
		mov currentLoc, bx
		mov theOk, 1
		call printTheScore
		call printStepCounter
		Call randomFruitSpawn
		RET

	checkLeftTeleport:
		CMP eax, 174
		jnz checkRightTeleport	;If not this teleporter, check if it's the other one
		mov currentLoc, 418
		mov nextLoc, 418	;Mov the current and next location to be the exit of the opposite side's teleporter
		mov theOk, 1
		mov xCor, 14	;Change the x and y coordinates to match.
		mov yCor, 27
		call printTheScore
		call printStepCounter
		Call randomFruitSpawn
		RET

	checkRightTeleport:
		CMP eax, 175
		jnz theEnd	;If not a pellet, power pellet, fruit, or teleporter, it's blank, so jump to the end
		mov currentLoc, 393
		mov nextLoc, 393	;Mov the current and next location to be the exit of the opposite side's teleporter
		mov theOk, 1
		mov xCor, 14	;Change x and y to match
		mov yCor, 0
		call printTheScore
		call printStepCounter
		Call randomFruitSpawn
		RET
		
	theEnd:
		mov theOk, 1
		sub steps, 1	;Decrease the steps by 1 whenever you move into a blank space.
		cmp steps, 0	;Check to see if the step counter is empty. If it is, you've lost
		jz YouLose
		mov currentLoc, bx
		call printStepCounter
		RET
	YouLose:
		mov gameOver, 1	;Set the gamestate to a loss, then go back to theMove to see the lose message.
		RET
checkPerm ENDP
END main