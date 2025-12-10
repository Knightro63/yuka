import 'aabb.dart';
import 'matrix4.dart';
import 'plane.dart';
import 'vector3.dart';

/// Class representing a bounding sphere.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class BoundingSphere {
  late Vector3 center;
  final aabb = AABB();
  double radius;

	/// Constructs a new bounding sphere with the given values.
	BoundingSphere([ Vector3? center, this.radius = 0 ]) {
		this.center = center ?? Vector3();
	}

	/// Sets the given values to this bounding sphere.
	BoundingSphere set(Vector3 center, double radius ) {
		this.center = center;
		this.radius = radius;

		return this;
	}

	/// Copies all values from the given bounding sphere to this bounding sphere.
	BoundingSphere copy(BoundingSphere sphere ) {
		center.copy( sphere.center );
		radius = sphere.radius;

		return this;
	}

	/// Creates a new bounding sphere and copies all values from this bounding sphere.
	BoundingSphere clone() {
		return BoundingSphere().copy( this );
	}

	/// Ensures the given point is inside this bounding sphere and stores
	/// the result in the given vector.
	Vector3 clampPoint( Vector3 point, Vector3 result ) {
		result.copy( point );

		final squaredDistance = center.squaredDistanceTo( point );

		if ( squaredDistance > ( radius * radius ) ) {

			result.sub( center ).normalize();
			result.multiplyScalar( radius ).add(center );

		}

		return result;
	}

	/// Returns true if the given point is inside this bounding sphere.
	bool containsPoint(Vector3 point ) {
		return ( point.squaredDistanceTo( center ) <= ( radius * radius ) );
	}

	/// Returns true if the given bounding sphere intersects this bounding sphere.
	bool intersectsBoundingSphere(BoundingSphere sphere ) {
		final radius = this.radius + sphere.radius;
		return ( sphere.center.squaredDistanceTo( center ) <= ( radius * radius ) );
	}

	/// Returns true if the given plane intersects this bounding sphere.
	///
	/// Reference: Testing Sphere Against Plane in Real-Time Collision Detection
	/// by Christer Ericson (chapter 5.2.2)
	bool intersectsPlane(Plane plane ) {
		return plane.distanceToPoint( center ).abs() <= radius;
	}

	/// Returns the normal for a given point on this bounding sphere's surface.
	Vector3 getNormalFromSurfacePoint(Vector3 point, Vector3 result ) {
		return result.subVectors( point, center ).normalize();
	}

	/// Computes a bounding sphere that encloses the given set of points.
	BoundingSphere fromPoints(List<Vector3> points ) {
		// Using an AABB is a simple way to compute a bounding sphere for a given set
		// of points. However, there are other more complex algorithms that produce a
		// more tight bounding sphere. For now, this approach is a good start.
		aabb.fromPoints( points );

		aabb.getCenter( center );
		radius = center.distanceTo( aabb.max );

		return this;
	}

	/// Transforms this bounding sphere with the given 4x4 transformation matrix.
	BoundingSphere applyMatrix4(Matrix4 matrix ) {
		center.applyMatrix4( matrix );
		radius = radius * matrix.getMaxScale();

		return this;
	}

	/// Returns true if the given bounding sphere is deep equal with this bounding sphere.
	bool equals(BoundingSphere sphere ) {
		return ( sphere.center.equals( center ) ) && ( sphere.radius == radius );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'center': center.storage,
			'radius': radius
		};
	}

	/// Restores this instance from the given JSON object.
	BoundingSphere fromJSON(Map<String,dynamic> json ) {
		center.fromArray( json['center'] );
		radius = json['radius'];

		return this;
	}

}
