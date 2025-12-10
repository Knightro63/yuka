import 'dart:math' as math;
import '../../graph/core/graph.dart';
import '../../math/vector3.dart';
import '../core/nav_edge.dart';
import '../core/nav_node.dart';

/// Class with graph helpers.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class GraphUtils {

	/// Generates a navigation graph with a planar grid layout based on the given parameters.
	static Graph createGridLayout(double size, double segments ) {
		final graph = Graph();
		graph.digraph = true;

		final halfSize = size / 2;
		final segmentSize = size / segments;

		// nodes
		int index = 0;

		for ( int i = 0; i <= segments; i ++ ) {
			final z = ( i * segmentSize ) - halfSize;

			for ( int j = 0; j <= segments; j ++ ) {
				final x = ( j * segmentSize ) - halfSize;
				final position = Vector3( x, 0, z );
				final node = NavNode( index, position );

				graph.addNode( node );
				index ++;
			}
		}

		// edges
		final count = graph.getNodeCount();
		final range = math.pow( segmentSize + ( segmentSize / 2 ), 2 );

		for ( int i = 0; i < count; i ++ ) {
			final node = graph.getNode( i );

			// check distance to all other nodes
			for ( int j = 0; j < count; j ++ ) {
				if ( i != j ) {
					final neighbor = graph.getNode( j )!;
					final distanceSquared = neighbor.position.squaredDistanceTo( node!.position );

					if ( distanceSquared <= range ) {
						final distance = math.sqrt( distanceSquared );
						final edge = NavEdge( i, j, distance );
						graph.addEdge( edge );
					}
				}
			}
		}
		return graph;
	}
}
