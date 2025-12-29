import 'package:examples/showcase/dive/core/world.dart';
import 'package:yuka/yuka.dart';

final Ray _ray = Ray();

/// Base class for representing a projectile.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Projectile extends MovingEntity {
  GameEntity? owner;
  late final Ray ray;
  final intersectionPoint = Vector3();
  final normal = Vector3();
  double lifetime = 0;
  double currentTime = 0;
  int damage = 0;

	/// finalructs a new projectile with the given values.
	Projectile([this.owner, Ray? ray]):super() {
    this.ray = ray ?? Ray();
		canActivateTrigger = false;
	}

	/// Executed when this game entity is updated for the first time by its entity manager.
  @override
	Projectile start() {
		// make the render component visible when the projectile was updated
		// by the entity manager at least once
		renderComponent.visible = true;
		return this;
	}

	/// Returns the intesection point if a projectile intersects with this entity.
	/// If no intersection is detected, null is returned.
	Vector3? checkProjectileIntersection(Ray ray, Vector3 intersectionPoint ) {
		return null;
	}

	/// Update method of this projectile.
  @override
	Projectile update(double delta ) {
		final World world = (owner as dynamic).world;

		currentTime += delta;

		if ( currentTime > lifetime ) {
			world.remove( this );
		} 
    else {
			_ray.copy( ray );
			_ray.origin.copy( position );

			super.update( delta );

			final entity = world.checkProjectileIntersection( this, intersectionPoint );

			if ( entity != null ) {
				// calculate distance from origin to intersection point
				final distanceToIntersection = _ray.origin.squaredDistanceTo( intersectionPoint );
				final validDistance = _ray.origin.squaredDistanceTo( position );

				if ( distanceToIntersection <= validDistance ) {
					// inform game entity about hit
					owner?.sendMessage( entity, 'hit', 0, { 'damage': damage, 'direction': ray.direction } );
					// remove projectile from world
					world.remove( this );
				}
			}
		}

    return this;
	}
}
