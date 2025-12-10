import '../../math/math_utils.dart';
import '../../math/vector3.dart';

/// A corridor is a sequence of portal edges representing a walkable way within a navigation mesh. The class is able
/// to find the shortest path through this corridor as a sequence of waypoints. It's an implementation of the so called
/// { @link http://digestingduck.blogspot.com/2010/03/simple-stupid-funnel-algorithm.html Funnel Algorithm}. Read
/// the paper {@link https://aaai.org/Papers/AAAI/2006/AAAI06-148.pdf Efficient Triangulation-Based Pathfinding} for
/// more detailed information.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class Corridor {

  List<Map<String,Vector3>> portalEdges = [];

	/// Adds a portal edge defined by its left and right vertex to this corridor.
	Corridor push(Vector3 left, Vector3 right ) {
		portalEdges.add( {
			'left': left,
			'right': right
		} );

		return this;
	}

	/// Generates the shortest path through the corridor as an array of 3D vectors.
	List<Vector3> generate() {
		final portalEdges = this.portalEdges;
		final path = <Vector3>[];

		// init scan state

		Vector3 portalApex, portalLeft, portalRight;
		int apexIndex = 0, leftIndex = 0, rightIndex = 0;

		portalApex = portalEdges[ 0 ]['left']!;
		portalLeft = portalEdges[ 0 ]['left']!;
		portalRight = portalEdges[ 0 ]['right']!;

		// add start point

		path.add( portalApex );

		for ( int i = 1, l = portalEdges.length; i < l; i ++ ) {
			final left = portalEdges[ i ]['left']!;
			final right = portalEdges[ i ]['right']!;

			// update right vertex
			if ( MathUtils.area( portalApex, portalRight, right ) <= 0 ) {
				if ( portalApex == portalRight || MathUtils.area( portalApex, portalLeft, right ) > 0 ) {
					// tighten the funnel
					portalRight = right;
					rightIndex = i;
				} 
        else {
					// right over left, insert left to path and restart scan from portal left point
					path.add( portalLeft );

					// make current left the new apex
					portalApex = portalLeft;
					apexIndex = leftIndex;

					// review eset portal
					portalLeft = portalApex;
					portalRight = portalApex;
					leftIndex = apexIndex;
					rightIndex = apexIndex;

					// restart scan
					i = apexIndex;

					continue;
				}
			}

			// update left vertex
			if ( MathUtils.area( portalApex, portalLeft, left ) >= 0 ) {
				if ( portalApex == portalLeft || MathUtils.area( portalApex, portalRight, left ) < 0 ) {
					// tighten the funnel
					portalLeft = left;
					leftIndex = i;
				} 
        else {
					// left over right, insert right to path and restart scan from portal right point
					path.add( portalRight );

					// make current right the new apex
					portalApex = portalRight;
					apexIndex = rightIndex;

					// reset portal
					portalLeft = portalApex;
					portalRight = portalApex;
					leftIndex = apexIndex;
					rightIndex = apexIndex;

					// restart scan
					i = apexIndex;

					continue;
				}
			}
		}

		if ( ( path.isEmpty ) || ( path[ path.length - 1 ] != portalEdges[ portalEdges.length - 1 ]['left'] ) ) {
			// append last point to path
			path.add( portalEdges[ portalEdges.length - 1 ]['left']! );
		}

		return path;
	}
}
