;Roey Amitay
.model small
.stack 100h
	row EQU -160
	middle EQU 2000
.data
;initial variables for the program:
	game_board db ' ', 80 dup('$') ;variable for game board
	line_down db 0Ah,0Dh,'$' ;variable to print line down
	location dw 2000 ;variable to save the location of the player
	line db 160 ;variable that saves the length of a line
	points db 0 ;variable for the number of points the player gained
	direction db -1d ;variable for the direction of the player
	flag db 0d ;variable for keeping same pace
	last_press db -1d ;saves the last direction the player headed
	ScoreA db 'Score is A:','$' ;print score A
	ScoreB db 'Score is B:','$' ;print score B
	ScoreC db 'Score is C:','$' ;print score C
	counter db 0d ;count how many times we entered to the timer
	msg db 'hello $' ;check variable

	
.code
	;proc to print the initial board
	get_board proc uses ax dx  cx ;push to stack ax,dx,cx
	mov cx,25 ;loop 25 times
	
L1:	mov dx, offset game_board ;print one line of spaces
	mov ah, 9h
	int 21h	
	
	mov dx, offset line_down ;line down
	mov ah, 9h
	int 21h
	loop L1
	
	ret
	get_board endp
	
	;proc to print X in the right location
	get_X proc uses ax bx dx
	;part 2
	mov al,0h ;ask clock for time in seconds
	out 70h,al
	in al,71h ;save seconds in higher bits
	mov ah,al ;ah=al=seconds

	mov al,2h ;ask clock for time in minutes
	out 70h,al
	in al,71h ;save minutes in lower bits
	
	
	mov bx,4000 ;mod for rtc location
	xor dx,dx ;reset dx value
	div bx ;dx=ax mod 4000
	mov di,dx
	and di,0FFFEh ;fix parity problem
	
	mov ax, 0B800h ;set ax to screen
	mov es,ax ; point es to screen using ax register
	mov bl, 58h ;set bl value to 'X'
	mov bh, 4h ;change bh color to red
	mov es:[di],bx ;print bx in random location based on rtc
	ret
	get_X endp
	
	;proc to use the PIT in the right timing
	same_pace proc far
		
	cmp counter,5 ;check if it's third iteration
	jne n1 ;if not do the usual proc
	;else
	mov counter,0 ;reset cx
	mov flag,1 ;sign that third iteration occured
n1:	inc counter ;cx++
	int 80h
	iret
	same_pace endp
	
	;start the main program
	
	START:
	.startup
	
	mov ax,0h ;move to the beginning of the IVT table
	mov es,ax ;point to that IVT table
	cli ;shutdown interrupts
	mov ax,es:[1Ch*4]; mov ip of 1Ch to ax
	mov es:[80h*4],ax ;mov ip of 1Ch to int 80h
	mov ax,es:[1Ch*4+2]; mov ip of 1Ch to ax
	mov es:[80h*4+2],ax ;mov ip of 1Ch to int 80h
	mov ax, offset same_pace ;ax = new proc
	mov es:[1Ch*4],ax ; interrupt 1Ch = new proc
	mov ax,cs; ax= code segment
	mov es:[1Ch*4+2],ax
	sti ;turn on interrupts
	
	;reset cx before program
	
	;part 1
	;print the initial board
	
	call get_board ;print the board
	mov si,middle ; set si to the middle of the screen
	mov ax, 0B800h ;set ax to screen
	mov es,ax ; point es to screen using ax register
	mov bl, 4Fh ;set bl value to 'O'
	mov bh, 4h ;change bh color to red
	mov es:[si],bx ;print bx in the middle of the scren
	
	call get_X ;print X on the board
	
	
	in al,21h
	or al,02h
	out 21h,al ;disable keyboard inputs

;first click on enter

firstEnter: 
	in al,64h
	test al,01 ;check if something pressed
	jz firstEnter ;go to loop until keyboard input
	in al,60h ;insert input to al
	test al,80h ;check if the keyboard released
	jz firstEnter ;if keyboard still pressed go back to loop

;keyboard input
PollKeyBoard:
	in al, 64h ;scan for keyboard input
	test al,01 ;check if something pressed
	;jz PollKeyBoard ;go to loop until keyboard input
	;first keyboard input
	in al,60h ;insert input to al
	;test al,80h ;check if the keyboard released
	;jz PollKeyBoard ;if keyboard still pressed go back to loop
	;keyboard released
	
	;and al,7Fh ;reset msb of al
	
