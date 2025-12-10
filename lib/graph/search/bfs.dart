import '../core/edge.dart';
import '../core/graph.dart';

/// Implementation of Breadth-first Search.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class BFS {
  Graph? graph;
  int source;
  int target;
  bool found = false;
  final List<Edge> _spanningTree = [];
  final Map _route = {};
  final List _visited = [];

	/// Constructs an AStar algorithm object.
	BFS([Graph? graph, this.source = - 1, this.target = - 1 ]) {
    this.graph = graph ?? Graph();
	}

	/// Executes the graph search. If the search was successful, {@link BFS#found}
	/// is set to true.
	BFS search() {
		// create a queue(FIFO) of edges, done via an array
		final queue = [];
		final outgoingEdges = <Edge>[];

		// create a dummy edge and put on the queue to begin the search
		final startEdge = Edge( source, source );

		queue.add( startEdge );

		// mark the source node as visited
		_visited.add( source );

		// while there are edges in the queue keep searching
		while ( queue.isNotEmpty ) {
			// grab the first edge and remove it from the queue
			final nextEdge = queue.removeAt(0);

			// make a note of the parent of the node this edge points to
			_route[nextEdge.to] = nextEdge.from;

			// expand spanning tree
			if ( nextEdge != startEdge ) {
				_spanningTree.add( nextEdge );
			}

			// if the target has been found the method can return success
			if ( nextEdge.to == target ) {
				found = true;
				return this;
			}

			// determine outgoing edges
			graph?.getEdgesOfNode( nextEdge.to, outgoingEdges );

			// push the edges leading from the node this edge points to onto the
			// queue (provided the edge does not point to a previously visited node)
			for ( int i = 0, l = outgoingEdges.length; i < l; i ++ ) {
				final edge = outgoingEdges[ i ];

				if ( _visited.contains( edge.to ) == false ) {
					queue.add( edge );

					// the node is marked as visited here, BEFORE it is examined,
					// because it ensures a maximum of N edges are ever placed in the queue rather than E edges.
					// (N = number of nodes, E = number of edges)
					_visited.add( edge.to );
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
			currentNode = _route[currentNode];

			// push the new current node at the beginning of the array
			path.insert(0, currentNode );
		}

		return path;
	}

	/// Returns the search tree of the algorithm as an array of edges.
	List<Edge> getSearchTree() {
		return _spanningTree;
	}

	/// Clears the internal state of the object. A new search is now possible.
	BFS clear() {
		found = false;

		_route.clear();
		_visited.clear();
		_spanningTree.clear();

		return this;
	}
}
