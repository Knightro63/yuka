import 'edge.dart';
import 'node.dart';

/// Class representing a sparse graph implementation based on adjacency lists.
/// A sparse graph can be used to model many different types of graphs like navigation
/// graphs (pathfinding), dependency graphs (e.g. technology trees) or state graphs
/// (a representation of every possible state in a game).
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Graph {
  bool digraph = false;
  final Map<int,Node> _nodes = {};
  final Map<int,List<Edge>> _edges = {};

	/// Adds a node to the graph.
	Graph addNode(Node node ) {
		int index = node.index;

		_nodes[index] = node ;
		_edges[index] = [];

		return this;
	}

	/// Adds an edge to the graph. If the graph is undirected, the method
	/// automatically creates the opponent edge.
	Graph addEdge(Edge edge ) {
		List<Edge>? edges = _edges[edge.from];
		edges?.add( edge );

		if ( digraph == false ) {
			final oppositeEdge = edge.clone();

			oppositeEdge.from = edge.to;
			oppositeEdge.to = edge.from;

			edges = _edges[edge.to];
			edges?.add( oppositeEdge );
		}

		return this;
	}

	/// Returns a node for the given node index. If no node is found,
	/// *null* is returned.
	Node? getNode(int index ) {
		return _nodes[index];
	}

	/// Returns an edge for the given *from* and *to* node indices.
	/// If no node is found, *null* is returned.
	Edge? getEdge(int from, int to ) {
		if (hasNode( from ) && hasNode( to ) ) {
			final edges = _edges[from];

			for ( int i = 0, l = (edges?.length ?? 0); i < l; i ++ ) {
				final edge = edges?[ i ];

				if ( edge?.to == to ) {
					return edge;
				}
			}
		}

		return null;
	}

	/// Gathers all nodes of the graph and stores them into the given array.
	List<Node> getNodes(List<Node> result ) {
		result.length = 0;
		result.addAll( _nodes.values );

		return result;
	}

	/// Gathers all edges leading from the given node index and stores them
	/// into the given array.
	List<Edge> getEdgesOfNode(int index, List<Edge> result ) {
		final edges = _edges[index];

		if ( edges != null ) {
			result.length = 0;
			result.addAll( edges );
		}

		return result;
	}

	//// Returns the node count of the graph.
	int getNodeCount() {
		return _nodes.length;
	}

	/// Returns the edge count of the graph.
	int getEdgeCount() {
		int count = 0;

		for ( final edges in _edges.values ) {
			count += edges.length;
		}

		return count;
	}

	/// Removes the given node from the graph and all edges which are connected
	/// with this node.
	Graph removeNode(Node node ) {
		_nodes.remove( node.index );

		if ( digraph == false ) {
			// if the graph is not directed, remove all edges leading to this node
			final edges = _edges[node.index];

			for ( final edge in edges! ) {
				final edgesOfNeighbor = _edges[edge.to];

				for ( int i = ( (edgesOfNeighbor?.length ?? 0) - 1 ); i >= 0; i -- ) {
					final edgeNeighbor = edgesOfNeighbor![ i ];

					if ( edgeNeighbor.to == node.index ) {
						final index = edgesOfNeighbor.indexOf( edgeNeighbor );
						edgesOfNeighbor.removeAt( index );

						break;
					}
				}
			}
		} 
    else {
			// if the graph is directed, remove the edges the slow way
			for ( final edges in _edges.values ) {
				for ( int i = ( edges.length - 1 ); i >= 0; i -- ) {
					final edge = edges[ i ];

					if ( !hasNode( edge.to ) || !hasNode( edge.from ) ) {
						final index = edges.indexOf( edge );
						edges.removeAt( index );
					}
				}
			}
		}

		// delete edge list of node (edges leading from this node)
		_edges.remove( node.index );
		return this;
	}

	/// Removes the given edge from the graph. If the graph is undirected, the
	/// method also removes the opponent edge.
	Graph removeEdge(Edge edge ) {
		// delete the edge from the node's edge list
		final edges = _edges[edge.from];

		if ( edges != null ) {
			final index = edges.indexOf( edge );
			edges.removeAt( index );

			// if the graph is not directed, delete the edge connecting the node in the opposite direction
			if ( digraph == false ) {
				final edges = _edges[edge.to];

				for ( int i = 0, l = (edges?.length ?? 0); i < l; i ++ ) {
					final e = edges![ i ];

					if ( e.to == edge.from ) {
						final index = edges.indexOf( e );
						edges.removeAt( index );
						break;
					}
				}
			}
		}

		return this;
	}

	/// Return true if the graph has the given node index.
	bool hasNode(int index ) {
		return _nodes.containsKey( index );
	}

	/// Return true if the graph has an edge connecting the given
	/// *from* and *to* node indices.
	bool hasEdge(int from, int to ) {
		if ( hasNode( from ) && hasNode( to ) ) {
			final edges = _edges[from];

			for ( int i = 0, l = (edges?.length ?? 0); i < l; i ++ ) {
				final edge = edges![ i ];

				if ( edge.to == to ) {
					return true;
				}
			}

			return false;
		} 
    else {
			return false;
		}
	}

	/// Removes all nodes and edges from this graph.
	Graph clear() {
		_nodes.clear();
		_edges.clear();

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'digraph': digraph
		};

		final edges = [];
		final nodes = [];

		for (final ent in _nodes.entries ) {
      final key = ent.key;
      final value = ent.value;
			final adjacencyList = <Edge>[];
			getEdgesOfNode( key, adjacencyList );

			for ( int i = 0, l = adjacencyList.length; i < l; i ++ ) {
				edges.add( adjacencyList[ i ].toJSON() );
			}

			nodes.add( value.toJSON() );
		}

		json['_edges'] = edges;
		json['_nodes'] = nodes;

		return json;
	}

	/// Restores this instance from the given JSON object.
	Graph fromJSON(Map<String,dynamic> json ) {
		digraph = json['digraph'];

		for ( int i = 0, l = json['_nodes'].length; i < l; i ++ ) {
			addNode( Node().fromJSON( json['_nodes'][ i ] ) );
		}

		for ( int i = 0, l = json['_edges'].length; i < l; i ++ ) {
			addEdge( Edge().fromJSON( json['_edges'][ i ] ) );
		}

		return this;
	}
}