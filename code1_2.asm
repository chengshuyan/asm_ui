.586
DATA SEGMENT USE16
WIN_LEFT DB 2,3,5,4,35
WIN_RIGHT DB 2,3,43,4,73 
WIN_LEFT_UP DB 1,3,5,4,35
WIN_RIGHT_UP DB 1,3,43,4,73
BUTTON DB 1,19,5,19,10
FILE_TEXT DB 1,19,12,19,35
winnum DB 1
OLD0B DD ?    ;�洢ϵͳ0BH�ж�����
FLAG DB 0      ;��־λ
CONT DB 0
CURSE_LEFT DB 3,5
CURSE_RIGHT DB 3,43
CURSE_BUTTON DB 19,6
lx	db 3    ;win1��ǰ���λ��
ly	db 5
rx	db 3    ;win2��ǰ���λ��
ry	db 43
FILE DB 'file$'
COLOR DB 0
WIN_COLOR DB 3EH
FILE_COLOR DB 63H
SHOW DB 0AH,0DH
     DB 17 DUP(' '),'sender',16 DUP(' '),'*',16 DUP(' '),'reciver',0AH,0DH,'$'
DATA ENDS 
CODE SEGMENT USE16
	 ASSUME CS:CODE,DS:DATA
BEG: MOV AX,DATA
	 MOV DS,AX
	 CALL UI_DESIGN
	 CLI			;���ж�
	 CALL I8250		;�����ڳ�ʼ��
	 CALL I8259		;����8259A�������ж�
	 CALL RD0B		;����0BH�ж�����
	 CALL WR0B	    ;�û�0BH�ж�����
	 STI			;���ж�
SCANT:
	 CMP FLAG,-1    
	 JE RETURN
	 MOV DX,2FDH	;��ѯ���ͱ��ּĴ���
	 IN AL,DX
	 TEST AL,20H
	 JZ SCANT
	 MOV AH,1	;��ѯ���̻�����
	 INT 16H
	 JZ SCANT
	 MOV AH,0	;��ȡ���̻����������� ASCII->AL
	 INT 16H
	 AND AL,7FH
	 MOV DX,2F8H 
	 OUT DX,AL
     CMP AL,1BH
     JNE SCANT
TWAIT:
	 MOV DX,2FDH
	 IN AL,DX
	 TEST AL,40H   ;����һ֡�Ƿ�����
	 JZ TWAIT
RETURN:            ;��һ֡��������ִ�н�������
	 CALL RESET    ;�ָ�ϵͳ0BH�ж�����
	 MOV AH,4CH
	 INT 21H

;�����жϷ����ӳ���
RECEIVE PROC
	  PUSH AX
	  PUSH DX
	  PUSH DS
	  MOV AX,DATA
	  MOV DS,AX
	  MOV DX,2F8H  ;��ȡ���ջ�����������
	  IN  AL,DX
	  AND AL,7FH
	  ;����Ƿ�Ϊ���
	  CMP AL,4BH
	  JNE is_win_right
	  MOV BL,lx
	  MOV CURSE_LEFT[0],BL
	  MOV BL,ly
	  MOV CURSE_LEFT[1],BL
	  MOV BX,OFFSET CURSE_LEFT
	  CALL POS_CURSE
	  MOV winnum,1
	  JMP EXIT
is_win_right:
      ;����Ƿ�Ϊ�Ҽ�
      CMP AL,4DH
      JNE is_ESC
      MOV BL,rx
      MOV CURSE_RIGHT[0],BL
      MOV BL,ry
      MOV CURSE_RIGHT[1],BL
      MOV BX,OFFSET CURSE_RIGHT
      CALL POS_CURSE
      MOV winnum,2
      JMP EXIT
is_ESC:
    ;�ж��Ƿ���'esc'
	CMP AL,01  
	JE NEXT
	;���������display,������������ʾ�����Ҵ���
	CALL DISPLAY 
	CALL Beep ;������Ϣ��ʾ��
	JMP EXIT
NEXT: MOV FLAG,-1
EXIT: 
	MOV AL,20H
	OUT 20H,AL
 	POP DS
	POP DX
	POP AX
	IRET    ;�жϷ���
