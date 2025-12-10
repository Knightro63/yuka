import '../core/game_entity.dart';
import '../core/moving_entity.dart';
import '../math/vector3.dart';
import 'smoother.dart';
import 'steering_manager.dart';

/// This type of game entity implements a special type of locomotion, the so called
/// *Vehicle Model*. The class uses basic physical metrics in order to implement a
/// realistic movement.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class Vehicle extends MovingEntity {
  double mass = 1;
  double maxForce = 100;
  late SteeringManager steering;
  Smoother? smoother;

  final steeringForce = Vector3();
  final acceleration = Vector3();
  final velocitySmooth = Vector3();

	/// Constructs a new vehicle.
	Vehicle():super() {
		steering = SteeringManager( this );
    displacement.copy(Vector3());
    target.copy(Vector3());
	}

	/// This method is responsible for updating the position based on the force produced
	/// by the internal steering manager.
  @override
	Vehicle update(double delta ) {
		// calculate steering force
		steering.calculate( delta, steeringForce );

		// acceleration = force / mass
		acceleration.copy( steeringForce ).divideScalar( mass );

		// update velocity
		velocity.add( acceleration.multiplyScalar( delta ) );

		// make sure vehicle does not exceed maximum speed
		if ( getSpeedSquared() > ( maxSpeed * maxSpeed ) ) {
			velocity.normalize();
			velocity.multiplyScalar( maxSpeed );
		}

		// calculate displacement
		displacement.copy( velocity ).multiplyScalar( delta );

		// calculate target position
		target.copy( position ).add( displacement );

		// update the orientation if the vehicle has a non zero velocity

		if ( updateOrientation == true && smoother == null && getSpeedSquared() > 0.00000001 ) {
			lookAt( target );
		}

		// update position
		position.copy( target );

		// if smoothing is enabled, the orientation (not the position!) of the vehicle is
		// changed based on a post-processed velocity vector

		if ( updateOrientation == true && smoother != null ) {
			smoother?.calculate( velocity, velocitySmooth );

			displacement.copy( velocitySmooth ).multiplyScalar( delta );
			target.copy( position ).add( displacement );

			lookAt( target );
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['mass'] = mass;
		json['maxForce'] = maxForce;
		json['steering'] = steering.toJSON();
		json['smoother'] = smoother?.toJSON();

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	Vehicle fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		mass = json['mass'];
		maxForce = json['maxForce'];
		steering = SteeringManager( this ).fromJSON( json['steering'] );
		smoother = json['smoother'] != null? Smoother().fromJSON( json['smoother'] ) : null;

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	Vehicle resolveReferences(Map<String,GameEntity> entities ) {
		super.resolveReferences( entities );
		steering.resolveReferences( entities );
    return this;
	}
}
