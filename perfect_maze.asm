.include beta.uasm
.include main.asm
 |; ***************************************************************
|; constants
nb_rows = 8
nb_cols = 32
nb_cells = 256
words_per_mem_line = 8
mem_lines_per_row = 8
words_per_row = 64
nb_maze_words = 512
cells_per_word = 4


|; Reg[Rc] <- Reg[Ra] mod Reg[Rb] (Rc should be different from Ra and Rb)
.macro MOD(Ra, Rb, Rc) DIV(Ra, Rb, Rc) MUL(Rc, Rb, Rc) SUB(Ra, Rc, Rc)

.macro MODC(Ra, CC, Rc) DIVC(Ra, CC, Rc) MULC(Rc, CC, Rc) SUB(Ra, Rc, Rc)

|; Swap the values stored at addresses a and b.
.macro SWAP(Ra,Rb,Rc) MOVE(Rc,Ra) MOVE(Ra,Rb) MOVE(Rb,Rc)

|;Return the row of the cell at given index.
.macro ROW_FROM_INDEX(Ra,Rb,Rc) DIV(Ra,Rb,Rc)

|;Return the column of the cell at given index.
.macro COL_FROM_INDEX(Ra,Rb,Rc) MOD(Ra,Rb,Rc)

.macro INIT() 	PUSH(LP) PUSH(BP) MOVE(SP,BP)

.macro END() MOVE(BP,SP) POP(BP) POP(LP) RTN()







|;allocate 4 words in memory for the neighbour array
neighbours: ALLOCATE(4) 


perfect_maze:
	INIT()
	CMOVE(neighbours,R20)

	PUSH(R1) 
	PUSH(R2)
	PUSH(R3)
	PUSH(R4)
	PUSH(R6)

	|; on loade les valeurs du stack dans les registres
	LD(BP,-12,R1) |;maze --> R1
	LD(BP,-16,R2) |;nb_rows --> R2
	LD(BP,-20,R3) |;nb_cols --> R3
	LD(BP,-24,R4) |;visited --> R4
	LD(BP,-28,R6) |;curr_cell --> R6


 |;update_visited
	CMOVE(1,R7)
	MODC(R6,32,R8) |; curr_cell in R6, (curr_cell % 32) 
	SHL(R7,R8,R7) |; shift 1 (R7) left by R8 bits
	DIVC(R6,8,R8) |; curr_cell/32 * 4
	|;******* FAUT METTRE CC ET PAS UN REGISTRE SI CA MARCHE PAS
	LD(R4,R8,R8) |; R8 = visited(R4)+offset(R8)
	OR(R8,R7,R8) |; update visited+offset

init_neighbours:	
	LD(R20,0,R7)
	ST(R31,0,R7)

	LD(R20,4,R7)
	ST(R31,4,R7) 

	LD(R20,8,R7)
	ST(R31,8,R7)

	LD(R20,12,R7)
	ST(R31,12,R7)




	COL_FROM_INDEX(R6,R3,R8) |; col in R8
	CMOVE(0,R9) |; n_valid_neighbours

checkLeft: 
	CMPLE(R31,R8,R7) |; 0 <= col(R8) ? Si faux, on l'ajoute
	BT(R7,checkRight)
	SUBC(R6,1,R7) |; curr_cell - 1
	LD(R20,R9,R10) 
	ST(R7,R9,R10)  |;neighbours[n_valid_neighbours++] = curr_cell - 1;
	ADDC(R9,4,R9) |;n_valid_neighbours++

checkRight:
	|;check right neighbour
	SUBC(R3,1,R7) |; nb_cols - 1
	CMPLT(R8,R7,R7) |; col < nb_cols -1 (R7)
	BF(R7,checkTop)
	ADDC(R6,1,R7) |; curr_cell + 1
	LD(R20,R9,R10)
	ST(R7,R9,R10)
	ADDC(R9,4,R9) |;n_valid_neighbours++

	ROW_FROM_INDEX(R6,R5,R8) |; row in R8
