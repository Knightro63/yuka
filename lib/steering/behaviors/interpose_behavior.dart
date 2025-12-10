import '../../constants.dart';
import '../../core/game_entity.dart';
import '../../core/moving_entity.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'arrive_behavior.dart';

/// This steering behavior produces a force that moves a vehicle to the midpoint
/// of the imaginary line connecting two other agents.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class InterposeBehavior extends SteeringBehavior {
  final midPoint = Vector3();
  final translation = Vector3();
  final predictedPosition1 = Vector3();
  final predictedPosition2 = Vector3();

  MovingEntity? entity1;
  MovingEntity? entity2;
  double deceleration;

  final _arrive = ArriveBehavior();

	/// Constructs a interpose behavior.
	InterposeBehavior([ this.entity1, this.entity2, this.deceleration = 3 ]):super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final entity1 = this.entity1!;
		final entity2 = this.entity2!;

		// first we need to figure out where the two entities are going to be
		// in the future. This is approximated by determining the time
		// taken to reach the mid way point at the current time at max speed
		midPoint.addVectors( entity1.position, entity2.position ).multiplyScalar( 0.5 );
		final time = vehicle.position.distanceTo( midPoint ) / vehicle.maxSpeed;

		// now we have the time, we assume that entity 1 and entity 2 will
		// continue on a straight trajectory and extrapolate to get their future positions
		translation.copy( entity1.velocity ).multiplyScalar( time );
		predictedPosition1.addVectors( entity1.position, translation );

		translation.copy( entity2.velocity ).multiplyScalar( time );
		predictedPosition2.addVectors( entity2.position, translation );

		// calculate the mid point of these predicted positions
		midPoint.addVectors( predictedPosition1, predictedPosition2 ).multiplyScalar( 0.5 );

		// then steer to arrive at it
		_arrive.deceleration = deceleration;
		_arrive.target = midPoint;
		_arrive.calculate( vehicle, force );

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['entity1'] = entity1?.uuid;
		json['entity2'] = entity2?.uuid;
		json['deceleration'] = deceleration;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	InterposeBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		entity1 = json['entity1'];
		entity2 = json['entity2'];
		deceleration = json['deceleration'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	InterposeBehavior resolveReferences(Map<String,GameEntity> entities ) {
		entity1 = entities.get( entity1! ) as MovingEntity?;
		entity2 = entities.get( entity2! )  as MovingEntity?;

    return this;
	}
}
