import 'package:examples/playground/hideseek/custom_obstacle.dart';
import 'package:yuka/yuka.dart';

class HideBehavior extends SteeringBehavior {
  final hidingSpot = Vector3();
  final offset = Vector3();
  final List<GameEntity> obstaclesArray = [];

  final inverse = Matrix4();
  final localPositionOfHidingSpot = Vector3();
  final localPositionOfObstacle = Vector3();
  final localPositionOfClosestObstacle = Vector3();
  final intersectionPoint = Vector3();
  final boundingSphere = BoundingSphere();

  final ray = Ray( Vector3( 0, 0, 0 ), Vector3( 0, 0, 1 ) );

  EntityManager entityManager;
  MovingEntity pursuer;

  double distanceFromHidingSpot;
  double deceleration;

	final _evade = EvadeBehavior();
	final _seek = SeekBehavior();
  final _arrive = ArriveBehavior();
  double dBoxMinLength = 3;
  final _bestHidingSpot = Vector3();
  Vector3? _waypoint;
  double _dBoxLength = 0;

	HideBehavior(this.entityManager, this.pursuer, [this.distanceFromHidingSpot = 2, this.deceleration = 1.5] ):super() {
		_arrive.tolerance = 1.5;
	}

  @override
	Vector3? calculate(Vehicle vehicle, Vector3 force , [double? delta ]) {
		double closestDistanceSquared = double.infinity;
		final obstacles = entityManager.entities;//.values();
		obstaclesArray.length = 0;

		for ( final obstacle in obstacles ) {
			if ( obstacle is CustomObstacle ) {
				obstaclesArray.add( obstacle );
				_getHidingPosition( obstacle, pursuer, hidingSpot );
				final squaredDistance = hidingSpot.squaredDistanceTo( vehicle.position );

				if ( squaredDistance < closestDistanceSquared ) {
					closestDistanceSquared = squaredDistance;
					_bestHidingSpot.copy( hidingSpot );
				}
			}
		}

		if ( closestDistanceSquared == double.infinity ) {
			// if no suitable obstacles found then evade the pursuer
			_evade.pursuer = pursuer;
			_evade.calculate( vehicle, force );
		} 
    else {
			// check if the way to the hiding spot is blocked by an obstacle
			_obstacleAvoidance( vehicle );

			if ( _waypoint != null) {
				// seek to an alternative waypoint
				_seek.target = _waypoint!;
				_seek.calculate( vehicle, force );
			} 
      else {
				// otherwise arrive at the hiding spot
				_arrive.target = _bestHidingSpot;
				_arrive.deceleration = deceleration;
				_arrive.calculate( vehicle, force );
			}
		}

		return force;
	}

	void _obstacleAvoidance(Vehicle vehicle ) {
		GameEntity? closestObstacle;

		// this will be used to track the distance to the closest obstacle
		double distanceToClosestObstacle = double.infinity;

		// the obstacles in the game world
		final obstacles = obstaclesArray;

		// the detection box length is proportional to the agent's velocity
		_dBoxLength = dBoxMinLength + ( vehicle.getSpeed() / vehicle.maxSpeed ) * dBoxMinLength;
		vehicle.worldMatrix().getInverse( inverse );

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstacle = obstacles[ i ];

			if ( obstacle == vehicle ) continue;

			// calculate this obstacle's position in local space of the vehicle
			localPositionOfObstacle.copy( obstacle.position ).applyMatrix4( inverse );
			
      // if the local position has a positive z value then it must lay behind the agent.
			// besides the absolute z value must be smaller than the length of the detection box
			if ( localPositionOfObstacle.z > 0 && localPositionOfObstacle.z.abs() < _dBoxLength ) {
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

		// if there an obstacle was detected, calculate a proper waypoint next to the obstacle

		if ( closestObstacle != null ) {
			_waypoint = localPositionOfClosestObstacle.clone();

			// check if it's better to steer left or right next to the obstacle
			final sign = ( localPositionOfClosestObstacle.x ).sign;

			// check if the best hiding spot is behind the vehicl
			localPositionOfHidingSpot.copy( _bestHidingSpot ).applyMatrix4( inverse );

			// if so flip the z-coordinate of the waypoint in order to avoid conflicts
			if ( localPositionOfHidingSpot.z < 0 ) _waypoint?.z *= - 1;

			// compute the optimal x-coordinate so the vehicle steers next to the obstacle
			_waypoint?.x -= ( closestObstacle.boundingRadius + vehicle.boundingRadius ) * sign;
			_waypoint?.applyMatrix4( vehicle.worldMatrix() );
		}

		// proceed if there is an active waypoint
		if ( _waypoint != null ) {
			final distanceSq = _waypoint!.squaredDistanceTo( vehicle.position );

			// if we are close enough, delete the current waypoint
			if ( distanceSq < 1 ) {
				_waypoint = null;
			}
		}
	}

	void  _getHidingPosition(CustomObstacle obstacle, MovingEntity pursuer, Vector3 hidingSpot ) {
		// calculate the ideal spacing of the vehicle to the hiding spot
		final spacing = obstacle.boundingRadius + distanceFromHidingSpot;

		// calculate the heading toward the object from the pursuer
		offset.subVectors( obstacle.position, pursuer.position ).normalize();

		// scale it to size
		offset.multiplyScalar( spacing );

		// add the offset to the obstacles position to get the hiding spot
		hidingSpot.addVectors( obstacle.position, offset );
	}
}
