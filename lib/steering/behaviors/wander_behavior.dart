import 'dart:math' as math;
import '../../math/math_utils.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

/// This steering behavior produces a steering force that will give the
/// impression of a random walk through the agent’s environment. The behavior only
/// produces a 2D force (XZ).
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class WanderBehavior extends SteeringBehavior {
  final targetWorld = Vector3();
  final randomDisplacement = Vector3();

  double radius;
  double distance;
  double jitter;
  final _targetLocal = Vector3();

	/// Constructs a new wander behavior.
	WanderBehavior([this.radius = 1, this.distance = 5, this.jitter = 5 ]):super() {
		generateRandomPointOnCircle( radius, _targetLocal );
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
    delta ??= 0;

		// this behavior is dependent on the update rate, so this line must be
		// included when using time independent frame rate
		final jitterThisTimeSlice = jitter * delta;

		// prepare random vector
		randomDisplacement.x = MathUtils.randFloat( - 1, 1 ) * jitterThisTimeSlice;
		randomDisplacement.z = MathUtils.randFloat( - 1, 1 ) * jitterThisTimeSlice;

		// add random vector to the target's position
		_targetLocal.add( randomDisplacement );

		// re-project this new vector back onto a unit sphere
		_targetLocal.normalize();

		// increase the length of the vector to the same as the radius of the wander sphere
		_targetLocal.multiplyScalar( radius );

		// move the target into a position wanderDist in front of the agent
		targetWorld.copy( _targetLocal );
		targetWorld.z += distance;

		// project the target into world space
		targetWorld.applyMatrix4( vehicle.worldMatrix() );

		// and steer towards it
		force.subVectors( targetWorld, vehicle.position );

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['radius'] = radius;
		json['distance'] = distance;
		json['jitter'] = jitter;
		json['_targetLocal'] = _targetLocal.storage;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	WanderBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		radius = json['radius'];
		distance = json['distance'];
		jitter = json['jitter'];
		_targetLocal.fromArray( json['_targetLocal'] );

		return this;
	}

  void generateRandomPointOnCircle(double radius, Vector3 target ) {
    final theta = math.Random().nextDouble() * math.pi * 2;
    target.x = radius * math.cos( theta );
    target.z = radius * math.sin( theta );
  }
}

//

