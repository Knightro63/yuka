import '../core/edge.dart';
import '../core/graph.dart';
import '../extra/priority_queue.dart';

/// Implementation of Dijkstra's algorithm.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Dijkstra {
  Graph? graph;
  int source;
  int target;
  bool found = false;
  final Map _cost = {};
  final Map<int,Edge> _shortestPathTree = {};
  final Map _searchFrontier = {};

	/// Constructs an AStar algorithm object.
	Dijkstra([Graph? graph, this.source = - 1, this.target = - 1 ]) {
    this.graph = graph ?? Graph();
	}

	/// Executes the graph search. If the search was successful, {@link Dijkstra#found}
  /// is set to true.
	Dijkstra search() {
		final outgoingEdges = <Edge>[];
		final pQueue = PriorityQueue( compare );

		pQueue.push( {
			'cost': 0,
			'index': source
		} );

		// while the queue is not empty
		while ( pQueue.length > 0 ) {
			final nextNode = pQueue.pop();
			final nextNodeIndex = nextNode['index'];

			// if the shortest path tree has the given node, we already found the shortest
			// path to this particular one
			if ( _shortestPathTree.containsKey( nextNodeIndex ) ) continue;

			// move this edge from the frontier to the shortest path tree
			if ( _searchFrontier.containsKey( nextNodeIndex ) == true ) {
				_shortestPathTree[nextNodeIndex] = _searchFrontier[nextNodeIndex];
			}

			// if the target has been found exit

			if ( nextNodeIndex == target ) {
				found = true;
				return this;
			}

			// now relax the edges
			graph?.getEdgesOfNode( nextNodeIndex, outgoingEdges );

			for ( int i = 0, l = outgoingEdges.length; i < l; i ++ ) {
				final edge = outgoingEdges[ i ];

				// the total cost to the node this edge points to is the cost to the
				// current node plus the cost of the edge connecting them.
				final newCost = ( _cost[nextNodeIndex] ?? 0 ) + edge.cost;

				// We enhance our search frontier in two cases:
				// 1. If the node was never on the search frontier
				// 2. If the cost to this node is better than before
				if ( ( _searchFrontier.containsKey( edge.to ) == false ) || newCost < ( _cost[edge.to] ) ) {
					_cost[edge.to] = newCost;
					_searchFrontier[edge.to] = edge;
					pQueue.push( {
						'cost': newCost,
						'index': edge.to
					} );
				}
			}
		}

		found = false;

		return this;
	}

	/// Returns the shortest path from the source to the target node as an array of node indices.
	List<int> getPath() {
		// array of node indices that comprise the shortest path from the source to the target
		final path = <int>[];

		// just return an empty path if no path to target found or if no target has been specified
		if ( found == false || target == - 1 ) return path;

		// start with the target of the path
		int currentNode = target;

		path.add( currentNode );

		// while the current node is not the source node keep processing
		while ( currentNode != source ) {
			// determine the parent of the current node
			currentNode = _shortestPathTree[currentNode]!.from;

			// push the new current node at the beginning of the array
			path.insert(0, currentNode );
		}

		return path;
	}

	/// Returns the search tree of the algorithm as an array of edges.
	List<Edge> getSearchTree() {
		return _shortestPathTree.values.toList();
	}

	/// Clears the internal state of the object. A new search is now possible.
	Dijkstra clear() {
		found = false;

		_cost.clear();
		_shortestPathTree.clear();
		_searchFrontier.clear();

		return this;
	}

  int compare(Map<String,dynamic> a, Map<String,dynamic> b ) {
    return ( a['cost'] < b['cost'] ) ? - 1 : ( a['cost'] > b['cost'] ) ? 1 : 0;
  }
}
