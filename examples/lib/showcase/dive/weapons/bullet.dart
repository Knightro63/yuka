import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/weapons/projectile.dart';
import 'dart:math' as math;

/// Class for representing a bullet.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Bullet extends Projectile {

	Bullet(super.owner, super.ray){

		maxSpeed = config['BULLET']['MAX_SPEED'];

		position.copy( ray.origin );
		velocity.copy( ray.direction ).multiplyScalar( maxSpeed );

		final s = 1 + ( math.Random().nextDouble() * 1.5 ); // scale the shot line a bit

		scale.set( s, s, s );

    lifetime = config['BULLET']['LIFETIME'];
    currentTime = 0;
    damage = config['BULLET']['DAMAGE'];
	}
}
