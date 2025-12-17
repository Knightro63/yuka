import 'vector3.dart';

/// Class representing a plane in 3D space. The plane is specified in Hessian normal form.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Plane {
  final v1 = Vector3();
  final v2 = Vector3();
  final d = Vector3();

  late final Vector3 normal;
  double constant;

	/// Constructs a new plane with the given values.
	Plane([Vector3? normal, this.constant = 0 ]) {
		this.normal = normal ?? Vector3( 0, 0, 1 );
	}

	/// Sets the given values to this plane.
	Plane set(Vector3 normal, double constant ) {
		this.normal = normal;
		this.constant = constant;

		return this;
	}

	/// Copies all values from the given plane to this plane.
	Plane copy(Plane plane ) {
		normal.copy( plane.normal );
		constant = plane.constant;

		return this;
	}

	/// Creates a new plane and copies all values from this plane.
	Plane clone() {
		return Plane().copy( this );
	}

	/// Computes the signed distance from the given 3D vector to this plane.
	/// The sign of the distance indicates the half-space in which the points lies.
	/// Zero means the point lies on the plane.
	double distanceToPoint(Vector3 point ) {
		return normal.dot( point ) + constant;
	}

	/// Sets the values of the plane from the given normal vector and a coplanar point.
	Plane fromNormalAndCoplanarPoint(Vector3 normal, Vector3 point ) {
		this.normal.copy( normal );
		constant = - point.dot( this.normal );

		return this;
	}

	/// Sets the values of the plane from three given coplanar points.
	Plane fromCoplanarPoints(Vector3 a, Vector3 b, Vector3 c ) {
		v1.subVectors( c, b ).cross( v2.subVectors( a, b ) ).normalize();
		fromNormalAndCoplanarPoint( v1, a );

		return this;
	}

	/// Performs a plane/plane intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	///
	/// Reference: Intersection of Two Planes in Real-Time Collision Detection
	/// by Christer Ericson (chapter 5.4.4)
	Vector3? intersectPlane(Plane plane, Vector3 result ) {
		// compute direction of intersection line
		d.crossVectors( normal, plane.normal );

		// if d is zero, the planes are parallel (and separated)
		// or coincident, so they’re not considered intersecting
		final denom = d.dot( d );
		if ( denom == 0 ) return null;

		// compute point on intersection line
		v1.copy( plane.normal ).multiplyScalar( constant );
		v2.copy( normal ).multiplyScalar( plane.constant );

		result.crossVectors( v1.sub( v2 ), d ).divideScalar( denom );

		return result;
	}

	/// Returns true if the given plane intersects this plane.
	bool intersectsPlane(Plane plane ) {
		final d = normal.dot( plane.normal );
		return ( d.abs() != 1 );
	}

	/// Projects the given point onto the plane. The result is written
	/// to the given vector.
	Vector3 projectPoint(Vector3 point, Vector3 result ) {
		v1.copy( normal ).multiplyScalar( distanceToPoint( point ) );
		result.subVectors( point, v1 );
		return result;
	}

	/// Returns true if the given plane is deep equal with this plane.
	bool equals(Plane plane ) {
		return plane.normal.equals( normal ) && plane.constant == constant;
	}
}