checkTop:
	|;check top neighbour
	CMPLE(R31,R8,R7) |; 0 <= row(R8) ? Si faux, on l'ajoute
	BT(R7,checkBottom)
	SUB(R6,R3,R7) |; curr_cell - nb_cols
	LD(R20,R9,R10)
	ST(R7,R9,R10)
	ADDC(R9,4,R9) |;n_valid_neighbours++

checkBottom:
	|;check bottom neighbour
	SUBC(R2,1,R7) |; nb_rows - 1
	CMPLT(R8,R7,R7) |; row < nb_rows -1 (R7)
	BF(R7,while_loop)
	ADD(R6,R3,R7) |; curr_cell + nb_cols
	LD(R20,R9,R10)
	ST(R7,R9,R10)
	ADDC(R9,4,R9) |;n_valid_neighbours++

while_loop:
	CMPLTC(R9,0,R7) |; n_valid_neighbours <= 0? Si vrai, on sort
	BT(R7,perfect_maze_end)
	|; randomly select one neighbour
	RANDOM()
	PUSH(R0)
	CALL(abs__)
	DEALLOCATE(1)

	DIVC(R9,4,R7) |; n_valid_neighbours/4
	MOD(R0,R7,R7) |; random_neigh_index (random % n_valid_neighbours/4)
	MULC(R7,4,R7) |; random_neigh_index_offset (0 4 8 12)
	LD(R20,R7,R19) |;neighbour = R8

	SUBC(R9,4,R11) |; n_valid_neighbours - 1 
	LD(R20,R11,R11) |; neighbours + n_valid_neighbours - 1
	LD(R20,R7,R12) |; neighbours + random_neigh_index
	SWAP(R11,R12,R7)
	SUBC(R9,4,R9) |; n_valid_neigbours--

	MODC(R19,32,R7) |; neighbour % 32
	DIVC(R19,8,R8) |; neighbour/32 * 4
	LD(R4,R8,R8) |; visited[neighbour/32]
	|; VERIFIER QU?ON EST BIEN EN LITTLB ENDIAN/BIG ENDIAN
	SHR(R8,R7,R8) |; Shift bitmap vers la droite de (neighbour % 32)
	ANDC(R8,1,R8) |; visited_bit = R8
	CMPEQC(R8,1,R7)
	BT(R7,while_loop)






	|; RECURSIVITE

	PUSH(R6) |; push curr_cell/source for connect
	PUSH(R4) |; push visited
	PUSH(R19) |; push neigbour (=! neighbours)
	PUSH(R3) |; push nb_cols	
	PUSH(R1) |; push maze
	CALL(connect__)			
	DEALLOCATE(5)

	PUSH(R6) |; curr_cell
	PUSH(R4) |; visited
	PUSH(R3) |; cols
	PUSH(R2) |; rows
	PUSH(R1) |;maze
	CALL(perfect_maze)
	DEALLOCATE(5)

perfect_maze_end:
	POP(R6)
	POP(R4)
	POP(R3)
	POP(R2)
	POP(R1)	
	END()



connect__:
	INIT()	
	|; on peut remettre dans les registres qu'on veut
	|; on PUSH les registres qu'on veut utiliser
	PUSH(R6) |; push curr_cell/source for connect
	PUSH(R4) |; push visited
	PUSH(R19) |; push neigbour
	PUSH(R3) |; push nb_cols	
	PUSH(R1) |; push maze
	|; on loade les valeurs présentes dans le stack
	|; dans les registres qu'on a push
	LD(BP,-12,R1) |;maze --> R1
	LD(BP,-16,R3) |;nb_cols --> R3
	LD(BP,-20,R19) |;neighbour --> R19
	LD(BP,-24,R4) |;visited --> R4
	LD(BP,-28,R6) |;curr_cell/source --> R6
	

	|; We'll use R7 as a temporary register for most things

	|; source == curr_cell in R6
	|; dest = neigbour in R19
	CMPLT(R6,R19,R7) |; make sure source is *before* dest in the maze (source < dest)
	BT(R7,byte_offset) |; no need to swap, so we jump the swap function
	SWAP(R19,R6,R7)

