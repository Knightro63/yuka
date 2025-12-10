import '../core/edge.dart';
import '../core/graph.dart';

/// Implementation of Depth-first Search.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class DFS {
  Graph? graph;
  int source;
  int target;
  bool found = false;
  final List<Edge> _spanningTree = [];
  final Map _route = {};
  final List _visited = [];

	/// Constructs an AStar algorithm object.
	DFS([Graph? graph, this.source = - 1, this.target = - 1 ]) {
    this.graph = graph ?? Graph();
	}

	/// Executes the graph search. If the search was successful, {@link DFS#found}
	/// is set to true.
	DFS search() {
		// create a stack(LIFO) of edges, done via an array
		final stack = [];
		final outgoingEdges = <Edge>[];

		// create a dummy edge and put on the stack to begin the search
		final startEdge = Edge( source, source );

		stack.add( startEdge );

		// while there are edges in the stack keep searching
		while ( stack.isNotEmpty ) {
			// grab the next edge and remove it from the stack
			final nextEdge = stack.removeLast();

			// make a note of the parent of the node this edge points to
			_route[nextEdge.to] = nextEdge.from;

			// and mark it visited
			_visited.add( nextEdge.to );

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
			// stack (provided the edge does not point to a previously visited node)
			for ( int i = 0, l = outgoingEdges.length; i < l; i ++ ) {
				final edge = outgoingEdges[ i ];

				if ( _visited.contains( edge.to ) == false ) {
					stack.add( edge );
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
	DFS clear() {
		found = false;

		_route.clear();
		_visited.clear();
		_spanningTree.clear();

		return this;
	}
}
