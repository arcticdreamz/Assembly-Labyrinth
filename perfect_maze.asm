.include beta.uasm

|; constants
nb_rows = 8
nb_cols = 32
NB_CELLS = 256
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


|;maze --> R1
|;nb_rows --> R2
|;nb_cols --> R3, total number of cells : R5
|;visited --> R4
|;curr_cell --> R6


perfect_maze:


connect__:
	|; We'll use R7 as a temporary registers for most things

	|;*****************************SWAP*************************************
	CMOVE(source,R9)
	CMOVE(dest,R10)
	CMPLT(R9,R10,R7) |; make sure source is *before* dest in the maze (source < dest)
	BT(R7,<PC>+4) |; no need to swap, so we jump the swap function
	SWAP(R10,R9,R7)

	|;**********************************************************************
				|;int dest_row = row_from_index(dest, nb_cols);
				|;int row_offset = dest_row * WORDS_PER_ROW;
				|;int source_col = col_from_index(source, nb_cols);
				|;int word_offset_in_line = row_from_index(source_col, CELLS_PER_WORD);
				|;int word_offset = row_offset + word_offset_in_line;
				|;int byte_offset = col_from_index(source_col, CELLS_PER_WORD);
	|;*****************************BYTE AND WORD OFFSET*************************************

	|; TODO: R8 is empty, shift all registers so that R8 is filled again

	ROW_FROM_INDEX(R10,R3,R7)|; dest_row dans R7, R3 contient déjà col (cf main.asm)
	MUL(words_per_row,R7,R11) |; row_offset dans R11
	COL_FROM_INDEX(R9,R3,R7) |;source_col dans R7
	ROW_FROM_INDEX(R7,cells_per_word,R12) |; word_offset_in_line dans R12
	ADD(R11,R12,R11) |; word offset dans R11
	COL_FROM_INDEX(R7,cells_per_word,R12) |; byte_offset dans R12
|;******************************************************************************************

|; *****************************Open vertical connection************************************
vertical__:
	SUB(R10,R9,R7) |; dest-source
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
	BT(R7,exit__)
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
	BT(R7,exit__)
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

exit__: