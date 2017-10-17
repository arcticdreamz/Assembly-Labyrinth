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

|; Swap the values stored at addresses a and b.
.macro SWAP(Ra,Rb,Rc) MOVE(Rc,Ra) MOVE(Ra,Rb) MOVE(Rb,Rc)

|;Return the row of the cell at given index.
.macro ROW_FROM_INDEX(Ra,Rb,Rc) DIV(Ra,Rb,Rc)

|;Return the column of the cell at given index.
.macro COL_FROM_INDEX(Ra,Rb,Rc) MOD(Ra,Rb,Rc)
|; ***************************************************************
.macro INIT() 	PUSH(LP) PUSH(BP) MOVE(SP,BP)


perfect_maze:
	INIT()
	|; on push les registres qu'on va vouloir utiliser
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


	CMOVE(1,R7)
	MOD(R6,32,R8) |; curr_cell in R6,  (curr_cell % 32) 
	SHL(R7,R8,R7) |; shift 1 (R7) left by R8 bits
	OR(R4,R7,R4) |; update visited(R4)
	|;******** FAUT AJOUTER LES NEIGHBOURS 
		|;	RANDOM()
		|;	PUSH(R0)
		|;	CALL(abs__)
		|;	DEALLOCATE(1)
		|;	MUL(R2, R3, R5)
		|;	MOD(R0, R5, R6)
	COL_FROM_INDEX(R6,R3,R8) |; col in R8
	|; on doit faire ça dynamiquement, i.e. allouer le bon nombre de words
	ALLOCATE(4) |; allocate 4 words in memory for the neighbour array
	CMOVE(0,R9); |; n_valid_neighbours

	|;check left neighbour
	CMPLT(R31,R8,R7) |; 0 < col(R8)
	BF(R7,<PC>+8)
	SUBC(R6,1,R7) |; curr_cell - 1
	MOVE(R7,R20) |; neighbour array start at R20
	|;neighbours[n_valid_neighbours++] = curr_cell - 1;
	ADDC(R9,1,R9) |;n_valid_neighbours++

	|;check right neighbour
	SUBC(R3,1,R7) |; nb_cols - 1
	CMPLT(R8,R7,R7) |; col < nb_cols -1 (R7)
	BF(R7, <PC> +8)
	ADDC(R6,1,R7) |; curr_cell + 1
	|;MOVE(R7,R16) |; 2nd element at R16
	|;neighbours[n_valid_neighbours++] = curr_cell + 1;
	ADDC(R9,1,R9) |;n_valid_neighbours++

	ROW_FROM_INDEX(R6,R5,R8) |; row in R8

	|;check top neighbour
	CMPLT(R31,R8,R7) |; 0 < row(R8)
	BF(R7,<PC>+8)
	SUB(R6,R3,R7) |; curr_cell - nb_cols
	|;MOVE(R7,R17) |; 3rd element at R17
	|;neighbours[n_valid_neighbours++] = curr_cell - nb_cols;
	ADDC(R9,1,R9) |;n_valid_neighbours++


	|;check bottom neighbour
	SUBC(R2,1,R7) |; nb_rows - 1
	CMPLT(R8,R7,R7) |; row < nb_rows -1 (R7)
	BF(R7, <PC> +8)
	ADD(R6,R3,R7) |; curr_cell + nb_cols
	|;MOVE(R7,R18) |; 4th element at R18
	|;neighbours[n_valid_neighbours++] = curr_cell + nb_cols;
	ADDC(R9,1,R9) |;n_valid_neighbours++









	|; RECURSIVITE
	POP(BP)
	POP(LP)
	PUSH(R6) |; push curr_cell/source for connect
	PUSH(R4) |; push visited
	PUSH(R20) |; push neigbour
	PUSH(R3) |; push nb_cols	
	PUSH(R1) |; push maze
	CALL(connect__)

	PUSH(R6) |; curr_cell
	PUSH(R4) |; visited
	PUSH(R3) |; cols
	PUSH(R2) |; rows
	PUSH(R1) |;maze
	CALL(perfect_maze)