;	jmp skip1
;	save:
;	mov al,last_press	
;	skip1:
	
	cmp al,91h ;check if al is 'w'
	jz W
	cmp al,9Fh ;check if al is 's'
	jz S
	cmp al,9Eh ;check if al is 'a'
	jz A
	cmp al,0A0h ;check if al is 'd'
	jz D
	cmp al,90h ;check if al is 'q'
	jz finish ;end game
	
	
stay:
	cmp flag,1
	jne stay ;if flag != 1 keep waiting
	;else (if flag == 1)
	mov last_press,al ;save the last pressed botton in last_press
	mov flag,0 ;reset flag
	jmp PollKeyBoard ;wait for next key
	
; jnz PollKeyBoard ;if al!=(a,s,d,w) continue waiting
	;בכל איטרציה תנסה לקלוט משהו מהמשתמש ואם לא קח את מה שהיה בעבר ותעבוד לפיו
	;בכל איטרציה סריקה אחת או שלחצו או שלא ואם לא קח את הפעולה האחרונה שאמרו
	
	
	
	; if 'w' pressed
	W:
	push ax
	push bx
	mov dx,158 ;dx=158
	cmp si,dx ;compare ah and zero
	jle popi ;if si<160 it's in the first row
	;else
	pop bx
	pop ax
	mov ax,' '
	mov es:[si],ax ;print bx in the middle of the scren
	add si,row
	mov es:[si],bx ;print O one line above
	mov direction,0 ;save the direction of the player (al) in direction variable
	jmp got_point ;go back to loop
	
	; if 's' pressed
	S:
	push ax
	push bx
	mov dx,3840 ;dx=3840
	cmp si,dx ;compare ah and zero
	jge popi ;if si<160 it's in the first row
	;else
	pop bx
	pop ax
	mov ax,' '
	mov es:[si],ax ;print bx in the middle of the scren
	sub si,row
	mov es:[si],bx ;print O one line above
	jmp got_point ;go back to loop
	
	; if 'd' pressed
	D:
	push ax ;save ax for later
	push bx ;save bx value
	mov ax,si ;ax=si
	mov bh,158 ;bh=80
	div line ;ah= ax mod 160
	cmp bh,ah ;compare ah and zero
	jz popi ;if O is in corner left then stay
	;else
	pop bx
	pop ax
	mov ax,' '
	mov es:[si],ax ;print bx in the middle of the scren
	add si,2
	mov es:[si],bx ;print O one line above
	jmp got_point ;go back to loop
	
	; if 'a' pressed
	A:
	push ax ;save ax for later
	push bx ;save bx value
	mov ax,si ;ax=si
	mov bx,0 ;bx=0
	div line ;ah= ax mod 160
	cmp bh,ah ;compare ah and zero
	jz popi ;if O is in corner left then stay
	;else
	pop bx
	pop ax
	mov ax,' '
	mov es:[si],ax ;print bx in the middle of the scren
	sub si,2
	mov es:[si],bx ;print O one row left
	jmp got_point ;go back to loop

popi: pop bx
	pop ax
	jmp stay

pointPlus:
inc points
call get_X ;print X another time randomically
jmp l3

got_point:	
	;si - 'O' location
	;di - 'X' location
	cmp si,di ;check if X and O are in the same location
	jz pointPlus ;if it does add 1 point
l3: jmp stay
	
	
	;finish of the program
finish:
	;mov es to 0
	mov ax,0
	mov es,ax
	;maybe cs move
	cli ;shutdown interrupts
	mov ax,es:[80h*4]
	mov es:[1Ch*4],ax
	mov ax,es:[80h*4+2]
	mov es:[1Ch*4+2],ax
	sti ;turn on interrupts


	

	;print points
	cmp points,(4)
	jle A1
	cmp points,(9)
	jle B1
	cmp points,(10)
	jge C1
	
	;print number points and grade
	
A1:	mov dx,offset ScoreA
	mov ah,9h
	int 21h
	jmp print_points
	
B1:	mov dx,offset ScoreB
	mov ah,9h
	int 21h
	jmp print_points
	
C1: mov dx,offset ScoreC
	mov ah,9h
	int 21h
	jmp print_points


print_points:
	;mov ax,offset points ;ax=points
	;mov dl,10h ;dl=16
	;div dl ;al= tens digit, ah=units digits
	;restore the ivt to the default
	

	
	mov dl, points
	add dl,48
	mov ah,02h
	int 21h
	
	;return keyboard control
	out 21h,al 
	and al,0dfh
	in al,21h ;
	
	.exit
end START