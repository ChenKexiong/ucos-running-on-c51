$NOMOD51
EA	BIT	0A8H.7
SP	DATA	081H
B	DATA	0F0H
ACC	DATA	0E0H
DPH	DATA	083H
DPL	DATA	082H
PSW	DATA	0D0H
TR0	BIT	088H.4
TH0	DATA	08CH
TL0	DATA	08AH

NAME OS_CPU_A    ;ģ����


; �����ض�λ��
?PR?OSStartHighRdy?OS_CPU_A SEGMENT CODE
?PR?OSCtxSw?OS_CPU_A SEGMENT CODE
?PR?OSIntCtxSw?OS_CPU_A SEGMENT CODE
?PR?OSTickISR?OS_CPU_A SEGMENT CODE

; ��������ȫ�ֱ������ⲿ�ӳ���
          EXTRN IDATA(?C_XBP)   ; �����ջָ����������ֲ���������
		  EXTRN IDATA(OSTCBCur)
		  EXTRN IDATA(OSTCBHighRdy)
		  EXTRN IDATA(OSRunning)
		  EXTRN IDATA(OSPrioCur)
		  EXTRN IDATA(OSPrioHighRdy)
		  EXTRN CODE (_?OSTaskSwHook)
		  EXTRN CODE (_?OSIntEnter)
		  EXTRN CODE (_?OSIntExit)
		  EXTRN CODE (_?OSTimeTick)

; ��������4���������뺯��
          PUBLIC OSStartHighRdy
		  PUBLIC OSCtxSw
		  PUBLIC OSIntCtxSw
		  PUBLIC OSTickISR
		  
; �����ջ�ռ䡣ֻ���Ĵ�С����ջ�����keil������ͨ����ſ��Ի��keil�����SP��㡣
?STACK SEGMENT IDATA
       RSEG ?STACK
OSStack:
       DS 40H
OSStkStart IDATA OSStack-1

; ����ѹջ��
PUSHALL MACRO
       PUSH PSW
	   PUSH ACC
	   PUSH B
	   PUSH DPL
	   PUSH DPH
	   MOV  A,R0     ; R0-R7��ջ
	   PUSH ACC
	   MOV  A,R1
	   PUSH ACC
	   MOV  A,R2
	   PUSH ACC
	   MOV  A,R3
	   PUSH ACC
	   MOV  A,R4
	   PUSH ACC
	   MOV  A,R5
	   PUSH ACC
	   MOV  A,R6
	   PUSH ACC
	   MOV  A,R7
	   PUSH ACC
	   ; PUSH SP      ; ���ȱ���SP�������л�ʱ����Ӧ�������
	   ENDM

; �����ջ��
POPALL MACRO
       ;POP SP        ; ���ر���SP�������л�ʱ����Ӧ�������
	   POP ACC       ; R0-R7��ջ
	   MOV R7,A
	   POP ACC
	   MOV R6,A
	   POP ACC
	   MOV R5,A
	   POP ACC
	   MOV R4,A
	   POP ACC
	   MOV R3,A
	   POP ACC
	   MOV R2,A
	   POP ACC
	   MOV R1,A
	   POP ACC
	   MOV R0,A
	   POP DPH
	   POP DPL
	   POP B
	   POP ACC
	   POP PSW
	   ENDM
	   
; �ӳ���
       RSEG ?PR?OSStartRdy?OS_CPU_A
OSStartHighRdy:
       USING 0               ; ʹ�üĴ�����0�顣�ϵ��51�Զ����жϣ��˴�����CLR EAָ���Ϊ���˴���δ�жϣ��������˳����ж�
	   LCALL _?OSTackSwHook
OSCtxSw_in:
       ;OSTCBCur ===> DPTR   ; ��õ�ǰTCBָ��
	   MOV  R0,#LOW(OSTCBCur); ���OSTCBCurָ��͵�ַ��ָ��ռ3�ֽڡ�+0����+1��8λ����+2��8λ����
	   INC  R0
	   MOV  DPH, @R0
	   INC  R0
	   MOV  DPL, @R0
	   ;OSTCBCur->OSTCBStkPtr===>DPTR  ;����û���ջָ��
	   INC  DPTR
	   MOVX A, @DPTR         ; OSTCBStkPtr��voidָ��
	   MOV  R0,A
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  R1,A
	   MOV  DPH, R0
	   MOV  DPL, R1
	   ;*UserStrPtr ===> R5  ; �û���ջ��ʼ��ַ���ݣ����û���ջ���ȷ��ڴ˴���
	   MOVX A, @DPTR
	   MOV  R5, A            ; R5 = �û���ջ����
	   ; �ָ��ֳ���ջ����
	   MOV  R0, #OSStkStart