RECEIVE ENDP

DISPLAY PROC
    CMP winnum,1
    ;��ʾ������Ļ
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
	;��ʾ������Ļ
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BL,rx
	MOV CURSE_RIGHT[0],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
	MOV AH,2	   ;����"esc",��ʾ�ַ�����Ļ��
	MOV DL,AL
	INT 21H
	INC ry 
    CMP ry,73
	JLE change_ry
	MOV ry,43
	INC rx
	MOV BL,WIN_RIGHT[3]
	CMP rx,BL
	JLE change_rx
	MOV BX,OFFSET WIN_RIGHT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,WIN_RIGHT[3]
	MOV rx,BL
change_rx:
    MOV BL,rx
    MOV CURSE_RIGHT[0],BL
change_ry:
	MOV BL,ry
	MOV CURSE_RIGHT[1],BL
	MOV BX,OFFSET CURSE_RIGHT
	CALL POS_CURSE
    INC ly
    CMP ly,35
	JLE change_ly
	MOV ly,5
	INC lx
	MOV BL,WIN_LEFT[3]
	CMP lx,BL
	JLE change_lx
	MOV BX,OFFSET WIN_LEFT_UP
	MOV CL,WIN_COLOR
	MOV COLOR,CL
	CALL SCROLL
	MOV BL,WIN_LEFT[3]
	MOV lx,BL
change_lx:
    MOV BL,lx
    MOV CURSE_LEFT[0],BL
change_ly:
	MOV BL,ly
	MOV CURSE_LEFT[1],BL
	MOV BX,OFFSET CURSE_LEFT
	CALL POS_CURSE
	JMP THE_END
THE_END:
	RET
DISPLAY ENDP

Beep PROC
	PUSH BX
	PUSH AX
	PUSH DX
	MOV AX,0  ;120000H������
	MOV DX,12H
	MOV BX,1048  
	DIV BX       ;����Ƶ��ֵ
	MOV BX,AX
	MOV AL,10110110B ;���ö�ʱ��������ʽ
    OUT 43H,AL
  
    MOV AX,BX            
    OUT 42H,AL   ;���ü�������8λ
  
    MOV AL,AH    ;���ü�������8λ
    OUT 42H,AL
  
    IN AL,61H     ;������
    OR AL,03H
    OUT 61H,AL
    CALL DELAY
    IN AL,61H     ;�ر�����
    AND AL,0FCH
    OUT 61H,AL
    POP DX
    POP AX
    POP BX
    RET
Beep ENDP

DELAY  PROC
  	PUSH CX
	MOV CX,05H;
  	DELAYLOOP1: 
  		PUSH CX
  		MOV CX,0FFFFH;
  		DELAYLOOP2:
  		LOOP DELAYLOOP2
  		POP CX
  	LOOP DELAYLOOP1
  	POP CX
  	RET
DELAY ENDP

;��ʼ��8250
I8250 PROC
	  MOV DX,2FBH    ;ѰַΪ��1
	  MOV AL,80H
	  OUT DX,AL
	  MOV DX,2F9H	 ;д�����Ĵ�����8λ
	  MOV AL,0
	  OUT DX,AL
	  MOV DX,2F8H	 ;д�����Ĵ�����8λ,������Ϊ1200
	  MOV AL,60H
	  OUT DX,AL
	  MOV DX,2FBH  	 ;д֡���ݸ�ʽ:8����Ϊ,1ֹͣλ,��У��λ	 
	  MOV AL,03H
	  OUT DX,AL
	  MOV DX,2F9H 	 ;����8250�ڲ�����ж�	
	  MOV AL,01H
	  OUT DX,AL
	  MOV DX,2FCH
	  MOV AL,00011000B  ;D4=1�ڻ��Լ�,   D3=1�����ж�, D4=0����ͨ��
	  OUT DX,AL
	  RET     ;���ڷ���
I8250 ENDP

;������8259�������ж�  D3λ
I8259 PROC
      IN AL,0A1H
      AND AL,11101111B
      OUT 0A1H,AL
	  IN AL,21H
	  AND AL,11110011B
	  OUT 21H,AL
	  RET     ;���ڷ���
