import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

/// This steering behavior produces a force that keeps a vehicle’s heading aligned with its neighbors.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AlignmentBehavior extends SteeringBehavior {
  final averageDirection = Vector3();
  final direction = Vector3();

	AlignmentBehavior():super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		averageDirection.set( 0, 0, 0 );
		final neighbors = vehicle.neighbors;

		// iterate over all neighbors to calculate the average direction vector
		for (int i = 0, l = neighbors.length; i < l; i ++ ) {
			final neighbor = neighbors[ i ];
			neighbor.getDirection( direction );
			averageDirection.add( direction );
		}

		if ( neighbors.isNotEmpty ) {
			averageDirection.divideScalar( neighbors.length.toDouble() );

			// produce a force to align the vehicle's heading
			vehicle.getDirection( direction );
			force.subVectors( averageDirection, direction );
		}

		return force;
	}
}
