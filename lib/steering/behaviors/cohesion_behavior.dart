import '../../math/vector3.dart';
import '../steering_behavior.dart';
import '../vehicle.dart';
import 'seek_behavior.dart';

/// This steering produces a steering force that moves a vehicle toward the center of mass of its neighbors.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CohesionBehavior extends SteeringBehavior {
  final _seek = SeekBehavior();
  final centerOfMass = Vector3();

	CohesionBehavior():super();

	/// Calculates the steering force for a single simulation step.
  @override
	Vector3 calculate(Vehicle vehicle, Vector3 force, [double? delta]) {
		centerOfMass.set( 0, 0, 0 );
		final neighbors = vehicle.neighbors;

		// iterate over all neighbors to calculate the center of mass
		for ( int i = 0, l = neighbors.length; i < l; i ++ ) {
			final neighbor = neighbors[ i ];
			centerOfMass.add( neighbor.position );
		}

		if ( neighbors.isNotEmpty ) {
			centerOfMass.divideScalar( neighbors.length.toDouble() );

			// seek to it
			_seek.target = centerOfMass;
			_seek.calculate( vehicle, force );

			// the magnitude of cohesion is usually much larger than separation
			// or alignment so it usually helps to normalize it
			force.normalize();
		}

		return force;
	}
}
