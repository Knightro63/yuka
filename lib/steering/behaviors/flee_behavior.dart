import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

/// This steering behavior produces a force that steers an agent away from a target position.
/// It's the opposite of {@link SeekBehavior}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}

class FleeBehavior extends SteeringBehavior {
  final desiredVelocity = Vector3();
  double panicDistance;

	/// Constructs a new flee behavior.
	FleeBehavior([Vector3? target, this.panicDistance = 10 ]):super() {
		this.target = target ?? Vector3();
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final target = this.target;

		// only flee if the target is within panic distance
		final distanceToTargetSq = vehicle.position.squaredDistanceTo( target );

		if ( distanceToTargetSq <= ( panicDistance * panicDistance ) ) {
			// from here, the only difference compared to seek is that the desired
			// velocity is calculated using a vector pointing in the opposite direction
			desiredVelocity.subVectors( vehicle.position, target ).normalize();

			// if target and vehicle position are identical, choose default velocity
			if ( desiredVelocity.squaredLength == 0 ) {
				desiredVelocity.set( 0, 0, 1 );
			}

			desiredVelocity.multiplyScalar( vehicle.maxSpeed );
			force.subVectors( desiredVelocity, vehicle.velocity );
		}

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['target'] = target.storage;
		json['panicDistance'] = panicDistance;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	FleeBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		target.fromArray( json['target'] );
		panicDistance = json['panicDistance'];

		return this;
	}
}

