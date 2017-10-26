	
|;*******************************CONSTANTS**************************************
nb_rows = 8
nb_cols = 32
nb_cells = 256
words_per_mem_line = 8
mem_lines_per_row = 8
words_per_row = 64
nb_maze_words = 512
cells_per_word = 4


OPEN_V_0:
 LONG(0xFFFFFF00)
OPEN_V_1:
 LONG(0xFFFF00FF)
OPEN_V_2:
 LONG(0xFF00FFFF)
OPEN_V_3:
 LONG(0x00FFFFFF)
OPEN_H_0:
 LONG(0xFFFFFFE1)
OPEN_H_1:
 LONG(0xFFFFE1FF)
OPEN_H_2:
 LONG(0xFFE1FFFF)
OPEN_H_3:
 LONG(0xE1FFFFFF)
|;*****************************************************************************


|;***********************************MACROS*************************************

|;Reg[Rc] <- Reg[Ra] mod <CC>
.macro MODC(Ra, CC, Rc) DIVC(Ra, CC, Rc) MULC(Rc, CC, Rc) SUB(Ra, Rc, Rc)

|;Swap the values stored at addresses a and b.
.macro SWAP(Ra,Rb,Rc) MOVE(Ra,Rc) MOVE(Rb,Ra) MOVE(Rc,Rb)

|;Return the row of the cell at given index.
.macro ROW_FROM_INDEX(Ra,Rb,Rc) DIV(Ra,Rb,Rc)

|;Return the column of the cell at given index.
.macro COL_FROM_INDEX(Ra,Rb,Rc) MOD(Ra,Rb,Rc)

.macro INIT() PUSH(LP) PUSH(BP) MOVE(SP,BP)

.macro END() MOVE(BP,SP) POP(BP) POP(LP) RTN()
|;******************************************************************************


|;*****************************PERFECT_MAZE FONCTION****************************
perfect_maze:

	INIT()

	|;Save in the stack the value of the registers we'll use in the function
	PUSH(R1) 
	PUSH(R2)
	PUSH(R3)
	PUSH(R4)
	PUSH(R6)
	PUSH(R7)
	PUSH(R8)
	PUSH(R9)
	PUSH(R10)
	PUSH(R11)
	PUSH(R12)
	PUSH(R19)
	PUSH(R20)

	|;Load the values we put in the stack in the registers
	LD(BP,-12,R1) |;maze --> R1
	LD(BP,-16,R2) |;nb_rows --> R2
	LD(BP,-20,R3) |;nb_cols --> R3
	LD(BP,-24,R4) |;visited --> R4
	LD(BP,-28,R6) |;curr_cell --> R6

 	|;Update the bitmap by putting 1 in the cell that is visited
	CMOVE(1,R7)
	MODC(R6,32,R8)	|;curr_cell % 32 --> R8
	SHL(R7,R8,R7)	|;shift 1 (<R7>) left by <R8> bits
	DIVC(R6,32,R8)	|;curr_cell/32 --> R8
	MULC(R8,4,R8)	|;R8 * 4 --> R8 (to get the offset)
	ADD(R8,R4,R8)	|;visited (R4) + offset (R8) --> R8
	LD(R8,0,R9)		|;visited[curr_cell /32] --> R9
	OR(R9,R7,R7)	|;put 1 in the curr_cell if not visited yet (OR)
	.breakpoint
	|;ST(R7,0,R8)	|;put the updated visited back
	ST(R7,0,R9)		|;put the updated visited back

	COL_FROM_INDEX(R6,R3,R8)	|; col --> R8
	CMOVE(0,R9) 				|; n_valid_neighbours = 0


|;Check left neighbour
checkLeft: 
	CMPLEC(R8,0,R7)		|;if (col <= 0) -> jump at checkRight
	BT(R7,checkRight)
	SUBC(R6,1,R7)		|;curr_cell-1 --> R7
	PUSH(R7)			|;save R7 in the stack
	ADDC(R9,4,R9)		|;n_valid_neighbours++ --> R9


|;Check right neighbour
checkRight:
	SUBC(R3,1,R7)	|;nb_cols-1  --> R7
	CMPLT(R8,R7,R7) |;if (col < nb_cols-1) -> jump at checkTop
	BF(R7,checkTop)
	ADDC(R6,1,R7)	|;curr_cell+1 --> R7
	PUSH(R7)		|;save R7 in the stack
	ADDC(R9,4,R9) 	|;n_valid_neighbours++ --> R9


|;Check top neighbour
checkTop:	
	ROW_FROM_INDEX(R6,R3,R8) |; row --> R8

	CMPLEC(R8,0,R7) 	|;if (row <= 0) -> jump at checkBottom
	BT(R7,checkBottom)
	SUB(R6,R3,R7) 		|;curr_cell-nb_cols --> R7
	PUSH(R7)			|;save R7 in the stack
	ADDC(R9,4,R9) 		|;n_valid_neighbours++ --> R9


