import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'dart:math' as math;

/// This steering behavior produces a force that directs an agent toward a target position.
/// Unlike {@link SeekBehavior}, it decelerates so the agent comes to a gentle halt at the target position.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class ArriveBehavior extends SteeringBehavior {
  final desiredVelocity = Vector3();
  final displacement = Vector3();
  double deceleration;
  double tolerance;

	/// Constructs a new arrive behavior.
	ArriveBehavior([Vector3? target, this.deceleration = 3, this.tolerance = 0 ]):super() {
		this.target = target ?? Vector3();
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final target = this.target;
		final deceleration = this.deceleration;

		displacement.subVectors( target, vehicle.position );

		final distance = displacement.length;

		if ( distance > tolerance ) {
			// calculate the speed required to reach the target given the desired deceleration
			double speed = distance / deceleration;

			// make sure the speed does not exceed the max
			speed = math.min( speed, vehicle.maxSpeed );

			// from here proceed just like "seek" except we don't need to normalize
			// the "displacement" vector because we have already gone to the trouble
			// of calculating its length.
			desiredVelocity.copy( displacement ).multiplyScalar( speed / distance );
		} 
    else {
			desiredVelocity.set( 0, 0, 0 );
		}

		return force.subVectors( desiredVelocity, vehicle.velocity );
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['target'] = target.storage;
		json['deceleration'] = deceleration;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	ArriveBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		target.fromArray( json['target'] );
		deceleration = json['deceleration'];

		return this;
	}
}
