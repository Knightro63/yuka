import '../../constants.dart';
import '../../core/game_entity.dart';
import '../../core/moving_entity.dart';
import '../../math/bounding_sphere.dart';
import '../../math/matrix4.dart';
import '../../math/ray.dart';
import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

/// This steering behavior produces a force so a vehicle avoids obstacles lying in its path.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class ObstacleAvoidanceBehavior extends SteeringBehavior {
  final inverse = Matrix4();
  final localPositionOfObstacle = Vector3();
  final localPositionOfClosestObstacle = Vector3();
  final intersectionPoint = Vector3();
  final boundingSphere = BoundingSphere();

  final ray = Ray( Vector3( 0, 0, 0 ), Vector3( 0, 0, 1 ) );

  late final List<GameEntity> obstacles;
  double brakingWeight = 0.2;
  double dBoxMinLength = 4;

	/// Constructs a obstacle avoidance behavior.
	ObstacleAvoidanceBehavior([List<GameEntity>? obstacles]):super() {
		this.obstacles = obstacles ?? [];
	}

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final obstacles = this.obstacles;

		// this will keep track of the closest intersecting obstacle
		GameEntity? closestObstacle;

		// this will be used to track the distance to the closest obstacle
		double distanceToClosestObstacle = double.infinity;

		// the detection box length is proportional to the agent's velocity

		final dBoxLength = dBoxMinLength + ( vehicle.getSpeed() / vehicle.maxSpeed ) * dBoxMinLength;
		vehicle.worldMatrix().getInverse( inverse );

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstacle = obstacles[ i ];

			if ( obstacle == vehicle ) continue;
			// calculate this obstacle's position in local space of the vehicle
			localPositionOfObstacle.copy( obstacle.position ).applyMatrix4( inverse );

			// if the local position has a positive z value then it must lay behind the agent.
			// besides the absolute z value must be smaller than the length of the detection box
			if ( localPositionOfObstacle.z > 0 && localPositionOfObstacle.z.abs() < dBoxLength ) {

				// if the distance from the x axis to the object's position is less
				// than its radius + half the width of the detection box then there is a potential intersection
				final expandedRadius = obstacle.boundingRadius + vehicle.boundingRadius;

				if ( localPositionOfObstacle.x.abs() < expandedRadius ) {
					// do intersection test in local space of the vehicle
					boundingSphere.center.copy( localPositionOfObstacle );
					boundingSphere.radius = expandedRadius;

					ray.intersectBoundingSphere( boundingSphere, intersectionPoint );

					// compare distances
					if ( intersectionPoint.z < distanceToClosestObstacle ) {
						// save minimum distance
						distanceToClosestObstacle = intersectionPoint.z;

						// save closest obstacle
						closestObstacle = obstacle;

						// save local position for force calculation
						localPositionOfClosestObstacle.copy( localPositionOfObstacle );
					}
				}
			}
		}

		// if we have found an intersecting obstacle, calculate a steering force away from it

		if ( closestObstacle != null ) {
			// the closer the agent is to an object, the stronger the steering force should be
			final multiplier = 1 + ( ( dBoxLength - localPositionOfClosestObstacle.z ) / dBoxLength );

			// calculate the lateral force
			force.x = ( closestObstacle.boundingRadius - localPositionOfClosestObstacle.x ) * multiplier;

			// apply a braking force proportional to the obstacles distance from the vehicle
			force.z = ( closestObstacle.boundingRadius - localPositionOfClosestObstacle.z ) * brakingWeight;

			// finally, convert the steering vector from local to world space (just apply the rotation)
			force.applyRotation( vehicle.rotation );
		}

		return force;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['obstacles'] = [];
		json['brakingWeight'] = brakingWeight;
		json['dBoxMinLength'] = dBoxMinLength;

		// obstacles
		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			json['obstacles'].add( obstacles[ i ].uuid );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	ObstacleAvoidanceBehavior fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		obstacles = json['obstacles'];
		brakingWeight = json['brakingWeight'];
		dBoxMinLength = json['dBoxMinLength'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	ObstacleAvoidanceBehavior resolveReferences(Map<String,GameEntity> entities ) {
		final obstacles = this.obstacles;
		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			obstacles[ i ] = entities.get( obstacles[ i ] ) as MovingEntity;
		}
    return this;
	}
}
