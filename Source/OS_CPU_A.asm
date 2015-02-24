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
       RSEG?PR?OSStartRdy?OS_CPU_A
OSStartHighRdy:
       USING 0       ; ʹ�üĴ�����0�顣�ϵ��51�Զ����жϣ��˴�����CLR EAָ���Ϊ���˴���δ�жϣ��������˳����ж�
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
       