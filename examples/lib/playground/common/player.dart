import 'package:examples/playground/hideseek/custom_obstacle.dart';
import 'package:examples/playground/common/blaster.dart';
import './world.dart';
import 'package:yuka/yuka.dart';

class PlayerSettings{

  PlayerSettings({
    this.allowUpdate = false,
    this.maxSpeed = 10,
    this.weaponPosition = 0.3,
    this.isShotgun = false
  });

  double weaponPosition;
  double maxSpeed;
  bool allowUpdate;
  bool isShotgun;
}

class Player extends MovingEntity {
  final q = Quaternion();
  final aabb = AABB();
  final ray = Ray();
  final intersectionPoint = Vector3();
  final intersectionNormal = Vector3();
  final reflectionVector = Vector3();

  final headContainer = GameEntity();
  final head = GameEntity();
  final weaponContainer = GameEntity();
  late final Blaster weapon;
  final World world;

  MeshGeometry? geometry;
  late final PlayerSettings settings;

	Player(this.world, [PlayerSettings? settings]):super() {
    this.settings = settings ?? PlayerSettings();
		add( headContainer );

		head.position.set( 0, 2, 0 );
		headContainer.add( head );

		head.add( weaponContainer );

    weapon = Blaster( this , world, this.settings.isShotgun);
		weapon.position.set( this.settings.weaponPosition, - 0.3, - 1 );
		weaponContainer.add( weapon );

		//
		forward.set( 0, 0, - 1 );
		maxSpeed = this.settings.maxSpeed;
		updateOrientation = false;
	}

  @override
	Vector3 getDirection(Vector3 result ) {
		q.multiplyQuaternions( rotation, head.rotation );
		return result.copy( forward ).applyRotation( q ).normalize();
	}

  @override
	MovingEntity update(double delta ) {
    if(settings.allowUpdate){
      final obstacles = world.obstacles;

      for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
        final obstacle = obstacles[ i ];

        if ( obstacle is CustomObstacle ) {
          // first check bounding volumes for intersection
          final squaredDistance = position.squaredDistanceTo( obstacle.position );
          final range = boundingRadius + obstacle.boundingRadius;

          if ( squaredDistance <= ( range * range ) ) {
            // compute AABB in world space for obstacle
            aabb.copy( obstacle.geometry.aabb ).applyMatrix4( obstacle.worldMatrix() );

            // enhance the AABB with the bounding radius of the player
            aabb.max.addScalar( boundingRadius );
            aabb.min.subScalar( boundingRadius );

            // setup ray
            ray.origin.copy( position );
            ray.direction.copy( velocity ).normalize();

            // perform ray/AABB intersection test
            if ( ray.intersectAABB( aabb, intersectionPoint ) != null ) {

              // derive normal vector
              aabb.getNormalFromSurfacePoint( intersectionPoint, intersectionNormal );

              // compute reflection vector
              reflectionVector.copy( ray.direction ).reflect( intersectionNormal );

              // compute velocity vector
              final speed = getSpeed();
              velocity.addVectors( ray.direction, reflectionVector ).normalize();
              final f = 1 -intersectionNormal.dot( ray.direction ).abs();
              velocity.multiplyScalar( speed * f );
            }
          }
        }
      }
    }

		return super.update( delta );
	}
}