|;Check bottom neighbour
checkBottom:
	SUBC(R2,1,R7) 		|;nb_rows-1 --> R7
	CMPLT(R8,R7,R7) 	|;if (row < nb_rows-1) -> jump at while_loop
	BF(R7,while_loop)
	ADD(R6,R3,R7) 		|;curr_cell+nb_cols --> R7
	PUSH(R7)			|;save R7 in the stack
	ADDC(R9,4,R9) 		|;n_valid_neighbours++ --> R9


while_loop:

	|;Loop condition
	CMPLEC(R9,0,R7) 		|;if (n_valid_neighbours <= 0) -> jump out of the loop
	BT(R7,perfect_maze_end)

	|;Randomly select one neighbour
	RANDOM()
	PUSH(R0)
	CALL(abs__)
	DEALLOCATE(1)
	DIVC(R9,4,R7) |;n_valid_neighbours/4 --> R7 (to get the index between [0..3])
	MOD(R0,R7,R8) |;random_neigh_index = (random % n_valid_neighbours/4) --> R8


	ADDC(BP,4*13,R20) |;Beginning of our array "neighbours" in the stack (put it in R20)
					  |;We already pushed 13 local variables on the stack
					  |;So we add 13*4 to BP to get the correct place in the stack
	
	MULC(R8,4,R7) 	|;random_neigh_index*4 --> R7 (to get the offset)
	ADD(R20,R7,R7) 	|;neighbours+4*random_neigh_index --> R7
	LD(R7,0,R19)  	|;neighbour = neighbours[random_neigh_index] --> R19
	

	|;Put the taken neighbour at the end of neighbours array
	SUBC(R9,4,R11) 	|;n_valid_neighbours-1 --> R11 (index of the last element of neighbours)
	ADD(R20,R11,R11)|;neighbours + n_valid_neighbours-1 --> R11
	LD(R11,0,R10) 	|;neighbours[n_valid_neighbours-1] --> R10

	ST(R10,0,R7)	|;swap neighbours[n_valid_neighbours-1] and neighbours[random_neigh_index] 
	ST(R19,0,R11) 	|; 
	
	SUBC(R9,4,R9) 	|;n_valid_neigbours--

	

	PUSH(R20) 		|;push the adress of the array neighbours
	PUSH(R9) 		|;push n_valid_neighbours

	|;Check if the neighbour is already visited
	MODC(R19,32,R7) |;neighbour % 32
	DIVC(R19,32,R8) |;neighbour/32 
	MULC(R8,4,R8) 	|;R8*4 (to get the offset)
	ADD(R4,R8,R8)	|;visited+4*neighbour/32 --> R8
	LD(R8,0,R8) 	|;visited[neighbour/32] --> R8
	SHR(R8,R7,R8) 	|;shift right the bitmap of (neighbour % 32)
	ANDC(R8,1,R8) 	|;visited_bit --> R8
	CMPEQC(R8,1,R7) |;if it is 1 (already visited)
	BT(R7,while_loop)


	|;RECURSIVITE
	PUSH(R6) 	|;push curr_cell for connect
	PUSH(R4) 	|;push visited
	PUSH(R19) 	|;push neigbour (!= neighbours)
	PUSH(R3)	|;push nb_cols	
	PUSH(R1) 	|;push maze

	CALL(connect__)	
	DEALLOCATE(5)

	POP(R9)
	POP(R20)

	PUSH(R19) 	|;neighbour becomes new curr_cell
	PUSH(R4) 	|;push visited
	PUSH(R3) 	|;push cols
	PUSH(R2) 	|;push rows
	PUSH(R1) 	|;push maze

	CALL(perfect_maze)
	DEALLOCATE(5) |;  5 registers
	 |; l'appel récursif s'est arrêté, on reprend un autre neighbour de curr_cell
	BR(while_loop)

perfect_maze_end:

	POP(R20)
	POP(R19)
	POP(R12)
	POP(R11)
	POP(R10)
	POP(R9)
	POP(R8)
	POP(R7)
	POP(R6)
	POP(R4)
	POP(R3)
	POP(R2)
	POP(R1)	
	END()	|;END OF WHILE

|;********************************************************************************

|;****************************CONNECT FUNCTION***********************************
connect__:

	INIT()	
	
	PUSH(R6) 	|;push curr_cell for connect
	PUSH(R4) 	|;push visited
	PUSH(R19) 	|;push neigbour
	PUSH(R3) 	|;push nb_cols	
	PUSH(R1) 	|;push maze
	
	LD(BP,-12,R1) 	|;maze --> R1
	LD(BP,-16,R3) 	|;nb_cols --> R3
	LD(BP,-20,R19)	|;neighbour --> R19
	LD(BP,-24,R4) 	|;visited --> R4
	LD(BP,-28,R6) 	|;curr_cell --> R6
	
	CMPLT(R6,R19,R7) 	|;make sure source < dest (neighbour)
	BT(R7,byte_offset) 	|;if it is true, we jump the swap macro
	SWAP(R19,R6,R7)		|;swap source and destination if false

