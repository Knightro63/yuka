import '../../constants.dart';
import '../../core/game_entity.dart';
import '../../core/moving_entity.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'flee_behavior.dart';

/// This steering behavior is is almost the same as {@link PursuitBehavior} except that
/// the agent flees from the estimated future position of the pursuer.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class EvadeBehavior extends SteeringBehavior {
  final displacement = Vector3();
  final newPursuerVelocity = Vector3();
  final predictedPosition = Vector3();

  MovingEntity? pursuer;
  double panicDistance;
  double predictionFactor;

  final _flee = FleeBehavior();

	/// Constructs a new arrive behavior.
	EvadeBehavior([this.pursuer, this.panicDistance = 10, this.predictionFactor = 1 ]):super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final pursuer = this.pursuer!;

		displacement.subVectors( pursuer.position, vehicle.position );

		double lookAheadTime = displacement.length / ( vehicle.maxSpeed + pursuer.getSpeed() );
		lookAheadTime *= predictionFactor; // tweak the magnitude of the prediction

		// calculate velocity and predicted future position
		newPursuerVelocity.copy( pursuer.velocity ).multiplyScalar( lookAheadTime );
		predictedPosition.addVectors( pursuer.position, newPursuerVelocity );

		// now flee away from predicted future position of the pursuer
		_flee.target = predictedPosition;
		_flee.panicDistance = panicDistance;
		_flee.calculate( vehicle, force );

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['pursuer'] = pursuer?.uuid;
		json['panicDistance'] = panicDistance;
		json['predictionFactor'] = predictionFactor;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	EvadeBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		pursuer = json['pursuer'];
		panicDistance = json['panicDistance'];
		predictionFactor = json['predictionFactor'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	EvadeBehavior resolveReferences(Map<String,GameEntity> entities ) {
		pursuer = entities.get( pursuer! ) as MovingEntity;
    return this;
	}
}
