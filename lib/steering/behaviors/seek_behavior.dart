import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

final desiredVelocity = new Vector3();


/// This steering behavior produces a force that directs an agent toward a target position.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SeekBehavior extends SteeringBehavior {
  final desiredVelocity = Vector3();

	/// Constructs a new seek behavior.
	SeekBehavior([Vector3? target]):super() {
    this.target = target ?? Vector3();
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final target = this.target;

		// First the desired velocity is calculated.
		// This is the velocity the agent would need to reach the target position in an ideal world.
		// It represents the vector from the agent to the target,
		// scaled to be the length of the maximum possible speed of the agent.
		desiredVelocity.subVectors( target, vehicle.position ).normalize();
		desiredVelocity.multiplyScalar( vehicle.maxSpeed );

		// The steering force returned by this method is the force required,
		// which when added to the agent’s current velocity vector gives the desired velocity.
		// To achieve this you simply subtract the agent’s current velocity from the desired velocity.
		return force.subVectors( desiredVelocity, vehicle.velocity );
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['target'] = target.storage;
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	SeekBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		target.fromArray( json['target'] );
		return this;
	}
}
