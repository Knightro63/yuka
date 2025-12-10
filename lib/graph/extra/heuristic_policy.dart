import '../core/graph.dart';

/// Class for representing a heuristic for graph search algorithms based
/// on the euclidean distance. The heuristic assumes that the node have
/// a *position* property of type {@link Vector3}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HeuristicPolicyEuclid {
	/// Calculates the euclidean distance between two nodes.
	static double calculate(Graph graph, int source, int target ) {
		final sourceNode = graph.getNode( source )!;
		final targetNode = graph.getNode( target )!;
		return sourceNode.position.distanceTo( targetNode.position );
	}
}

/// Class for representing a heuristic for graph search algorithms based
/// on the squared euclidean distance. The heuristic assumes that the node
/// have a *position* property of type {@link Vector3}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HeuristicPolicyEuclidSquared {
	/// Calculates the squared euclidean distance between two nodes.
	static double calculate(Graph graph, int source, int target ) {
		final sourceNode = graph.getNode( source )!;
		final targetNode = graph.getNode( target )!;
		return sourceNode.position.squaredDistanceTo( targetNode.position );
	}
}

/// Class for representing a heuristic for graph search algorithms based
/// on the manhattan distance. The heuristic assumes that the node
/// have a *position* property of type {@link Vector3}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HeuristicPolicyManhattan {
	/// Calculates the manhattan distance between two nodes.
	static double calculate(Graph graph, int source, int target ) {
		final sourceNode = graph.getNode( source )!;
		final targetNode = graph.getNode( target )!;
		return sourceNode.position.manhattanDistanceTo( targetNode.position );
	}
}

/// Class for representing a heuristic for graph search algorithms based
/// on Dijkstra's algorithm.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HeuristicPolicyDijkstra {
	/// This heuristic always returns *0*. The {@link AStar} algorithm
	/// behaves with this heuristic exactly like {@link Dijkstra}
	static double calculate(Graph graph, int source, int target ) {
		return 0;
	}
}
