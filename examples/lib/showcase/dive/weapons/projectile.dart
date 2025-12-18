import 'package:yuka/yuka.dart';

/// Base class for representing a projectile.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Projectile extends MovingEntity {
  GameEntity owner;
  late final Ray ray;
  final intersectionPoint = Vector3();

  double lifetime = 0;
  double currentTime = 0;
  double damage = 0;

	/// finalructs a new projectile with the given values.
	Projectile(this.owner, Ray? ray):super() {
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

	/// Update method of this projectile.
  @override
	Projectile update(double delta ) {
		final world = (owner as dynamic).world;

		currentTime += delta;

		if ( currentTime > lifetime ) {
			world.remove( this );
		} 
    else {
			ray.copy( ray );
			ray.origin.copy( position );

			super.update( delta );

			final entity = world.checkProjectileIntersection( this, intersectionPoint );

			if ( entity != null ) {
				// calculate distance from origin to intersection point
				final distanceToIntersection = ray.origin.squaredDistanceTo( intersectionPoint );
				final validDistance = ray.origin.squaredDistanceTo( position );

				if ( distanceToIntersection <= validDistance ) {
					// inform game entity about hit
					owner.sendMessage( entity, 'MESSAGE_HIT', 0, { 'damage': damage, 'direction': ray.direction } );

					// remove projectile from world
					world.remove( this );
				}
			}
		}

    return this;
	}
}
