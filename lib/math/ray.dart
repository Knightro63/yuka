import 'aabb.dart';
import 'bounding_sphere.dart';
import 'bvh.dart';
import 'convex_hull.dart';
import 'matrix4.dart';
import 'obb.dart';
import 'plane.dart';
import 'vector3.dart';
import 'dart:math' as math;

final _localRay = Ray();

/// Class representing a ray in 3D space.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Ray {
  final v1 = Vector3();
  final edge1 = Vector3();
  final edge2 = Vector3();
  final normal = Vector3();
  final size = Vector3();
  final matrix = Matrix4();
  final inverse = Matrix4();
  final aabb = AABB();

  late final Vector3 origin;
  late final Vector3 direction;

	/// Constructs a ray with the given values.
	Ray([Vector3? origin, Vector3? direction]) {
		this.origin = origin ?? Vector3() ;
		this.direction = direction ?? Vector3() ;
	}

	/// Sets the given values to this ray.
	Ray set(Vector3 origin, Vector3 direction ) {
		this.origin = origin;
		this.direction = direction;

		return this;
	}

	/// Copies all values from the given ray to this ray.
	Ray copy( Ray ray ) {
		origin.copy( ray.origin );
		direction.copy( ray.direction );

		return this;
	}

	/// Creates a ray and copies all values from this ray.
	Ray clone() {
		return Ray().copy( this );
	}

	/// Computes a position on the ray according to the given t value
	/// and stores the result in the given 3D vector. The t value has a range of
	/// [0, double.infinity] where 0 means the position is equal with the origin of the ray.
	Vector3 at(double t, Vector3 result ) {
		// t has to be zero or positive
		return result.copy( direction ).multiplyScalar( t ).add( origin );
	}

	/// Performs a ray/sphere intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectBoundingSphere(BoundingSphere sphere, Vector3 result ) {
		v1.subVectors( sphere.center, origin );
		final tca = v1.dot( direction );
		final d2 = v1.dot( v1 ) - tca * tca;
		final radius2 = sphere.radius * sphere.radius;

		if ( d2 > radius2 ) return null;

		final thc = math.sqrt( radius2 - d2 );

		// t0 = first intersect point - entrance on front of sphere
		final t0 = tca - thc;

		// t1 = second intersect point - exit point on back of sphere
		final t1 = tca + thc;

		// test to see if both t0 and t1 are behind the ray - if so, return null
		if ( t0 < 0 && t1 < 0 ) return null;

		// test to see if t0 is behind the ray:
		// if it is, the ray is inside the sphere, so return the second exit point scaled by t1,
		// in order to always return an intersect point that is in front of the ray.
		if ( t0 < 0 ) return at( t1, result );

		// else t0 is in front of the ray, so return the first collision point scaled by t0
		return at( t0, result );
	}

	/// Performs a ray/sphere intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsBoundingSphere(BoundingSphere sphere ) {
    final v1 = Vector3();
		double squaredDistanceToPoint;

		final directionDistance = v1.subVectors( sphere.center, origin ).dot( direction );

		if ( directionDistance < 0 ) {
			// sphere's center behind the ray
			squaredDistanceToPoint = origin.squaredDistanceTo( sphere.center );
		} 
    else {
			v1.copy( direction ).multiplyScalar( directionDistance ).add( origin );
			squaredDistanceToPoint = v1.squaredDistanceTo( sphere.center );
		}


		return squaredDistanceToPoint <= ( sphere.radius * sphere.radius );
	}

	/// Performs a ray/AABB intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectAABB(AABB aabb, Vector3 result ) {
		double tmin, tmax, tymin, tymax, tzmin, tzmax;

		final invdirx = 1 / direction.x,
			invdiry = 1 / direction.y,
			invdirz = 1 / direction.z;

		final origin = this.origin;

		if ( invdirx >= 0 ) {
			tmin = ( aabb.min.x - origin.x ) * invdirx;
			tmax = ( aabb.max.x - origin.x ) * invdirx;
		} 
    else {
			tmin = ( aabb.max.x - origin.x ) * invdirx;
			tmax = ( aabb.min.x - origin.x ) * invdirx;
		}

		if ( invdiry >= 0 ) {
			tymin = ( aabb.min.y - origin.y ) * invdiry;
			tymax = ( aabb.max.y - origin.y ) * invdiry;
		} 
    else {
			tymin = ( aabb.max.y - origin.y ) * invdiry;
			tymax = ( aabb.min.y - origin.y ) * invdiry;
		}

		if ( ( tmin > tymax ) || ( tymin > tmax ) ) return null;

		// these lines also handle the case where tmin or tmax is NaN
		// (result of 0 * double.infinity). x !== x returns true if x is NaN

		if ( tymin > tmin || tmin != tmin ) tmin = tymin;

		if ( tymax < tmax || tmax != tmax ) tmax = tymax;

		if ( invdirz >= 0 ) {
			tzmin = ( aabb.min.z - origin.z ) * invdirz;
			tzmax = ( aabb.max.z - origin.z ) * invdirz;
		} 
    else {
			tzmin = ( aabb.max.z - origin.z ) * invdirz;
			tzmax = ( aabb.min.z - origin.z ) * invdirz;
		}

		if ( ( tmin > tzmax ) || ( tzmin > tmax ) ) return null;

		if ( tzmin > tmin || tmin != tmin ) tmin = tzmin;

		if ( tzmax < tmax || tmax != tmax ) tmax = tzmax;

		// return point closest to the ray (positive side)

		if ( tmax < 0 ) return null;

		return at( tmin >= 0 ? tmin : tmax, result );
	}

	/// Performs a ray/AABB intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsAABB(AABB aabb ) {
		return intersectAABB( aabb, v1 ) != null;
	}

	/// Performs a ray/plane intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectPlane(Plane plane, Vector3 result ) {
		double t;

		final denominator = plane.normal.dot( direction );

		if ( denominator == 0 ) {
			if ( plane.distanceToPoint( origin ) == 0 ) {
				// ray is coplanar
				t = 0;
			} 
      else {
				// ray is parallel, no intersection
				return null;
			}
		} 
    else {
			t = - ( origin.dot( plane.normal ) + plane.constant ) / denominator;
		}

		// there is no intersection if t is negative

		return ( t >= 0 ) ? at( t, result ) : null;
	}

	/// Performs a ray/plane intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsPlane(Plane plane ) {
		// check if the ray lies on the plane first
		final distToPoint = plane.distanceToPoint( origin );

		if ( distToPoint == 0 ) {
			return true;
		}

		final denominator = plane.normal.dot( direction );

		if ( denominator * distToPoint < 0 ) {
			return true;
		}

		// ray origin is behind the plane (and is pointing behind it)
		return false;
	}

	/// Performs a ray/OBB intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectOBB(OBB obb, Vector3 result ) {
		// the idea is to perform the intersection test in the local space
		// of the OBB.
		obb.getSize( size );
		aabb.fromCenterAndSize( v1.set( 0, 0, 0 ), size );

		matrix.fromMatrix3( obb.rotation );
		matrix.setPosition( obb.center );

		// transform ray to the local space of the OBB
		_localRay.copy( this ).applyMatrix4( matrix.getInverse( inverse ) );

		// perform ray <-> AABB intersection test
		if ( _localRay.intersectAABB( aabb, result ) != null) {
			// transform the intersection point back to world space
			return result.applyMatrix4( matrix );
		} 
    else {
			return null;
		}
	}

	/// Performs a ray/OBB intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsOBB(OBB obb ) {
		return intersectOBB( obb, v1 ) != null;
	}

	/// Performs a ray/convex hull intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	/// The implementation is based on "Fast Ray-Convex Polyhedron Intersection"
	/// by Eric Haines, GRAPHICS GEMS II
	Vector3? intersectConvexHull(ConvexHull convexHull, Vector3 result ) {
		final faces = convexHull.faces;

		double tNear = - double.infinity;
		double tFar = double.infinity;

		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			final plane = face.plane;

			final vN = plane.distanceToPoint( origin );
			final vD = plane.normal.dot( direction );

			// if the origin is on the positive side of a plane (so the plane can "see" the origin) and
			// the ray is turned away or parallel to the plane, there is no intersection
			if ( vN > 0 && vD >= 0 ) return null;

			// compute the distance from the ray’s origin to the intersection with the plane
			final double t = ( vD != 0 ) ? ( - vN / vD ) : 0;

			// only proceed if the distance is positive. since the ray has a direction, the intersection point
			// would lie "behind" the origin with a negative distance
			if ( t <= 0 ) continue;

			// now categorized plane as front-facing or back-facing
			if ( vD > 0 ) {
				//  plane faces away from the ray, so this plane is a back-face
				tFar = math.min( t, tFar );
			} 
      else {
				// front-face
				tNear = math.max( t, tNear );
			}

			if ( tNear > tFar ) {
				// if tNear ever is greater than tFar, the ray must miss the convex hull
				return null;
			}
		}

		// evaluate intersection point
		// always try tNear first since its the closer intersection point
		if ( tNear != - double.infinity ) {
			at( tNear, result );
		} 
    else {
			at( tFar, result );
		}

		return result;
	}

	/// Performs a ray/convex hull intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsConvexHull(ConvexHull convexHull ) {
		return intersectConvexHull( convexHull, v1 ) != null;
	}

	/// Performs a ray/triangle intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectTriangle(Map<String,Vector3> triangle, bool backfaceCulling, Vector3 result ) {
		// reference: https://www.geometrictools.com/GTEngine/Include/Mathematics/GteIntrRay3Triangle3.h
		final a = triangle['a']!;
		final b = triangle['b']!;
		final c = triangle['c']!;

		edge1.subVectors( b, a );
		edge2.subVectors( c, a );
		normal.crossVectors( edge1, edge2 );

		double ddN = direction.dot( normal );
		int sign;

		if ( ddN > 0 ) {
			if ( backfaceCulling ) return null;
			sign = 1;
		} 
    else if ( ddN < 0 ) {
			sign = - 1;
			ddN = - ddN;
		} 
    else {
			return null;
		}

		v1.subVectors( origin, a );
		final ddQxE2 = sign * direction.dot( edge2.crossVectors( v1, edge2 ) );

		// b1 < 0, no intersection
		if ( ddQxE2 < 0 ) {
			return null;
		}

		final ddE1xQ = sign * direction.dot( edge1.cross( v1 ) );

		// b2 < 0, no intersection
		if ( ddE1xQ < 0 ) {
			return null;
		}

		// b1 + b2 > 1, no intersection
		if ( ddQxE2 + ddE1xQ > ddN ) {
			return null;
		}

		// line intersects triangle, check if ray does
		final qdN = - sign * v1.dot( normal );

		// t < 0, no intersection
		if ( qdN < 0 ) {
			return null;
		}

		// ray intersects triangle
		return at( qdN / ddN, result );
	}

	/// Performs a ray/BVH intersection test and stores the intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectBVH(BVH bvh, Vector3 result ) {
		return bvh.root?.intersectRay( this, result );
	}

	/// Performs a ray/BVH intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsBVH(BVH bvh ) {
		return bvh.root!.intersectsRay( this );
	}

	/// Transforms this ray by the given 4x4 matrix.
	Ray applyMatrix4(Matrix4 m ) {
		origin.applyMatrix4( m );
		direction.transformDirection( m );

		return this;
	}

	/// Returns true if the given ray is deep equal with this ray.
	bool equals(Ray ray ) {
		return ray.origin.equals( origin ) && ray.direction.equals( direction );
	}
}


