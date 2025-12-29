import '../../math/vector3.dart';
import '../path.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'arrive_behavior.dart';
import 'seek_behavior.dart';

/// This steering behavior produces a force that moves a vehicle along a series of waypoints forming a path.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FollowPathBehavior extends SteeringBehavior {
  late final Path path;
  double nextWaypointDistance;
	final _arrive = ArriveBehavior();
	final _seek = SeekBehavior();

  ArriveBehavior get arrive => _arrive;

	/// Constructs a new follow path behavior.
	FollowPathBehavior([Path? path, this.nextWaypointDistance = 1 ]):super() {
		this.path = path ?? Path();
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final path = this.path;

		// calculate distance in square space from current waypoint to vehicle
		final distanceSq = path.current().squaredDistanceTo( vehicle.position );

		// move to next waypoint if close enough to current target
		if ( distanceSq < ( nextWaypointDistance * nextWaypointDistance ) ) {
			path.advance();
		}

		final target = path.current();

		if ( path.finished() == true ) {
			_arrive.target = target;
			_arrive.calculate( vehicle, force );
		} 
    else {
			_seek.target = target;
			_seek.calculate( vehicle, force );
		}

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['path'] = path.toJSON();
		json['nextWaypointDistance'] = nextWaypointDistance;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	FollowPathBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		path.fromJSON( json['path'] );
		nextWaypointDistance = json['nextWaypointDistance'];

		return this;
	}
}
