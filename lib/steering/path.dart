import '../math/vector3.dart';

/// Class for representing a walkable path.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Path {
  bool loop = false;
  int _index = 0;
  final List<Vector3> waypoints = [];

	/// Adds the given waypoint to this path.
	Path add(Vector3 waypoint ) {
		waypoints.add( waypoint );
		return this;
	}

	/// Clears the internal state of this path.
	Path clear() {
		waypoints.clear();
		_index = 0;

		return this;
	}

	/// Returns the current active waypoint of this path.
	Vector3 current() {
		return waypoints[ _index ];
	}

	/// Returns true if this path is not looped and the last waypoint is active.
	bool finished() {
		final lastIndex = waypoints.length - 1;
		return loop == true ? false : ( _index == lastIndex );
	}

	/// Makes the next waypoint of this path active. If the path is looped and
	/// returns true, the path starts from the beginning.
	Path advance() {
		_index ++;

		if ( ( _index == waypoints.length ) ) {
			if ( loop == true ) {
				_index = 0;
			} 
      else {
				_index --;
			}
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> data = {
			'type': runtimeType.toString(),
			'loop': loop,
			'_waypoints': [],
			'_index': _index
		};

		// waypoints
		final waypoints = this.waypoints;

		for ( int i = 0, l = waypoints.length; i < l; i ++ ) {
			final waypoint = waypoints[ i ];
			data['_waypoints'].add( waypoint.storage );
		}

		return data;
	}

	/// Restores this instance from the given JSON object.
	Path fromJSON(Map<String,dynamic> json ) {
		loop = json['loop'];
		_index = json['_index'];

		// waypoints
		final waypointsJSON = json['_waypoints'];

		for ( int i = 0, l = waypointsJSON.length; i < l; i ++ ) {
			final waypointJSON = waypointsJSON[ i ];
			waypoints.add( Vector3().fromArray( waypointJSON ) );
		}

		return this;
	}
}