byte_offset:
	ROW_FROM_INDEX(R19,R3,R7)|; dest_row dans R7, R3 contient déjà col (cf main.asm)
	MUL(words_per_row,R7,R11) |; row_offset dans R11
	COL_FROM_INDEX(R6,R3,R7) |;source_col dans R7
	ROW_FROM_INDEX(R7,cells_per_word,R12) |; word_offset_in_line dans R12
	ADD(R11,R12,R11) |; word offset dans R11
	COL_FROM_INDEX(R7,cells_per_word,R12) |; byte_offset dans R12
|;******************************************************************************************

|; *****************************Open vertical connection************************************
vertical__:
	SUB(R19,R6,R7) |; dest-source
	CMPLEC(R7, 1, R7) |; if dest-source <= 1 --> R7 = 1
	BT(R7,horizontal__) |; if R7 == 1 -->  horizontal connection

	CMPEQC(R12,0,R7) |; examine the byte offset
	BF(R7,openV1)
	CMOVE(0xFFFFFF00,R13) |;OPEN_V_0 , we put the mask in R13
	BR(vert_loop_init__)

openV1: 
	CMPEQC(R12,1,R7)
	BF(R7,openV2)
	CMOVE(0xFFFF00FF,R13) |;OPEN_V_1
	BR(vert_loop_init__)

openV2:
	CMPEQC(R12,2,R7)
	BF(R7,openV3)
	CMOVE(0xFF00FFFF,R13) |;OPEN_V_2
	BR(vert_loop_init__)

openV3:
	CMOVE(0x00FFFFFF,R13) |;OPEN_V_3
	


vert_loop_init__:
	CMOVE(3,R14) |; initialise the iterator to 3
vert_loop__:
	CMPEQC(R14,7, R7)
	BT(R7,connect_end__)

	MULC(R14,words_per_mem_line,R7) |; iterator*words_per_mem_line
	ADD(R11,R7,R7) |; word_offset + iterator*words_per_mem_line
	
	MULC(R7,4,R7) |; R7 now contains the adress of the *word* to be changed
	LD(R1,R7,R15) |; load the word to R15
	AND(R15,R13,R15) |; apply the mask
	ST(R15,R7,R1) |; put the updated word back
	ADDC(R14,1,R14) |; increment iterator
	BR(vert_loop__)
|;*************************************************************


horizontal__:
	CMPEQC(R12,0,R7) |; examine the byte offset
	BF(R7,openH1)
	CMOVE(0xFFFFFFE1,R13) |;OPEN_H_0 , we put the mask in R13
	BR(horitonzal_loop_init__)

openH1:
	CMPEQC(R12,1,R7)
	BF(R7,openH2)
	CMOVE(0xFFFFE1FF,R13) |;OPEN_H_1
	BR(horitonzal_loop_init__)
openH2:
	CMPEQC(R12,2,R7)
	BF(R7,openH3)
	CMOVE(0xFFE1FFFF,R13) |;OPEN_H_2
	BR(horitonzal_loop_init__)
openH3:
	CMOVE(0xE1FFFFFF,R13) |;OPEN_H_3


horitonzal_loop_init__:
	CMOVE(0,R14) |; initialise the iterator to 0
horizontal_loop__:
	CMPEQC(R14,2, R7)
	BT(R7,connect_end__)
	
	MULC(R14,words_per_mem_line,R7) |; iterator*words_per_mem_line
	ADD(R11,R7,R7) |; word_offset + iterator*words_per_mem_line

	MULC(R7,4,R7) |; R7 now contains the adress of the *word* to be changed
	LD(R1,R7,R15) |; load the word to R15
	AND(R15,R13,R15) |; apply the mask
	ST(R15,R7,R1) |; put the updated word back
	ADDC(R14,1,R14) |; increment iterator
	BR(horizontal_loop__)

connect_end__:
POP(R1) |; POP maze
POP(R3) |; POP nb_cols	
POP(R19) |; POP neigbour
POP(R4) |; POP visited
POP(R6) |; POP curr_cell/source for connect
END()


