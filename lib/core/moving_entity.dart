import '../math/vector3.dart';
import 'game_entity.dart';

/// Class representing moving game entities.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MovingEntity extends GameEntity {
  Vector3 velocity = Vector3();
  double maxSpeed = 1;
  bool updateOrientation = true;

  final displacement = Vector3();
  final target = Vector3();

	/// Constructs a new moving entity.
	MovingEntity():super();

	/// Updates the internal state of this game entity.
  @override
	MovingEntity update(double delta ) {
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
		if ( updateOrientation && getSpeedSquared() > 0.00000001 ) {
			lookAt( target );
		}

		// update position
		position.copy( target );

		return this;
	}

	/// Returns the current speed of this game entity.
	double getSpeed() {
		return velocity.length;
	}

	/// Returns the current speed in squared space of this game entity.
	double getSpeedSquared() {
		return velocity.squaredLength;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['velocity'] = velocity.storage;
		json['maxSpeed'] = maxSpeed;
		json['updateOrientation'] = updateOrientation;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	MovingEntity fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		velocity.fromArray( json['velocity'] );
		maxSpeed = json['maxSpeed'];
		updateOrientation = json['updateOrientation'];

		return this;
	}
}