byte_offset:
	ROW_FROM_INDEX(R19,R3,R7)	|;dest_row --> R7
	MULC(R7,words_per_row,R11) 	|;row_offset = dest_row * WORDS_PER_ROW --> R11
	COL_FROM_INDEX(R6,R3,R7) 	|;source_col --> R7
	CMOVE(cells_per_word,R8) 	|;cells per word --> R8
	ROW_FROM_INDEX(R7,R8,R12) 	|;word_offset_in_line --> R12
	ADD(R11,R12,R11) 			|;word offset = row_offset + word_offset_in_line --> R11
	COL_FROM_INDEX(R7,R8,R12) 	|;byte_offset --> R12


vertical__:
	SUB(R19,R6,R7) 		|;dest-source --> R7
	CMPLEC(R7, 1, R7) 	|;if dest-source <= 1 --> R7 = 1 (jump to horizontal)
	BT(R7,horizontal__) 
	
	CMPEQC(R12,0,R7) 	|;byte offset == 0 ?
	BF(R7,openV1)
	CMOVE(OPEN_V_0,R13) |;OPEN_V_0 --> R13
	LD(R13,0,R13)
	BR(vert_loop_init__)

openV1: 
	CMPEQC(R12,1,R7)	|;byte offset == 1 ?
	BF(R7,openV2)
	CMOVE(OPEN_V_1,R13) |;OPEN_V_1 --> R13
	LD(R13,0,R13)
	BR(vert_loop_init__)

openV2:
	CMPEQC(R12,2,R7)	|;byte offset == 2 ?
	BF(R7,openV3)
	CMOVE(OPEN_V_2,R13) |;OPEN_V_2 --> R13
	LD(R13,0,R13)
	BR(vert_loop_init__)

openV3:
	CMOVE(OPEN_V_3,R13) |;OPEN_V_3 --> R13
	LD(R13,0,R13)
	

vert_loop_init__:
	CMOVE(3,R14) 	|; initialise the iterator to 3
vert_loop__:
	CMPEQC(R14,7, R7)
	BT(R7,connect_end__)
	CMOVE(8,R7) |; 8 words per mem line
	MUL(R14,R7,R7) |; iterator*words_per_mem_line
	ADD(R11,R7,R7) |; word_offset + iterator*words_per_mem_line
 
	MULC(R7,4,R7) |; R7 now contains the adress of the *word* to be changed
	ADD(R1,R7,R7) |; On va à l'adresse du word à partir du début
	LD(R7,0,R15) |; load the word to R15
	AND(R15,R13,R25) |; apply the mask
	ST(R25,0,R7) |; put the updated word back
	ADDC(R14,1,R14) |; increment iterator
	BR(vert_loop__)


horizontal__:
	CMPEQC(R12,0,R7) 	|;byte offset == 0 ?
	BF(R7,openH1)
	CMOVE(OPEN_H_0,R13) |;OPEN_H_0 --> R13
	LD(R13,0,R13)
	BR(horitonzal_loop_init__)

openH1:
	CMPEQC(R12,1,R7)	|;byte offset == 1 ?
	BF(R7,openH2)
	CMOVE(OPEN_H_1,R13) |;OPEN_H_1 --> R13
	LD(R13,0,R13)
	BR(horitonzal_loop_init__)
openH2:
	CMPEQC(R12,2,R7)	|;byte offset == 2 ?
	BF(R7,openH3)
	CMOVE(OPEN_H_2,R13) |;OPEN_H_2 --> R13
	LD(R13,0,R13)
	BR(horitonzal_loop_init__)
openH3:
	CMOVE(OPEN_H_3,R13) |;OPEN_H_3 --> R13
	LD(R13,0,R13)


horitonzal_loop_init__:
	CMOVE(0,R14) 	|; initialise the iterator to 0
horizontal_loop__:
	CMPEQC(R14,2, R7)
	BT(R7,connect_end__)

	MULC(R14,words_per_mem_line,R7) |;iterator*words_per_mem_line --> R7
	ADD(R11,R7,R7) 					|;word_offset + iterator*words_per_mem_line --> R7
	MULC(R7,4,R7) 					|;R7 now contains the adress of the *word* to be changed
	ADD(R1,R7,R7) 					|;maze + word_offset + iterator*words_per_mem_line --> R7
	LD(R7,0,R15) 					|;maze[word_offset + i * WORDS_PER_MEM_LINE] --> R15
	AND(R15,R13,R25) 				|;apply the mask
	ST(R25,0,R7) 					|;put the updated word back
	ADDC(R14,1,R14) 				|;iterator++
	BR(horizontal_loop__)

connect_end__:
	POP(R1) 	|;POP maze
	POP(R3) 	|;POP nb_cols	
	POP(R19) 	|;POP neigbour
	POP(R4) 	|;POP visited
	POP(R6) 	|;POP curr_cell for connect
	END()		|;end of connect

|;**********************************************************************************
