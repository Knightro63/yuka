import '../../constants.dart';
import '../../core/game_entity.dart';
import '../../core/moving_entity.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'seek_behavior.dart';

/// This steering behavior is useful when an agent is required to intercept a moving agent.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class PursuitBehavior extends SteeringBehavior {
  final displacement = Vector3();
  final vehicleDirection = Vector3();
  final evaderDirection = Vector3();
  final newEvaderVelocity = Vector3();
  final predictedPosition = Vector3();

  final _seek = SeekBehavior();
  MovingEntity? evader;
  double predictionFactor;

	/// Constructs a pursuit behavior.
	PursuitBehavior([ this.evader, this.predictionFactor = 1 ]):super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final evader = this.evader!;
		displacement.subVectors( evader.position, vehicle.position );

		// 1. if the evader is ahead and facing the agent then we can just seek for the evader's current position
		vehicle.getDirection( vehicleDirection );
		evader.getDirection( evaderDirection );

		// first condition: evader must be in front of the pursuer
		final evaderAhead = displacement.dot( vehicleDirection ) > 0;

		// second condition: evader must almost directly facing the agent
		final facing = vehicleDirection.dot( evaderDirection ) < - 0.95;

		if ( evaderAhead == true && facing == true ) {
			_seek.target = evader.position;
			_seek.calculate( vehicle, force );
			return force;
		}

		// 2. evader not considered ahead so we predict where the evader will be

		// the lookahead time is proportional to the distance between the evader
		// and the pursuer. and is inversely proportional to the sum of the
		// agent's velocities
		double lookAheadTime = displacement.length / ( vehicle.maxSpeed + evader.getSpeed() );
		lookAheadTime *= predictionFactor; // tweak the magnitude of the prediction

		// calculate velocity and predicted future position
		newEvaderVelocity.copy( evader.velocity ).multiplyScalar( lookAheadTime );
		predictedPosition.addVectors( evader.position, newEvaderVelocity );

		// now seek to the predicted future position of the evader
		_seek.target = predictedPosition;
		_seek.calculate( vehicle, force );

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['evader'] = evader?.uuid;
		json['predictionFactor'] = predictionFactor;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	PursuitBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		evader = json['evader'];
		predictionFactor = json['predictionFactor'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	PursuitBehavior resolveReferences(Map<String,GameEntity> entities ) {
		evader = entities.get( evader! ) as MovingEntity;
    return this;
	}
}
