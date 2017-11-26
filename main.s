				INCLUDE stm32l1xx_constants.s		; Load Constant Definitions
				INCLUDE stm32l1xx_tim_constants.s   ; TIM Constants
					
				AREA	mydata, DATA
data dcd 2,18,4,5,27,12,9,8
sortData dcd 0,0,0,0,0,0,0,0
len equ 8
;-----------------------------------------	
keep1Left dcd -1,-1
keep1Right dcd -1,-1
chkKeep1 dcd 0

keep2Left dcd -1,-1,-1
keep2Right dcd -1,-1,-1
chkKeep2 dcd 0

keep4Left dcd -1,-1,-1,-1,-1
keep4Right dcd -1,-1,-1,-1,-1
chkKeep4 dcd 0
;-----------------------------------------	
lastData dcd 0
;-----------------------------------------	
				AREA    main, CODE, READONLY
				EXPORT	__main						; make __main visible to linker
				ENTRY
;-------------------------------------------			
subTwo
				SUB r2,r2,#2
				BL  foundedMiddle

;=============begin of merge sort============
mergeSort		
				;r0 address of data[0] ;r1 address of data[7]
				CMP r0,r1							;compare r0 (left side) and r1 (right side)
				BLT findMiddle						;if left<right do findMiddle
				B  divide							;if not then do divide
backFromMerge
				MOV PC, LR							;return point
				
findMiddle			
				SUB r2,r1,r0						;r2 = r-l
				LSR r2,r2,#1						;r2 = r2/2
				ADD r2,r0,r2						;r2 = address+middle address
				AND r3,r2,#3						;check r2%4 == 0
				CMP r3,#0
				BNE subTwo							;we need to +2 for point to address of array
foundedMiddle
				
				PUSH {r1}							;keep right addr
				MOV r1, r2
				ADD r3, r2, #4						;next to middle = middle+4
				PUSH {r3}							;keep left addr
				
				LDR r6,=chkKeep1					;set chkKeep1 to 0
				MOV r8,#0
				STR r8,[r6]
				
				BL mergeSort						;recursive mergesort of left side 
				;-----------------------------------------
				POP {r0}							;r0 = left(previous keep)
				POP {r1}							;r1 = right(previous keep)
				
				LDR r6,=chkKeep1					;set chkKeep1 to 1
				MOV r8,#1
				STR r8,[r6]

				B mergeSort							;recursive mergesort of right side

;-------------------------------------------------			
divide
				LDR r6,=chkKeep1					
				LDR r4,[r6]
				CMP r4, #1							;check if chkKeep1 = 1 (completed)
				BEQ fullSlot1Layer					;if completed goto fullSlot1Layer
										
				LDR r6,=keep1Left					;if not complete use keep1Left as vassel
				LDR r5,[r0] 					
				STR r5,[r6]							;store r0 value to keep1Left
				
				B finishKeep						;go back
fullSlot1Layer
				LDR r6,=keep1Right					
				LDR r5,[r0]
				STR r5,[r6]							;store r0 value to keep1Right
				
				; we already have keep1Right and keep1Left
				; continue // merge keep1 >> keep2	
;-------------------------------------------------	
prepareToMerge1	
				;continue merge
				LDR r6,=chkKeep2
				LDR r4,[r6]
				CMP r4, #1
				BEQ fullSlot2Layer			;check if chkKeep2 = 1 (completed)
				
				LDR r6,=chkKeep2			;if not completed change chkKeep2 to 1
				MOV r8,#1
				STR r8,[r6]
				LDR r6,=keep2Left			;if not completed use keep2Left as a vessel
			
				B fisrtLayerMerge			;goto fisrtLayerMerge
				
fullSlot2Layer		
				LDR r6,=keep1Right			
				LDR r7,[r6] 				;load keep1Right to r7
									
				LDR r6,=chkKeep2			;change state of chkkeep2 to 0
				MOV r8,#0
				STR r8,[r6]
				
				LDR r6,=keep2Right			;use keep2Right as a vessel
				
