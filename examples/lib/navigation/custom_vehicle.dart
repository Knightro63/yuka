
import 'package:yuka/yuka.dart';

class CustomVehicle extends Vehicle {
  NavMesh? navMesh;

  Polygon? currentRegion;
  Polygon? fromRegion;
  Polygon? toRegion;

	CustomVehicle():super();

  @override
	CustomVehicle update(double delta ) {
		super.update( delta );

		// this code is used to adjust the height of the entity according to its current region
		final currentRegion = navMesh?.getRegionForPoint( position, 1 );

		if ( currentRegion != null ) {
			this.currentRegion = currentRegion;
			final double distance = this.currentRegion?.distanceToPoint( position ) ?? 0;
			position.y -= distance * 0.2;
		}

		return this;
	}
}
