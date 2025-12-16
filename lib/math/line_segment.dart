import 'vector3.dart';
import 'math_utils.dart';

/// Class representing a 3D line segment.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class LineSegment {
  final p1 = Vector3();
  final p2 = Vector3();
  late Vector3 from;
  late Vector3 to;

	/// Constructs a new line segment with the given values.
	LineSegment([Vector3? from, Vector3? to]) {
		this.from = from ?? Vector3();
		this.to = to ?? Vector3();
	}

	/// Sets the given values to this line segment.
	LineSegment set(Vector3 from, Vector3 to ) {
		this.from = from;
		this.to = to;

		return this;
	}

	/// Copies all values from the given line segment to this line segment.
	LineSegment copy(LineSegment lineSegment ) {
		from.copy(lineSegment.from);
		to.copy(lineSegment.to);

		return this;
	}

	/// Creates a new line segment and copies all values from this line segment.
	LineSegment clone() {
		return LineSegment().copy( this );
	}

	/// Computes the difference vector between the end and start point of this
	/// line segment and stores the result in the given vector.
	Vector3 delta(Vector3 result ) {
		return result.subVectors( to, from );
	}

	/// Computes a position on the line segment according to the given t value
	/// and stores the result in the given 3D vector. The t value has usually a range of
  /// [0, 1] where 0 means start position and 1 the end position.
	Vector3 at(double t, Vector3 result ) {
		return delta( result ).multiplyScalar( t ).add( from );
	}

	/// Computes the closest point on an infinite line defined by the line segment.
	/// It's possible to clamp the closest point so it does not exceed the start and
	/// end position of the line segment.
	Vector3 closestPointToPoint(Vector3 point, bool clampToLine, Vector3 result ) {
		final t = closestPointToPointParameter( point, clampToLine );
		return at( t, result );
	}

	/// Computes a scalar value which represents the closest point on an infinite line
	/// defined by the line segment. It's possible to clamp this value so it does not
	/// exceed the start and end position of the line segment.
	double closestPointToPointParameter(Vector3 point, [bool clampToLine = true ]) {
		p1.subVectors( point, from );
		p2.subVectors( to, from );

		final dotP2P2 = p2.dot( p2 );
		final dotP2P1 = p2.dot( p1 );

		double t = dotP2P1 / dotP2P2;

		if ( clampToLine ) t = MathUtils.clamp( t, 0, 1 );

		return t;
	}

	/// Returns true if the given line segment is deep equal with this line segment.
	bool equals(LineSegment lineSegment ) {
		return lineSegment.from.equals( from ) && lineSegment.to.equals( to );
	}
}
