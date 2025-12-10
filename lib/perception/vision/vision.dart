import '../../core/game_entity.dart';
import '../../math/ray.dart';
import '../../math/vector3.dart';
import 'dart:math' as math;
import '../../constants.dart';

/// Class for representing the vision component of a game entity.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Vision {
  final toPoint = Vector3();
  final direction = Vector3();
  final ray = Ray();
  final intersectionPoint = Vector3();
  final worldPosition = Vector3();

  GameEntity? owner;
  double fieldOfView = math.pi;
  double range = double.infinity;
  final obstacles = <GameEntity>[];

	/// Constructs a new vision object.
	Vision([ this.owner]);

	/// Adds an obstacle to this vision instance.
	Vision addObstacle(GameEntity obstacle ) {
		obstacles.add( obstacle );
		return this;
	}

	/// Removes an obstacle from this vision instance.
	Vision removeObstacle(GameEntity obstacle ) {
		final index = obstacles.indexOf( obstacle );
		obstacles.removeAt( index );

		return this;
	}

	/// Performs a line of sight test in order to determine if the given point
	/// in 3D space is visible for the game entity.
	bool visible(Vector3 point ) {
		final owner = this.owner;
		final obstacles = this.obstacles;

		owner?.getWorldPosition( worldPosition );

		// check if point lies within the game entity's visual range

		toPoint.subVectors( point, worldPosition );
		final distanceToPoint = toPoint.length;

		if ( distanceToPoint > range ) return false;

		// next, check if the point lies within the game entity's field of view

		owner?.getWorldDirection( direction );

		final angle = direction.angleTo( toPoint );

		if ( angle > ( fieldOfView * 0.5 ) ) return false;

		// the point lies within the game entity's visual range and field
		// of view. now check if obstacles block the game entity's view to the given point.

		ray.origin.copy( worldPosition );
		ray.direction.copy( toPoint ).divideScalar(distanceToPoint != 0?distanceToPoint: 1); // normalize

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstacle = obstacles[ i ];
			final intersection = obstacle.lineOfSightTest( ray, intersectionPoint );

			if ( intersection != null ) {
				// if an intersection point is closer to the game entity than the given point,
				// something is blocking the game entity's view
				final squaredDistanceToIntersectionPoint = intersectionPoint.squaredDistanceTo( worldPosition );
				if ( squaredDistanceToIntersectionPoint <= ( distanceToPoint * distanceToPoint ) ) return false;
			}
		}

		return true;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'owner': owner?.uuid,
			'fieldOfView': fieldOfView,
			'range': range.toString()
		};

		json['obstacles'] = [];

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstacle = obstacles[ i ];
			json['obstacles'].add( obstacle.uuid );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	Vision fromJSON(Map<String,dynamic> json ) {
		owner = json['owner'];
		fieldOfView = json['fieldOfView'];
		range = double.parse( json['range'] );

		for ( int i = 0, l = json['obstacles'].length; i < l; i ++ ) {
			final obstacle = json['obstacles'][ i ];
			obstacles.add( obstacle );
		}

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	Vision resolveReferences(Map<String,GameEntity> entities ) {
		owner = entities.get(owner!);
		final obstacles = this.obstacles;

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			obstacles[ i ] = entities.get(obstacles[ i ])!;
		}

		return this;
	}
}
