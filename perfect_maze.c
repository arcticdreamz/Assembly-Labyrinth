#include <stdlib.h>
#include <math.h>

const int H_LINE = 0xFFFFFFFF;
const int V_LINE = 0xC0C0C0C0;
const int OPEN_V_0 = 0xFFFFFF00;
const int OPEN_V_1 = 0xFFFF00FF;
const int OPEN_V_2 = 0xFF00FFFF;
const int OPEN_V_3 = 0x00FFFFFF;
const int OPEN_H_0 = 0xFFFFFFE1;
const int OPEN_H_1 = 0xFFFFE1FF;
const int OPEN_H_2 = 0xFFE1FFFF;
const int OPEN_H_3 = 0xE1FFFFFF;

const int NB_ROWS = 8, NB_COLS = 32;
const int NB_CELLS = 256;
const int WORDS_PER_MEM_LINE = 8;
const int MEM_LINES_PER_ROW = 8;
const int WORDS_PER_ROW = 64;
const int NB_MAZE_WORDS = 512; 
const int CELLS_PER_WORD = 4;

/**
 * Swap the values stored at addresses a and b.
 */
void swap(int* a, int* b) {
	int tmp = *a;
	*a = *b;
	*b = tmp;
}

/**
 * Return the row of the cell at given index
 */
int row_from_index(int index, int nb_cols) {
	return index / nb_cols;
}

/**
 * Return the column of the cell at given index
 */
int col_from_index(int index, int nb_cols) {
	return index % nb_cols;
}

/**
 * Opens a connection between two cells.
 */
void connect(int* maze, int source, int dest, int nb_cols) {
	if (source > dest) { // make sure source is *before* dest in the maze (source < dest) 
		swap(&source, &dest);
	}

	int dest_row = row_from_index(dest, nb_cols);
	int row_offset = dest_row * WORDS_PER_ROW;
	int source_col = col_from_index(source, nb_cols);
	int word_offset_in_line = row_from_index(source_col, CELLS_PER_WORD);
	int word_offset = row_offset + word_offset_in_line;
	int byte_offset = col_from_index(source_col, CELLS_PER_WORD); 

	if (dest - source > 1) { // open vertical connection
		int mask;
		if (byte_offset == 0) {
			mask = OPEN_V_0;
		} else if (byte_offset == 1) {
			mask = OPEN_V_1;
		} else if (byte_offset == 2) {
			mask = OPEN_V_2;
		} else {
			mask = OPEN_V_3;
		}

		for (int i = 3; i < 7; ++i) { // four words to update
			maze[word_offset + i * WORDS_PER_MEM_LINE] &= mask;
		}
	} else { // open an horizontal connection
		int mask;
		if (byte_offset == 0) {
			mask = OPEN_H_0;
		} else if (byte_offset == 1) {
			mask = OPEN_H_1;
		} else if (byte_offset == 2) {
			mask = OPEN_H_2;
		} else {
			mask = OPEN_H_3;
		}

		for (int i = 0; i < 2; ++i) { // two words to update
			maze[word_offset + i * WORDS_PER_MEM_LINE] &= mask;
		}
	}
}

/**
 * PARAMETERS
 * ----------
 * maze: address of the first word of the maze
 * nb_rows: number of rows in the maze
 * nb_cols: number of columns in the maze
 * visited: the bitmap indicating which cells were already visited/attached to the maze 
 *	 visited[i] contains 1 if there is a path between c_i and c_start (i.e. the initial cell), 0 otherwise
 * curr_cell: the cell the maze should be constructed from
 */
void perfect_maze(int* maze, int nb_rows, int nb_cols, int* visited, int curr_cell) {
	// set current cell as visited 
	visited[curr_cell / 32] |= (1 << (curr_cell % 32));

	// valid neighbours static array and array size
	int neighbours[4] = {0}, n_valid_neighbours = 0; 

	// check left neighbour
	int col = col_from_index(curr_cell, nb_cols);
	if (col > 0) {
		neighbours[n_valid_neighbours++] = curr_cell - 1;
	}

	// check right neighbour
	if (col < nb_cols - 1) {
		neighbours[n_valid_neighbours++] = curr_cell + 1;
	}

	// check top neighbour
	int row = row_from_index(curr_cell, nb_cols);
	if (row > 0) {
		neighbours[n_valid_neighbours++] = curr_cell - nb_cols;
	}

	// check bottom neighbour
	if (row < nb_rows - 1) {
		neighbours[n_valid_neighbours++] = curr_cell + nb_cols;
	}

	// explore valid neighbours
	while (n_valid_neighbours > 0) {
		int random_neigh_index = rand() % n_valid_neighbours;
		int neighbour = neighbours[random_neigh_index];

		// put the taken neighbour at the end of neighbours array to avoid picking it a second time. 
		swap(neighbours + n_valid_neighbours - 1, neighbours + random_neigh_index);
		n_valid_neighbours--;

		int visited_bit = (visited[neighbour / 32] >> (neighbour % 32)) & 1; 
		if (visited_bit == 1) {
			continue;
		}

		// connect and explore recursively
		connect(maze, curr_cell, neighbour, nb_cols);
		perfect_maze(maze, nb_rows, nb_cols, visited, neighbour);
	} 
}


int main() {
	// reserve some space on the stack 
	int maze[NB_MAZE_WORDS]; 
	int visited[8]; // visited bitmap
	
	// reset bitmap: no cell was added to the maze yet
	for (int i = 0; i < 8; ++i) {
		visited[i] = 0;
	}

	// init fully closed maze
	for (int row = 0; row < NB_ROWS; ++row) {
		int row_offset = row * WORDS_PER_ROW;  
		for (int line = 0; line < MEM_LINES_PER_ROW; ++line) {
			int line_offset = line * WORDS_PER_MEM_LINE;
			for (int word = 0; word < WORDS_PER_MEM_LINE; ++word) {
				int word_offset = row_offset + line_offset + word;
				if (line < 2) {
					maze[word_offset] = H_LINE;  
				} else {
					maze[word_offset] = V_LINE;
				}
			}
		}
	}

	// build random perfect maze 
	int start_cell = rand() % NB_CELLS;
	perfect_maze(maze, NB_ROWS, NB_COLS, visited, start_cell);
	return 0;
}