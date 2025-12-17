import 'package:yuka/yuka.dart';

/// Class for representing the level of this game.
///
/// @author {@link https://github.com/robp94|robp94}
class Level extends GameEntity {
  MeshGeometry geometry;
  late final BVH bvh;

	Level(this.geometry ):super(){
		bvh = BVH().fromMeshGeometry( geometry );
		canActivateTrigger = false;
	}

	/// Holds the implementation for the message handling of this game entity.
  @override
	bool handleMessage(Telegram telegram) {
		// do nothing
		return true;
	}

	/// Returns the intesection point if a projectile intersects with this entity.
	/// If no intersection is detected, null is returned./
	Vector3 checkProjectileIntersection(Ray ray, Vector3 intersectionPoint ) {
		return ray.intersectBVH( bvh, intersectionPoint );
	}

	/// Returns the intesection point if this entity lies within the given line of sight.
	/// If no intersection is detected, null is returned.
  @override
	Vector3 lineOfSightTest(Ray ray, Vector3 intersectionPoint ) {
		return ray.intersectBVH( bvh, intersectionPoint );
	}
}
