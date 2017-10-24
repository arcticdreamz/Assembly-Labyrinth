source = 94 %R19 ou R16, le plus petit est source
dest =  126
nb_cols = 32;
WORDS_PER_ROW = 64 ;
CELLS_PER_WORD = 4;
dest_row = rowfromindex(dest,nb_cols)
row_offset = dest_row * WORDS_PER_ROW
source_col = colfromindex(source,nb_cols)

word_offset_in_line = rowfromindex(source_col, CELLS_PER_WORD)
word_offset = row_offset + word_offset_in_line
byte_offset = colfromindex(source_col, CELLS_PER_WORD)