fisrtLayerMerge	
				;input r6 = vessel
				;input r8 = arrRight
				;input r9 = arrLeft

				LDR r8,=keep1Right
				LDR r9,=keep1Left
				
				PUSH {LR}
				mov lr,pc
				B Merge						;use merge fucntion
				POP {LR}			

finishFisrtLayerMerge	
											
				LDR r6,=chkKeep2			
				LDR r4,[r6]
				CMP r4, #0
				BNE finishKeep				;if chkKeep2=0 (not completed) go back
				
;------------------------------------------------------	
				;merge
				;we already have keep2Left and keep2Right
prepareToMerge2
				
				LDR r6,=chkKeep4
				LDR r4,[r6]
				CMP r4, #0					;check if chkKeep4 = 0 (completed)
				BEQ fullSlot4Layer
											
				LDR r6,=chkKeep4
				MOV r8,#0					;change state of chkkeep4 to 0
				STR r8,[r6]
				LDR r6,=keep4Right			;use keep4Right as a vessel

				B secondLayerMerge			;go merge
fullSlot4Layer
							
				LDR r6,=chkKeep4
				MOV r8,#1					;change state of chkkeep4 to 1
				STR r8,[r6]
				
				LDR r6,=keep4Left			;use keep4Left as a vessel
				
secondLayerMerge
				;input r6 = vessel
				;input r8 = arrRight
				;input r9 = arrLeft

				LDR r8,=keep2Right
				LDR r9,=keep2Left
				
				PUSH {LR}
				mov lr,pc
				B Merge						;use merge fucntion
				POP {LR}

finishSecondLayerMerge

				LDR r6,=chkKeep4
				LDR r4,[r6]
				CMP r4, #0
				BNE finishKeep				;if chkKeep4=0 (not completed) go back
				
;------------------------------------------------------	
ThirdLayerMerge
				;input r6 = vessel
				;input r8 = arrRight
				;input r9 = arrLeft

				LDR r6,=sortData
				LDR r8,=keep4Right
				LDR r9,=keep4Left
				
				PUSH {LR}
				mov lr,pc
				B Merge						;use merge fucntion
				POP {LR}
				
finishKeep

				LDR r6,=lastData
				LDR r10,[r6]
				
				CMP r0,r10					;CMP Left to lastData
				BEQ finish					;if equal end program
				
				B backFromMerge				;back track
				
;-----------Merge Function--------------------
Merge
				;input r6 = vessel
				;input r8 = arrRight
				;input r9 = arrLeft

				LDR r5,[r8] 		;r5 is arrRight
				LDR r7,[r9] 		;r7 is arrLeft
				
				CMP r5,#-1
				CMPEQ r7,#-1
				BNE loopCompare
				mov pc,lr
loopCompare			
				CMP r5,r7
				BLT rightLess
				CMP r7,#-1
				BNE addLeft
				B addRight
rightLess
				CMP r5,#-1
				BNE addRight
				B addLeft
addLeft
				CMP r7,#-1
				STRNE r7,[r6]
				ADDNE r6,r6,#4
				ADDNE r9,r9,#4
				B Merge		
				
addRight
				;add right r5
				CMP r5,#-1
				STRNE r5,[r6]
				ADDNE r6,r6,#4
				ADDNE r8,r8,#4
				B Merge	
;-------------------------------------------					
__main			
				STR lr,[sp]	
				LDR r0,=data						;r0-->data[0] ;load data register ;r0 kepp address of array
				LDR r1,=len							;r1=len
				SUB r1,r1,#1						;r1=len-1
				LSL r1,r1,#2						;r1=r1*4
				ADD r1,r0,r1						;r1-->data[r1] or data[(len-1)]
				
				MOV r10,r1							;r10 is the last Data's addr
				LDR r6,=lastData					;r6 keep addr of lastData
				STR r10,[r6]						;Store r10 to mem lastData
				
				B  mergeSort						;goto merge sort
				
;-------------------------------------------	

finish			B finish
				ALIGN
				AREA allocations, DATA, READWRITE
				END