I8259 ENDP

RD0B PROC
	  MOV AX,350BH
	  INT 21H
	  MOV WORD PTR OLD0B,BX
	  MOV WORD PTR OLD0B+2,ES
	  RET   ;���ڷ���
RD0B ENDP

WR0B PROC
	  PUSH DS
	  MOV AX,CODE
	  MOV DS,AX
	  MOV DX,OFFSET RECEIVE
	  MOV AX,250BH
	  INT 21H
	  POP DS
	  RET	;���ڷ���
WR0B ENDP
	 
	 
RESET PROC
	  IN AL,21H
	  OR AL,00001000B    ;���ж����μĴ����ĸ������ж���������1���ر�8259�������ж�
	  OUT 21H,AL
	  MOV AX,250BH
	  MOV DX,WORD PTR OLD0B
	  MOV DS,WORD PTR OLD0B+2
	  INT 21H
	  RET	;���ڷ���
RESET ENDP

CLEAR PROC ;����
	MOV AH,6 ;���Ϲ�������
	MOV AL,0 ;
	MOV BH,7 ;������ɫ��������ɫ
	MOV CH,0 ;������
	MOV CL,0 ;������
    MOV DH,24 ;������
	MOV DL,79 ;������
	INT 10H 
	RET	;���ڷ���
CLEAR ENDP

UI_DESIGN PROC
	;����
	 CALL CLEAR
	 LEA SI,SHOW
	 MOV DX,SI
	 MOV AH,09H
	 INT 21H
	 ;�����󴰿ڲ���
	 MOV BX,OFFSET WIN_LEFT
	 MOV CL,WIN_COLOR
	 MOV COLOR,CL
	 CALL SCROLL
	 ;�����Ҵ��ڲ���
	 MOV BX,OFFSET WIN_RIGHT
	 CALL SCROLL
	 ;���ð�ť����
	 MOV BX,OFFSET BUTTON
	 MOV CL,FILE_COLOR
	 MOV COLOR,CL
	 CALL SCROLL
	 ;����fileBUTTONs
	 MOV BX,OFFSET CURSE_BUTTON
	 CALL POS_CURSE
	 MOV DX,OFFSET FILE
	 MOV AH,9
	 INT 21H
	 ;����file_text
	 MOV BX,OFFSET FILE_TEXT
	 CALL SCROLL
	 ;���ó�ʼ���λ��
	 MOV BX,OFFSET CURSE_LEFT
	 CALL POS_CURSE
	 RET
UI_DESIGN ENDP

SCROLL PROC ;��ʾ����
	  MOV AH,6 ;���Ϲ�������
	  MOV AL,[BX]  ;�Ͼ�����
	  MOV CH,[BX + 1] ;���Ͻ��к�
	  MOV CL,[BX + 2] ;���Ͻ��к�
	  MOV DH,[BX + 3] ;���Ͻ��к�
	  MOV DL,[BX + 4] ;���Ͻ��к�
	  MOV BH,COLOR;������ɫ���ַ���ɫ ��ɫ�����ͻ�ɫ����
	  INT 10H
	  RET	;���ڷ���
SCROLL ENDP

POS_CURSE PROC
	MOV DH,[BX]
	MOV DL,[BX+1]
	MOV BH,0
	MOV AH,2
	INT 10H
	RET  ;���ڷ���
POS_CURSE ENDP

MOUSE PROC
	PUSH AX
	PUSH DX
	PUSH DS
	MOV AX,DATA
	MOV DS,AX
	MOV AX,0  ;��ʼ�����
    INT 33H
    MOV AX,1  ;��ʾ���
    INT 33H
    MOV AX,0AH  ;�����ı�������״
    MOV CX,6E41H ;15Ϊ��˸��14-12�ַ�����ɫ��11���ȣ�10-8�ַ���ɫ��7-0���ָ�����
    INT 33H
  	MOV AX,05
  	MOV BX,0
  	MOV AL,20H 
	OUT 20H,AL  ;��8259Aд������
 	POP DS
	POP DX
	POP AX
	IRET    ;�жϷ���
MOUSE ENDP

CODE ENDS
	 END BEG








