import 'package:yuka/yuka.dart';

class Obstacle extends GameEntity {
  late final MeshGeometry geometry;
	Obstacle([MeshGeometry? geometry]):super(){
		this.geometry = geometry ?? MeshGeometry();
	}

  @override
	Vector3? lineOfSightTest(Ray ray, Vector3 intersectionPoint ) {
		return geometry.intersectRay( ray, worldMatrix(), true, intersectionPoint );
	}
}
