import 'package:examples/playground/common/world.dart';
import 'package:examples/playground/hideseek/enemy.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

class Bullet extends MovingEntity {
  final Ray _ray = Ray();
  late final Ray ray;
  final intersectionPoint = Vector3();
  final normal = Vector3();
  double lifetime = 1;
  double currentTime = 0;

  GameEntity owner;
  final World world;
  MeshGeometry? geometry;

	Bullet(this.owner, this.world, Ray? ray):super() {
    this.ray = ray ?? Ray();
		maxSpeed = 400; // 400 m/s

		position.copy( this.ray.origin );
		velocity.copy( this.ray.direction ).multiplyScalar( maxSpeed );

		final s = 1 + ( math.Random().nextDouble() * 3 ); // scale the shot line a bit

		scale.set( s, s, s );

		lifetime = 1;
		currentTime = 0;
	}

  @override
	Bullet update(double delta ) {
		currentTime += delta;

		if ( currentTime > lifetime ) {
			world.remove( this );
		} 
    else {
			_ray.copy( ray );
			_ray.origin.copy( position );

			super.update( delta );

			final entity = world.intersectRay( _ray, intersectionPoint, normal );
			if ( entity != null ) {
				// calculate distance from origin to intersection point
				final distanceToIntersection = _ray.origin.squaredDistanceTo( intersectionPoint );
				final validDistance = _ray.origin.squaredDistanceTo( position );

				if ( distanceToIntersection <= validDistance ) {
					// inform game entity about hit
					owner.sendMessage( entity, 'hit' );

					// add visual feedback
          if (entity is! Enemy) world.addBulletHole( intersectionPoint, normal);

					// remove bullet from world
					world.remove( this );
				}
			}
		}

		return this;
	}
}