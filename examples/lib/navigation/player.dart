import 'package:yuka/yuka.dart';

final startPosition = Vector3();
final endPosition = Vector3();

class Player extends MovingEntity {
  double height = 2.0;
  final head = GameEntity();
  bool updateOrientation = false;
  NavMesh? navMesh;
  Polygon? currentRegion;

	Player():super() {
		maxSpeed = 4;
		add(head );
	}

  @override
	Player update(double delta ) {
		startPosition.copy( position );
		super.update( delta );

		endPosition.copy( position );

		// ensure the entity stays inside its navmesh
		currentRegion = navMesh?.clampMovement(
			currentRegion,
			startPosition,
			endPosition,
			position
		);

		// adjust height of player according to the ground
		final distance = currentRegion?.distanceToPoint( position ) ?? 0;
		position.y -= distance * 0.2; // smooth transition

    return this;
	}
}

