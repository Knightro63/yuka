
import 'dart:math' as math;
import 'package:examples/graph/ttt_edge.dart';
import 'package:examples/graph/ttt_node.dart';
import 'package:yuka/yuka.dart';

final arrayTurn = <Edge>[];

class TTTGraph extends Graph {
  int humanPlayer;
  int currentNode = - 1;
  int nextNode = 0;
  int currentPlayer = 1;
  late int aiPlayer;

  Map<String,dynamic> nodeMap = {};

	TTTGraph( [this.humanPlayer = 1] ):super() {
		digraph = true;
		currentNode = - 1;
		nextNode = 0;

		currentPlayer = 1;
		aiPlayer = nextPlayer( humanPlayer );

		init( );
	}

	void init( ) {
		final node = TTTNode( nextNode ++ );
		addNode( node );
		currentNode = node.index;
		// start generation of game state graph
		generate( node.index, currentPlayer );
	}

  @override
	addNode( node ) {
		nodeMap[node.value] = node.index;
		return super.addNode( node );
	}

	generate(int nodeIndex, int activePlayer ) {
		final node = getNode( nodeIndex );
		final weights = [];

		for ( int i = 0; i < 9; i ++ ) {
			if ( node.board[ i ] == 9 ) {
				// determine the next board and check if there is already a
				// respective node
				final nextBoard = getNextBoard( node, i, activePlayer );
				let activeNodeIndex = findNode( nextBoard );

				if ( activeNodeIndex == - 1 ) {
					// there is no node representing the next board so let's create
					// a new one

					final nextNode = TTTNode( this.nextNode ++, nextBoard );
					addNode( nextNode );
					activeNodeIndex = nextNode.index;

					// link the current node to the next one

					final edge = TTTEdge( nodeIndex, activeNodeIndex, i, activePlayer );
					addEdge( edge );

					// check if the next node represents a finished game

					if ( nextNode.finished == true ) {
						// if so, then compute the weight for this node and store it
						// in the current weights array
						computeWeight( nextNode );
						weights.add( nextNode.weight );
					} 
          else {
						// if not, recursively call "generate()" to continue the build of the graph
						weights.add( generate( activeNodeIndex, nextPlayer( activePlayer ) ) );
					}
				} 
        else {
					// there is already a node representing the next board
					// in this case we should link to it with a new edge and update the weights
					final edge = TTTEdge( nodeIndex, activeNodeIndex, i, activePlayer );
					addEdge( edge );

					final nextNode = getNode( activeNodeIndex );
					weights.add( nextNode.weight );
				}
			}
		}

		// update weight for the current node
		if ( activePlayer == aiPlayer ) {
			node.weight = math.max( ...weights );
			return node.weight;
		} 
    else {
			node.weight = math.min( ...weights );
			return node.weight;
		}
	}

	aiTurn() {
		final currentWeight = getNode( currentNode ).weight;

		// perform best possible move
		final possibleMoves = [];
		getEdgesOfNode( currentNode, possibleMoves );
		dynamic bestMove;

		for ( int i = 0, l = possibleMoves.length; i < l; i ++ ) {
			final move = possibleMoves[ i ];
			final node = getNode( move.to );

			if ( node.weight == currentWeight ) {
				// check if the AI can immediately finish the game

				if ( node.finished ) {
					// if so, perform the move
					turn( move.cell, aiPlayer );
					return;
				} 
				bestMove ??= move;
			}
		}

		turn( bestMove.cell, aiPlayer );
	}

	getNextBoard( node, cell, player ) {
		final board = node.board.slice();
		board[ cell ] = player;
		return board;
	}

	nextPlayer( currentPlayer ) {
		return ( currentPlayer % 2 ) + 1;
	}

	findNode( board ) {
		final value = int.parse( board.join( '' ), radix: 10 );
		final node = nodeMap.get( value );

		return node ? node : - 1;
	}

	turn( cell, player ) {
		arrayTurn.length = 0;
		getEdgesOfNode( currentNode, arrayTurn );

		for ( int i = 0, l = arrayTurn.length; i < l; i ++ ) {
			final edge = arrayTurn[ i ];

			if ( edge.cell == cell && edge.player == player ) {
				currentNode = edge.to;
				currentPlayer = nextPlayer( player );
				break;
			}
		}
	}

	// called for node that represents an end of the game (win/draw)
	computeWeight(Map node ) {
		if ( node['win'] ) {
			if ( node['winPlayer'] == aiPlayer ) {
				node['weight'] = 100;
			} else {
				node['weight'] = - 100;
			}
		} 
    else {
			node['weight'] = 0;
		}
	}
}