connect__:
	INIT()	
	|; on peut remettre dans les registres qu'on veut
	|; on PUSH les registres qu'on veut utiliser
	PUSH(R6) |; push curr_cell/source for connect
	PUSH(R4) |; push visited
	PUSH(R20) |; push neigbour
	PUSH(R3) |; push nb_cols	
	PUSH(R1) |; push maze
	|; on loade les valeurs présentes dans le stack
	|; dans les registres qu'on a push
	LD(BP,-12,R1) |;maze --> R1
	LD(BP,-16,R3) |;nb_cols --> R3
	LD(BP,-20,R20) |;neighbour --> R20
	LD(BP,-24,R4) |;visited --> R4
	LD(BP,-28,R6) |;curr_cell/source --> R6
	

	|; We'll use R7 as a temporary register for most things

	|;*****************************SWAP*************************************
	|; source == curr_cell in R6
	|; dest = neigbour(first element) in R20
	CMPLT(R6,R20,R7) |; make sure source is *before* dest in the maze (source < dest)
	BT(R7,<PC>+4) |; no need to swap, so we jump the swap function
	SWAP(R20,R6,R7)

	|;**********************************************************************
				|;int dest_row = row_from_index(dest, nb_cols);
				|;int row_offset = dest_row * WORDS_PER_ROW;
				|;int source_col = col_from_index(source, nb_cols);
				|;int word_offset_in_line = row_from_index(source_col, CELLS_PER_WORD);
				|;int word_offset = row_offset + word_offset_in_line;
				|;int byte_offset = col_from_index(source_col, CELLS_PER_WORD);
	|;*****************************BYTE AND WORD OFFSET*************************************

	|; TODO: R8 is empty, shift all registers so that R8 is filled again

	ROW_FROM_INDEX(R20,R3,R7)|; dest_row dans R7, R3 contient déjà col (cf main.asm)
	MUL(words_per_row,R7,R11) |; row_offset dans R11
	COL_FROM_INDEX(R6,R3,R7) |;source_col dans R7
	ROW_FROM_INDEX(R7,cells_per_word,R12) |; word_offset_in_line dans R12
	ADD(R11,R12,R11) |; word offset dans R11
	COL_FROM_INDEX(R7,cells_per_word,R12) |; byte_offset dans R12
|;******************************************************************************************

|; *****************************Open vertical connection************************************
vertical__:
	SUB(R20,R6,R7) |; dest-source
	CMPLEC(R7, 1, R7) |; if dest-source <= 1 --> R7 = 1
	BT(R7,horizontal__) |; if R7 == 1 -->  horizontal connection

	CMPEQC(R12,0,R7) |; examine the byte offset
	BF(R7,<PC>+8)
	CMOVE(0xFFFFFF00,R13) |;OPEN_V_0 , we put the mask in R13
	BR(vert_loop_init__)

	CMPEQC(R12,1,R7)
	BF(R7,<PC>+8)
	CMOVE(0xFFFF00FF,R13) |;OPEN_V_1
	BR(vert_loop_init__)

	CMPEQC(R12,2,R7)
	BF(R7,<PC>+8)
	CMOVE(0xFF00FFFF,R13) |;OPEN_V_2
	BR(vert_loop_init__)

	CMOVE(0x00FFFFFF,R13) |;OPEN_V_3
	BR(vert_loop_init__)


vert_loop_init__:
	CMOVE(3,R14) |; initialise the iterator to 3
vert_loop__:
	CMPEQC(R14,7, R7)
	BT(R7,connect_end__)
	MULC(R14,words_per_mem_line,R7) |; calculate the index(like an array) of the word to update
	ADD(R11,R7,R7) |; calculate the index of the word to update
	|; if the first word is at memory adress 64(cf slides), and the adress is +4 for the next one,
	|; we just multiply the  index just gotten by 4 , so we get the word adress
	MULC(R7,4,R7) |; R7 now contains the *ADRESS* of the word to be changed
	LD(R7,R15) |; load the word to R15
	AND(R15,R13,R15) |; apply the mask
	ST(R15,R7) |; put the updated word back
	ADDC(R14,1,R14) |; increment iterator
	BR(vert_loop__)



horizontal__:
	CMPEQC(R12,0,R7) |; examine the byte offset
	BF(R7,<PC>+8)
	CMOVE(0xFFFFFFE1,R13) |;OPEN_H_0 , we put the mask in R13
	BR(horitonzal_loop_init__)

	CMPEQC(R12,1,R7)
	BF(R7,<PC>+8)
	CMOVE(0xFFFFE1FF,R13) |;OPEN_V_1
	BR(horitonzal_loop_init__)

	CMPEQC(R12,2,R7)
	BF(R7,<PC>+8)
	CMOVE(0xFFE1FFFF,R13) |;OPEN_V_2
	BR(horitonzal_loop_init__)

	CMOVE(0xE1FFFFFF,R13) |;OPEN_V_3
	BR(horitonzal_loop_init__)


horitonzal_loop_init__:
	CMOVE(0,R14) |; initialise the iterator to 0
horizontal_loop__:
	CMPEQC(R14,2, R7)
	BT(R7,connect_end__)
	MULC(R14,words_per_mem_line,R7) |; calculate the index(like an array) of the word to update
	ADD(R11,R7,R7) |; calculate the index of the word to update
	|; if the first word is at memory adress 64(cf slides), and the adress is +4 for the next one,
	|; we just multiply the  index just gotten by 4 , so we get the word adress
	MULC(R7,4,R7) |; R7 now contains the *ADRESS* of the word to be changed
	LD(R7,R15) |; load the word to R15
	AND(R15,R13,R15) |; apply the mask
	ST(R15,R7) |; put the updated word back 
	ADDC(R14,1,R14) |; increment iterator
	BR(horizontal_loop__)

connect_end__:
POP(BP)
POP(LP)
POP(R6) |; POP curr_cell/source for connect
POP(R4) |; POP visited
POP(R20) |; POP neigbour
POP(R3) |; POP nb_cols	
POP(R1) |; POP maze
RTN()
