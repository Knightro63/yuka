import '../../math/line_segment.dart';
import '../../math/vector3.dart';
import '../path.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'seek_behavior.dart';

/// This steering behavior produces a force that keeps a vehicle close to its path. It is intended
/// to use it in combination with {@link FollowPathBehavior} in order to realize a more strict path following.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class OnPathBehavior extends SteeringBehavior {
  final translation = Vector3();
  final predictedPosition = Vector3();
  final normalPoint = Vector3();
  final lineSegment = LineSegment();
  final closestNormalPoint = Vector3();

  late final Path path;
  double radius;
  double predictionFactor;
  final _seek = SeekBehavior();

	/// Constructs a on path behavior.
	OnPathBehavior([Path? path, this.radius = 0.1, this.predictionFactor = 1 ]):super() {
		this.path = path ?? Path();
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final path = this.path;

		// predicted future position
		translation.copy( vehicle.velocity ).multiplyScalar( predictionFactor );
		predictedPosition.addVectors( vehicle.position, translation );

		// compute closest line segment and normal point. the normal point is computed by projecting
		// the predicted position of the vehicle on a line segment.
		double minDistance = double.infinity;
		int l = path.waypoints.length;

		// handle looped paths differently since they have one line segment more

		l = ( path.loop == true ) ? l : l - 1;

		for ( int i = 0; i < l; i ++ ) {
			lineSegment.from = path.waypoints[ i ];

			// the last waypoint needs to be handled differently for a looped path.
			// connect the last point with the first one in order to create the last line segment

			if ( path.loop == true && i == ( l - 1 ) ) {
				lineSegment.to = path.waypoints[ 0 ];
			}
      else {
				lineSegment.to = path.waypoints[ i + 1 ];
			}

			lineSegment.closestPointToPoint( predictedPosition, true, normalPoint );

			final distance = predictedPosition.squaredDistanceTo( normalPoint );

			if ( distance < minDistance ) {
				minDistance = distance;
				closestNormalPoint.copy( normalPoint );
			}
		}

		// seek towards the projected point on the closest line segment if
		// the predicted position of the vehicle is outside the valid range.
		// also ensure that the path length is greater than zero when performing a seek

		if ( minDistance > ( radius * radius ) && path.waypoints.length > 1 ) {
			_seek.target = closestNormalPoint;
			_seek.calculate( vehicle, force );
		}

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['path'] = path.toJSON();
		json['radius'] = radius;
		json['predictionFactor'] = predictionFactor;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	OnPathBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		path.fromJSON( json['path'] );
		radius = json['radius'];
		predictionFactor = json['predictionFactor'];

		return this;
	}
}
