import 'package:examples/playground/shooter/blaster.dart';
import 'package:examples/playground/shooter/world.dart';
import 'package:yuka/yuka.dart';

class Player extends MovingEntity {
  final q = Quaternion();
  final headContainer = GameEntity();
  final head = GameEntity();
  final weaponContainer = GameEntity();
  late final Blaster weapon;
  final World world;

  MeshGeometry? geometry;

	Player(this.world):super() {
		add( headContainer );

		head.position.set( 0, 2, 0 );
		headContainer.add( head );

		head.add( weaponContainer );

    weapon = Blaster( this , world);
		weapon.position.set( 0.3, - 0.3, - 1 );
		weaponContainer.add( weapon );

		//
		forward.set( 0, 0, - 1 );
		maxSpeed = 10;
		updateOrientation = false;
	}

  @override
	Vector3 getDirection(Vector3 result ) {
		q.multiplyQuaternions( rotation, head.rotation );
		return result.copy( forward ).applyRotation( q ).normalize();
	}
}
