import 'package:yuka/graph/core/node.dart';
import 'package:yuka/navigation/navmesh/nav_mesh.dart';
import '../../math/vector3.dart';

/// A lookup table representing the cost associated from traveling from one
/// node to every other node in the navgiation mesh's graph.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CostTable {
  final Map<int,List> _nodeMap = {};

	/// Inits the cost table for the given navigation mesh.
	CostTable init(NavMesh navMesh ) {
		final graph = navMesh.graph;
		final nodes = <Node>[];

		clear();

		// iterate over all nodes
		graph.getNodes( nodes );

		for ( int i = 0, il = nodes.length; i < il; i ++ ) {
			final from = nodes[ i ];

			// compute the distance to all other nodes
			for ( int j = 0, jl = nodes.length; j < jl; j ++ ) {
				final to = nodes[ j ];
				final path = navMesh.findPath( from.position, to.position );
				final cost = computeDistanceOfPath( path );

				set( from.index, to.index, cost );
			}
		}

		return this;
	}

	/// Clears the cost table.
	CostTable clear() {
		_nodeMap.clear();
		return this;
	}

	///Sets the cost for the given pair of navigation nodes.
	CostTable set(int from, int to, cost ) {
		final nodeMap = _nodeMap;

		if ( nodeMap.containsKey( from ) == false ) nodeMap[from] = [];

		final nodeCostMap = nodeMap[from];
		nodeCostMap?[to] = cost;
		return this;
	}

	/// Returns the cost for the given pair of navigation nodes.
	List get(int from, int to ) {
		final nodeCostMap = _nodeMap[from];
		return nodeCostMap?[to];
	}

	/// Returns the size of the cost table (amount of entries).
	int size() {
		return _nodeMap.length;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'nodes': []
		};

		for ( final ent in _nodeMap.entries ) {
      final key = ent.key;
      final value = ent.value;
			json['nodes'].add( { 'index': key, 'costs': value} );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	CostTable fromJSON(Map<String,dynamic> json ) {
		final nodes = json['nodes'];

		for ( int i = 0, l = nodes.length; i < l; i ++ ) {
			final node = nodes[ i ];

			final index = node['index'];
			final costs = node['costs'];

			_nodeMap[index] = costs;
		}

		return this;
	}

  double computeDistanceOfPath(List<Vector3> path ) {
    double distance = 0;

    for ( int i = 0, l = ( path.length - 1 ); i < l; i ++ ) {
      final from = path[ i ];
      final to = path[ i + 1 ];

      distance += from.distanceTo( to );
    }

    return distance;
  }
}

//


