import 'package:yuka/yuka.dart';

class TTTNode extends Node {
  late final List board;

  bool win = false; // whether this node represents a won game
  bool finished = false; // whether this node represents a finished game (win or draw)
  int winPlayer = - 1; // represents the player who wins with the current board, - 1 if there is no winner
  double weight = 0; // used for min/max algorithm
  late int value;
	TTTNode( super.index, [List? board]) {
		// the board is represented as a flat array
		// 1 = cell marked by player 1
		// 2 = cell marked by player 2
		// 9 = cell is empty

		this.board = board ?? [ 9, 9, 9, 9, 9, 9, 9, 9, 9 ];
		value = int.parse( this.board.join( '' ), radix: 10 ); // number representation of the board array for faster comparision
		evaluate();
	}

	void evaluate() {
		// check for win
		// horizontal
		if ( [ board[ 0 ], board[ 1 ], board[ 2 ] ].every( (e){return condition(e,board[ 0 ]);} ) ) {
			finished = true;
			winPlayer = board[ 0 ];
		}

		if ( [ board[ 3 ], board[ 4 ], board[ 5 ] ].every( (e){return condition(e,board[ 3 ]);} ) ) {
			finished = true;
			winPlayer = board[ 3 ];
		}

		if ( [ board[ 6 ], board[ 7 ], board[ 8 ] ].every( (e){return condition(e,board[ 6 ]);} ) ) {
			finished = true;
			winPlayer = board[ 6 ];
		}

		// vertical

		if ( [ board[ 0 ], board[ 3 ], board[ 6 ] ].every( (e){return condition(e,board[ 0 ]);} ) ) {
			finished = true;
			winPlayer = board[ 0 ];
		}

		if ( [ board[ 1 ], board[ 4 ], board[ 7 ] ].every( (e){return condition(e,board[ 1 ]);} ) ) {
			finished = true;
			winPlayer = board[ 1 ];
		}

		if ( [ board[ 2 ], board[ 5 ], board[ 8 ] ].every( (e){return condition(e,board[ 2 ]);} ) ) {
			finished = true;
			winPlayer = board[ 2 ];
		}

		// diagonal

		if ( [ board[ 0 ], board[ 4 ], board[ 8 ] ].every( (e){return condition(e,board[ 0 ]);} ) ) {
			finished = true;
			winPlayer = board[ 0 ];
		}

		if ( [ board[ 6 ], board[ 4 ], board[ 2 ] ].every( (e){return condition(e,board[ 6 ]);} ) ) {
			finished = true;
			winPlayer = board[ 6 ];
		}

		if ( winPlayer != - 1 ) win = true;

		// check for draw
		int count = 0;

		for ( int i = 0; i < 9; i ++ ) {
			if ( board[ i ] != 9 ) {
				count ++;
			}
		}

		if ( count == 9 ) {
			finished = true;
		}
	}

  bool condition( element, i) {
    return ( i == element && element != 9 );
  }
}

