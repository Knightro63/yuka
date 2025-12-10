import '../../constants.dart';
import '../../core/game_entity.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'arrive_behavior.dart';

/// This steering behavior produces a force that keeps a vehicle at a specified offset from a leader vehicle.
/// Useful for creating formations.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class OffsetPursuitBehavior extends SteeringBehavior {
  final offsetWorld = Vector3();
  final toOffset = Vector3();
  final newLeaderVelocity = Vector3();
  final predictedPosition = Vector3();

  Vehicle? leader;
  late final Vector3 offset;
  final _arrive = ArriveBehavior();

	/// Constructs a offset pursuit behavior.
	OffsetPursuitBehavior([ this.leader, Vector3? offset]):super() {
		this.offset = offset ?? Vector3();
		_arrive.deceleration = 1.5;
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final leader = this.leader!;
		final offset = this.offset;

		// calculate the offset's position in world space
		offsetWorld.copy( offset ).applyMatrix4( leader.worldMatrix() );

		// calculate the vector that points from the vehicle to the offset position
		toOffset.subVectors( offsetWorld, vehicle.position );

		// the lookahead time is proportional to the distance between the leader
		// and the pursuer and is inversely proportional to the sum of both
		// agent's velocities
		final lookAheadTime = toOffset.length / ( vehicle.maxSpeed + leader.getSpeed() );

		// calculate velocity and predicted future position
		newLeaderVelocity.copy( leader.velocity ).multiplyScalar( lookAheadTime );
		predictedPosition.addVectors( offsetWorld, newLeaderVelocity );

		// now arrive at the predicted future position of the offset
		_arrive.target = predictedPosition;
		_arrive.calculate( vehicle, force );

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['leader'] = leader?.uuid;
		json['offset'] = offset;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	OffsetPursuitBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		leader = json['leader'];
		offset = json['offset'];

		return this;
	}


	/// Restores UUIDs with references to GameEntity objects.
  @override
	OffsetPursuitBehavior resolveReferences(Map<String,GameEntity> entities ) {
		leader = entities.get( leader! ) as Vehicle;
    return this;
	}
}
