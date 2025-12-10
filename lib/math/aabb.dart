import './vector3.dart';
import 'bounding_sphere.dart';
import 'matrix4.dart';
import 'plane.dart';

/// Class representing an axis-aligned bounding box (AABB).
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AABB {
  final vector = Vector3();
  final center = Vector3();
  final size = Vector3();

  final points = [
    Vector3(),
    Vector3(),
    Vector3(),
    Vector3(),
    Vector3(),
    Vector3(),
    Vector3(),
    Vector3()
  ];

  late Vector3 min;
  late Vector3 max;

	/// Constructs a new AABB with the given values.
	AABB([Vector3? min, Vector3? max ]) {
		this.min = min ?? Vector3();
		this.max = max ?? Vector3();
	}

	/// Sets the given values to this AABB.
	AABB set(Vector3 min, Vector3 max ) {
		this.min = min;
		this.max = max;

		return this;
	}

	/// Copies all values from the given AABB to this AABB.
	AABB copy(AABB aabb ) {
		min.copy( aabb.min );
		max.copy( aabb.max );

		return this;
	}

	/// Creates a new AABB and copies all values from this AABB.
	AABB clone() {
		return AABB().copy( this );
	}

	/// Ensures the given point is inside this AABB and stores
	/// the result in the given vector.
	Vector3 clampPoint(Vector3 point, Vector3 result ) {
		result.copy( point ).clamp( min, max );
		return result;
	}

	/// Returns true if the given point is inside this AABB.
	bool containsPoint(Vector3 point ) {
		return point.x < min.x || point.x > max.x ||
			point.y < min.y || point.y > max.y ||
			point.z < min.z || point.z > max.z ? false : true;
	}

	/// Expands this AABB by the given point. So after this method call,
	/// the given point lies inside the AABB.
	AABB expand(Vector3 point ) {
		min.min( point );
		max.max( point );

		return this;
	}

	/// Computes the center point of this AABB and stores it into the given vector.
	Vector3 getCenter(Vector3 result ) {
		return result.addVectors( min, max ).multiplyScalar( 0.5 );
	}

	/// Computes the size (width, height, depth) of this AABB and stores it into the given vector.
	Vector3 getSize(Vector3 result ) {
		return result.subVectors( max, min );
	}

	/// Returns true if the given AABB intersects this AABB.
	bool intersectsAABB(AABB aabb ) {
		return aabb.max.x < min.x || aabb.min.x > max.x ||
			aabb.max.y < min.y || aabb.min.y > max.y ||
			aabb.max.z < min.z || aabb.min.z > max.z ? false : true;
	}

	/// Returns true if the given bounding sphere intersects this AABB.
	bool intersectsBoundingSphere(BoundingSphere sphere ) {
		// find the point on the AABB closest to the sphere center
		clampPoint( sphere.center, vector );

		// if that point is inside the sphere, the AABB and sphere intersect.
		return vector.squaredDistanceTo( sphere.center ) <= ( sphere.radius * sphere.radius );
	}

	/// Returns true if the given plane intersects this AABB.
	///
	/// Reference: Testing Box Against Plane in Real-Time Collision Detection
	/// by Christer Ericson (chapter 5.2.3)
	bool intersectsPlane(Plane plane ) {
		final normal = plane.normal;

		getCenter( center );
		size.subVectors( max, center ); // positive extends

		// compute the projection interval radius of b onto L(t) = c + t * plane.normal
		final r = size.x * normal.x.abs(  ) + size.y * normal.y.abs(  ) + size.z * normal.z.abs(  );

		// compute distance of box center from plane
		final s = plane.distanceToPoint( center );
		return s.abs(  ) <= r;
	}

	/// Returns the normal for a given point on this AABB's surface.
	Vector3 getNormalFromSurfacePoint(Vector3 point, Vector3 result ) {
		// from https://www.gamedev.net/forums/topic/551816-finding-the-aabb-surface-normal-from-an-intersection-point-on-aabb/
		result.set( 0, 0, 0 );

		double distance;
		double minDistance = double.infinity;

		getCenter( center );
		getSize( size );

		// transform point into local space of AABB
		vector.copy( point ).sub( center );

		// x-axis
		distance = ( size.x - vector.x.abs() ).abs();

		if ( distance < minDistance ) {
			minDistance = distance;
			result.set( 1 * vector.x.sign, 0, 0 );
		}

		// y-axis
		distance = ( size.y - vector.y.abs(  ) ).abs();

		if ( distance < minDistance ) {
			minDistance = distance;
			result.set( 0, 1 * vector.y.sign, 0 );
		}

		// z-axis
		distance = ( size.z - vector.z.abs(  ) ).abs();

		if ( distance < minDistance ) {
			result.set( 0, 0, 1 * vector.z.sign);
		}

		return result;
	}

	/// Sets the values of the AABB from the given center and size vector.
	AABB fromCenterAndSize(Vector3 center, Vector3 size ) {
		vector.copy( size ).multiplyScalar( 0.5 ); // compute half size

		min.copy( center ).sub( vector );
		max.copy( center ).add( vector );

		return this;
	}

	/// Computes an AABB that encloses the given set of points.
	AABB fromPoints(List<Vector3> points ) {
		min.set( double.infinity, double.infinity, double.infinity );
		max.set( - double.infinity, - double.infinity, - double.infinity );

		for ( int i = 0, l = points.length; i < l; i ++ ) {
			expand( points[ i ] );
		}

		return this;
	}

	/// Transforms this AABB with the given 4x4 transformation matrix.
	AABB applyMatrix4(Matrix4 matrix ) {
		final min = this.min;
		final max = this.max;

		points[ 0 ].set( min.x, min.y, min.z ).applyMatrix4( matrix );
		points[ 1 ].set( min.x, min.y, max.z ).applyMatrix4( matrix );
		points[ 2 ].set( min.x, max.y, min.z ).applyMatrix4( matrix );
		points[ 3 ].set( min.x, max.y, max.z ).applyMatrix4( matrix );
		points[ 4 ].set( max.x, min.y, min.z ).applyMatrix4( matrix );
		points[ 5 ].set( max.x, min.y, max.z ).applyMatrix4( matrix );
		points[ 6 ].set( max.x, max.y, min.z ).applyMatrix4( matrix );
		points[ 7 ].set( max.x, max.y, max.z ).applyMatrix4( matrix );

		return fromPoints( points );
	}

	/// Returns true if the given AABB is deep equal with this AABB.
	bool equals(AABB aabb ) {
		return ( aabb.min.equals( min ) ) && ( aabb.max.equals( max ) );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'min': min.storage,
			'max': max.storage
		};
	}

	/// Restores this instance from the given JSON object.
	AABB fromJSON(Map<String,dynamic> json ) {
		min.fromArray( json['min'] );
		max.fromArray( json['max'] );

		return this;
	}
}
