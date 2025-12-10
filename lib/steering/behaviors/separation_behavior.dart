import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';

/// This steering produces a force that steers a vehicle away from those in its neighborhood region.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SeparationBehavior extends SteeringBehavior {
  final toAgent = Vector3();

	SeparationBehavior():super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		final neighbors = vehicle.neighbors;

		for ( int i = 0, l = neighbors.length; i < l; i ++ ) {
			final neighbor = neighbors[ i ];
			toAgent.subVectors( vehicle.position, neighbor.position );

			double length = toAgent.length;

			// handle zero length if both vehicles have the same position
			if ( length == 0 ) length = 0.0001;

			// scale the force inversely proportional to the agents distance from its neighbor
			toAgent.normalize().divideScalar( length );
			force.add( toAgent );
		}

		return force;
	}
}