restore_stack:
       INC  DPTR
	   INC  R0
	   MOVX A, @DPTR
	   MOV  @R0, A
	   DJNZ R5, restore_stack
	   ; �ָ���ջָ��SP
	   MOV  SP,R0
	   ; �ָ������ջָ��?C_XBP
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  ?C_XBP, A        ; ?C_XBP�����ջָ���8λ
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  ?C_XBP+1, A      ; ?C_XBP�����ջָ���8λ
	   ;OSRunning=TRUE
	   MOV  R0, #LOW(OSRunning)
	   MOV  @R0, #01
	   POPALL
	   SETB EA
	   RETI
	   
;----------------------------------------------------------------------
       RSEG ?PR?OSCtxSw?OS_CPU_A
OSCtxSw:
       PUSHALL
OSIntCtxSw_in:
       ; ��ö�ջ���Ⱥ���ʼ��ַ
	   MOV  A, SP
	   CLR  C
	   SUBB A, #OSStkStart
	   MOV  R5, A            ; ��ö�ջ����
	   ;OSTCBCur===>DPTR     ; ��õ�ǰTCBָ��
	   MOV  R0, #LOW(OSTCBCur)
	   ; ���OSTCBCurָ��͵�ַ��ָ��ռ3�ֽڡ�+0����+1�߰�λ����+2�Ͱ�λ����
	   INC  R0
	   MOV  DPH, @R0
	   INC  R0
	   MOV  DPL, @R0
	   ;OSTCBCur->OSTCBStkPtr===>DPTR    ; ����û���ջָ��
	   INC  DPTR
	   MOVX A, @DPTR         ; OSTCBStkPtr��voidָ��
	   MOV  R0, A
	   INC  DPTR
	   MOVX A, @DPTR
	   MOV  R1, A
	   MOV  DPH, R0
	   MOV  DPL, R1
	   ; �����ջ����
	   MOV  A, R5
	   MOVX @DPTR, A
	   MOV  R0, #OSStkStart  ; ��ö�ջָ��
save_stack:
       INC  DPTR
	   INC  R0
	   MOV  A, @R0
	   MOVX @DPTR, A
	   DJNZ R5, sava_stack
	   ; ��������ջָ��?C_XBP
	   INC  DPTR
	   MOV  A, ?C_XBP        ; C_XBP�����ջָ���8λ
	   MOVX @DPTR, A
	   INC  DPTR
	   MOV  A, ?C_XBP+1      ; C_XBP�����ջָ���8λ
	   MOVX @DPTR, A
	   ; �����û�����
	   LCALL _?OSTaskSwHook
	   ;OSTCBCur=OSTCBHighRdy
	   MOV  R0, #OSTCBCur
	   MOV  R1, #OSTCBHighRdy
	   MOV  A, @R1
	   MOV  @R0, A
	   INC  R0
	   INC  R1
	   MOV  A, @R1
	   MOV  @R0, A
	   ;OSPrioCur=OSPrioHighRdy   ; ʹ��������������ҪĿ����Ϊ��ʹָ��Ƚϱ�Ϊ�ֽڱȽϣ��Ա��ʡ�ռ�
	   MOV  R0, #OSPrioCur
	   MOV  R1, #OSPrioHighRdy
	   MOV  A, @R1
	   MOV  @R0, A
	   LJMP OSCtxSw_in
	   
;-----------------------------------------------------------------------
       RSEG ?PR?OSIntCtxSw?OS_CPU_A
OSIntCtxSw:
       ; ����spָ��ȥ���ڵ���OSIntExit(),OSIntCtxSw()������ѹ��ջ�Ķ�������
	   ;SP=SP-4
	   MOV  A, SP
	   CLR  C
	   SUBB A, #4
	   MOV  SP, A
	   LJMP OSIntCtXSw_in

;-----------------------------------------------------------------------
       CSEG AT 000BH      ;OSTickISR
	   LJMP OSTickISR
	   RSEG ?PR?OSTickISR?OS_CPU_A
OSTickISR:
       USING 0
	   PUSHALL
	   CLR   TR0
	   MOV   TH0, #0B1H
	   MOV   TL0, #0E0H
	   SETB  TR0
	   LCALL _?OSIntEnter
	   LCALL _?OSTimeTick
	   LCALL _?OSIntExit
	   POPALL
	   RETI
	   
END 