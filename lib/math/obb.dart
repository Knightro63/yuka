import 'aabb.dart';
import 'bounding_sphere.dart';
import 'convex_hull.dart';
import 'half_edge.dart';
import 'math_utils.dart';
import 'matrix3.dart';
import 'plane.dart';
import 'vector3.dart';
import 'dart:math' as math;

final _obb = OBB();

/// Class representing an oriented bounding box (OBB). Similar to an AABB, it's a
/// rectangular block but with an arbitrary orientation. When using {@link OBB#fromPoints},
/// the implementation tries to provide a tight-fitting oriented bounding box. In
/// many cases, the result is better than an AABB or bounding sphere but worse than a
/// convex hull. However, it's more efficient to work with OBBs compared to convex hulls.
/// In general, OBB's are a good compromise between performance and tightness.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class OBB {
  final _closestPoint = Vector3();
  final _xAxis = Vector3();
  final _yAxis = Vector3();
  final _zAxis = Vector3();
  final _v1 = Vector3();

  final Map<String,Matrix3> eigenDecomposition = {
    'unitary': Matrix3(),
    'diagonal': Matrix3()
  };

  final Map<String,dynamic> a = {
    'c': null, // center
    'u': [ Vector3(), Vector3(), Vector3() ], // basis vectors
    'e': [] // half width
  };

  final Map<String,dynamic> b = {
    'c': null, // center
    'u': [ Vector3(), Vector3(), Vector3() ], // basis vectors
    'e': [] // half width
  };

  final List<List<double>> R = [[], [], []];
  final List<List<double>> absR = [[], [], []];
  final List<double> t = [];

  late final Vector3 center;
  late final Vector3 halfSizes;
  late final Matrix3 rotation;

	/// Constructs a OBB with the given values.
	OBB( [Vector3? center, Vector3? halfSizes, Matrix3? rotation] ) {
		this.center = center ?? Vector3();
		this.halfSizes = halfSizes ?? Vector3();
		this.rotation = rotation ?? Matrix3();
	}

	/// Sets the given values to this OBB.
	OBB set(Vector3 center, Vector3 halfSizes, Matrix3 rotation ) {
		this.center = center;
		this.halfSizes = halfSizes;
		this.rotation = rotation;

		return this;
	}

	/// Copies all values from the given OBB to this OBB.
	OBB copy(OBB obb ) {
		center.copy( obb.center );
		halfSizes.copy( obb.halfSizes );
		rotation.copy( obb.rotation );

		return this;
	}

	/// Creates a OBB and copies all values from this OBB.
	OBB clone() {
		return OBB().copy( this );
	}

	/// Computes the size (width, height, depth) of this OBB and stores it into the given vector.
	Vector3 getSize(Vector3 result ) {
		return result.copy( halfSizes ).multiplyScalar( 2 );
	}

	/// Ensures the given point is inside this OBB and stores
	/// the result in the given vector.
	///
	/// Reference: Closest Point on OBB to Point in Real-Time Collision Detection
/// by Christer Ericson (chapter 5.1.4)
	Vector3 clampPoint(Vector3 point, Vector3 result ) {
		final halfSizes = this.halfSizes;

		_v1.subVectors( point, center );
		rotation.extractBasis( _xAxis, _yAxis, _zAxis );

		// start at the center position of the OBB
		result.copy( center );

		// project the target onto the OBB axes and walk towards that point
		final x = MathUtils.clamp( _v1.dot( _xAxis ), - halfSizes.x, halfSizes.x );
		result.add( _xAxis.multiplyScalar( x ) );

		final y = MathUtils.clamp( _v1.dot( _yAxis ), - halfSizes.y, halfSizes.y );
		result.add( _yAxis.multiplyScalar( y ) );

		final z = MathUtils.clamp( _v1.dot( _zAxis ), - halfSizes.z, halfSizes.z );
		result.add( _zAxis.multiplyScalar( z ) );

		return result;
	}

	/// Returns true if the given point is inside this OBB.
	bool containsPoint(Vector3 point ) {
		_v1.subVectors( point, center );
		rotation.extractBasis( _xAxis, _yAxis, _zAxis );

		// project v1 onto each axis and check if these points lie inside the OBB
		return _v1.dot( _xAxis ).abs() <= halfSizes.x &&
				_v1.dot( _yAxis ).abs() <= halfSizes.y &&
				_v1.dot( _zAxis ).abs() <= halfSizes.z;
	}

	/// Returns true if the given AABB intersects this OBB.
	bool intersectsAABB(AABB aabb ) {
		return intersectsOBB( _obb.fromAABB( aabb ) );
	}

	/// Returns true if the given bounding sphere intersects this OBB.
	bool intersectsBoundingSphere(BoundingSphere sphere ) {
		// find the point on the OBB closest to the sphere center
		clampPoint( sphere.center, _closestPoint );
		// if that point is inside the sphere, the OBB and sphere intersect
		return _closestPoint.squaredDistanceTo( sphere.center ) <= ( sphere.radius * sphere.radius );
	}

	/// Returns true if the given OBB intersects this OBB.
	///
	/// Reference: OBB-OBB Intersection in Real-Time Collision Detection
	/// by Christer Ericson (chapter 4.4.1)
	bool intersectsOBB(OBB obb, [double epsilon = MathUtils.epsilon] ) {
		// prepare data structures (the code uses the same nomenclature like the reference)
		a['c'] = center;
		a['e'][ 0 ] = halfSizes.x;
		a['e'][ 1 ] = halfSizes.y;
		a['e'][ 2 ] = halfSizes.z;
		rotation.extractBasis( a['u'][ 0 ], a['u'][ 1 ], a['u'][ 2 ] );

		b['c'] = obb.center;
		b['e'][ 0 ] = obb.halfSizes.x;
		b['e'][ 1 ] = obb.halfSizes.y;
		b['e'][ 2 ] = obb.halfSizes.z;
		obb.rotation.extractBasis( b['u'][ 0 ], b['u'][ 1 ], b['u'][ 2 ] );

		// compute rotation matrix expressing b in a’s coordinate frame
		for ( int i = 0; i < 3; i ++ ) {
			for ( int j = 0; j < 3; j ++ ) {
				R[ i ][ j ] = a['u'][ i ].dot( b['u'][ j ] );
			}
		}

		// compute translation vector
		_v1.subVectors( b['c'], a['c'] );

		// bring translation into a’s coordinate frame
		t[ 0 ] = _v1.dot( a['u'][ 0 ] );
		t[ 1 ] = _v1.dot( a['u'][ 1 ] );
		t[ 2 ] = _v1.dot( a['u'][ 2 ] );

		// compute common subexpressions. Add in an epsilon term to
		// counteract arithmetic errors when two edges are parallel and
		// their cross product is (near) null

		for ( int i = 0; i < 3; i ++ ) {
			for ( int j = 0; j < 3; j ++ ) {
				absR[i][j] = R[i][j].abs() + epsilon;
			}
		}

		double ra, rb;

		// test axes L = A0, L = A1, L = A2
		for ( int i = 0; i < 3; i ++ ) {
			ra = a['e'][ i ];
			rb = b['e'][ 0 ] * absR[ i ][ 0 ] + b['e'][ 1 ] * absR[ i ][ 1 ] + b['e'][ 2 ] * absR[ i ][ 2 ];
			if ( t[ i ].abs() > ra + rb ) return false;
		}

		// test axes L = B0, L = B1, L = B2

		for ( int i = 0; i < 3; i ++ ) {
			ra = a['e'][ 0 ] * absR[ 0 ][ i ] + a['e'][ 1 ] * absR[ 1 ][ i ] + a['e'][ 2 ] * absR[ 2 ][ i ];
			rb = b['e'][ i ];
			if ( ( t[ 0 ] * R[ 0 ][ i ] + t[ 1 ] * R[ 1 ][ i ] + t[ 2 ] * R[ 2 ][ i ] ).abs() > ra + rb ) return false;
		}

		// test axis L = A0 x B0

		ra = a['e'][ 1 ] * absR[ 2 ][ 0 ] + a['e'][ 2 ] * absR[ 1 ][ 0 ];
		rb = b['e'][ 1 ] * absR[ 0 ][ 2 ] + b['e'][ 2 ] * absR[ 0 ][ 1 ];
		if ( ( t[ 2 ] * R[ 1 ][ 0 ] - t[ 1 ] * R[ 2 ][ 0 ] ).abs() > ra + rb ) return false;

		// test axis L = A0 x B1

		ra = a['e'][ 1 ] * absR[ 2 ][ 1 ] + a['e'][ 2 ] * absR[ 1 ][ 1 ];
		rb = b['e'][ 0 ] * absR[ 0 ][ 2 ] + b['e'][ 2 ] * absR[ 0 ][ 0 ];
		if ( ( t[ 2 ] * R[ 1 ][ 1 ] - t[ 1 ] * R[ 2 ][ 1 ] ).abs() > ra + rb ) return false;

		// test axis L = A0 x B2

		ra = a['e'][ 1 ] * absR[ 2 ][ 2 ] + a['e'][ 2 ] * absR[ 1 ][ 2 ];
		rb = b['e'][ 0 ] * absR[ 0 ][ 1 ] + b['e'][ 1 ] * absR[ 0 ][ 0 ];
		if ( ( t[ 2 ] * R[ 1 ][ 2 ] - t[ 1 ] * R[ 2 ][ 2 ] ).abs() > ra + rb ) return false;

		// test axis L = A1 x B0

		ra = a['e'][ 0 ] * absR[ 2 ][ 0 ] + a['e'][ 2 ] * absR[ 0 ][ 0 ];
		rb = b['e'][ 1 ] * absR[ 1 ][ 2 ] + b['e'][ 2 ] * absR[ 1 ][ 1 ];
		if ( ( t[ 0 ] * R[ 2 ][ 0 ] - t[ 2 ] * R[ 0 ][ 0 ] ).abs() > ra + rb ) return false;

		// test axis L = A1 x B1

		ra = a['e'][ 0 ] * absR[ 2 ][ 1 ] + a['e'][ 2 ] * absR[ 0 ][ 1 ];
		rb = b['e'][ 0 ] * absR[ 1 ][ 2 ] + b['e'][ 2 ] * absR[ 1 ][ 0 ];
		if ( ( t[ 0 ] * R[ 2 ][ 1 ] - t[ 2 ] * R[ 0 ][ 1 ] ).abs() > ra + rb ) return false;

		// test axis L = A1 x B2

		ra = a['e'][ 0 ] * absR[ 2 ][ 2 ] + a['e'][ 2 ] * absR[ 0 ][ 2 ];
		rb = b['e'][ 0 ] * absR[ 1 ][ 1 ] + b['e'][ 1 ] * absR[ 1 ][ 0 ];
		if ( ( t[ 0 ] * R[ 2 ][ 2 ] - t[ 2 ] * R[ 0 ][ 2 ] ).abs() > ra + rb ) return false;

		// test axis L = A2 x B0

		ra = a['e'][ 0 ] * absR[ 1 ][ 0 ] + a['e'][ 1 ] * absR[ 0 ][ 0 ];
		rb = b['e'][ 1 ] * absR[ 2 ][ 2 ] + b['e'][ 2 ] * absR[ 2 ][ 1 ];
		if ( ( t[ 1 ] * R[ 0 ][ 0 ] - t[ 0 ] * R[ 1 ][ 0 ] ).abs() > ra + rb ) return false;

		// test axis L = A2 x B1

		ra = a['e'][ 0 ] * absR[ 1 ][ 1 ] + a['e'][ 1 ] * absR[ 0 ][ 1 ];
		rb = b['e'][ 0 ] * absR[ 2 ][ 2 ] + b['e'][ 2 ] * absR[ 2 ][ 0 ];
		if ( ( t[ 1 ] * R[ 0 ][ 1 ] - t[ 0 ] * R[ 1 ][ 1 ] ).abs() > ra + rb ) return false;

		// test axis L = A2 x B2

		ra = a['e'][ 0 ] * absR[ 1 ][ 2 ] + a['e'][ 1 ] * absR[ 0 ][ 2 ];
		rb = b['e'][ 0 ] * absR[ 2 ][ 1 ] + b['e'][ 1 ] * absR[ 2 ][ 0 ];
		if ( ( t[ 1 ] * R[ 0 ][ 2 ] - t[ 0 ] * R[ 1 ][ 2 ] ).abs() > ra + rb ) return false;

		// since no separating axis is found, the OBBs must be intersecting

		return true;

	}

	/// Returns true if the given plane intersects this OBB.
	///
	/// Reference: Testing Box Against Plane in Real-Time Collision Detection
	/// by Christer Ericson (chapter 5.2.3)
	bool intersectsPlane(Plane plane ) {
		rotation.extractBasis( _xAxis, _yAxis, _zAxis );

		// compute the projection interval radius of this OBB onto L(t) = this->center + t * p.normal;
		final r = halfSizes.x * plane.normal.dot( _xAxis ).abs(  ) +
				halfSizes.y * plane.normal.dot( _yAxis ).abs(  ) +
				halfSizes.z * plane.normal.dot( _zAxis ).abs(  );

		// compute distance of the OBB's center from the plane
		final d = plane.normal.dot( center ) - plane.constant;

		// Intersection occurs when distance d falls within [-r,+r] interval
		return d.abs() <= r;
	}

	/// Computes the OBB from an AABB.
	OBB fromAABB(AABB aabb ) {
		aabb.getCenter( center );
		aabb.getSize( halfSizes ).multiplyScalar( 0.5 );
		rotation.identity();

		return this;
	}

	/// Computes the minimum enclosing OBB for the given set of points. The method is an
	/// implementation of {@link http://gamma.cs.unc.edu/users/gottschalk/main.pdf Collision Queries using Oriented Bounding Boxes}
	/// by Stefan Gottschalk.
	/// According to the dissertation, the quality of the fitting process varies from
	/// the respective input. This method uses the best approach by computing the
	/// covariance matrix based on the triangles of the convex hull (chapter 3.4.3).
	///
	/// However, the implementation is susceptible to {@link https://en.wikipedia.org/wiki/Regular_polygon regular polygons}
	/// like cubes or spheres. For such shapes, it's recommended to verify the quality
  /// of the produced OBB. Consider to use an AABB or bounding sphere if the result
	/// is not satisfying.
	OBB fromPoints(List<Vector3> points ) {
		final convexHull = ConvexHull().fromPoints( points );
    print(convexHull.faces.length);

		// 1. iterate over all faces of the convex hull and triangulate
		final faces = convexHull.faces;
		final List<HalfEdge> edges = [];
		final List<double> triangles = [];

		for ( int i = 0, il = faces.length; i < il; i ++ ) {
			final face = faces[ i ];
			HalfEdge? edge = face.edge;

			edges.length = 0;

			// gather edges
			do{
				edges.add( edge! );
				edge = edge.next;
			} while ( edge != face.edge ); 

			// triangulate
			final triangleCount = ( edges.length - 2 );

			for ( int j = 1, jl = triangleCount; j <= jl; j ++ ) {
				final v1 = edges[ 0 ].vertex;
				final v2 = edges[ j + 0 ].vertex;
				final v3 = edges[ j + 1 ].vertex;

				triangles.addAll([ v1.x, v1.y, v1.z ]);
				triangles.addAll( [v2.x, v2.y, v2.z] );
				triangles.addAll( [v3.x, v3.y, v3.z] );
			}
		}

		// 2. build covariance matrix

		final p = Vector3();
		final q = Vector3();
		final r = Vector3();

		final qp = Vector3();
		final rp = Vector3();

		final v = Vector3();

		final mean = Vector3();
		final weightedMean = Vector3();
		double areaSum = 0;

		double cxx, cxy, cxz, cyy, cyz, czz;
		cxx = cxy = cxz = cyy = cyz = czz = 0;

		for ( int i = 0, l = triangles.length; i < l; i += 9 ) {

			p.fromArray( triangles, i );
			q.fromArray( triangles, i + 3 );
			r.fromArray( triangles, i + 6 );

			mean.set( 0, 0, 0 );
			mean.add( p ).add( q ).add( r ).divideScalar( 3 );

			qp.subVectors( q, p );
			rp.subVectors( r, p );

			final area = v.crossVectors( qp, rp ).length / 2; // .length() represents the frobenius norm here
			weightedMean.add( v.copy( mean ).multiplyScalar( area ) );

			areaSum += area;

			cxx += ( 9.0 * mean.x * mean.x + p.x * p.x + q.x * q.x + r.x * r.x ) * ( area / 12 );
			cxy += ( 9.0 * mean.x * mean.y + p.x * p.y + q.x * q.y + r.x * r.y ) * ( area / 12 );
			cxz += ( 9.0 * mean.x * mean.z + p.x * p.z + q.x * q.z + r.x * r.z ) * ( area / 12 );
			cyy += ( 9.0 * mean.y * mean.y + p.y * p.y + q.y * q.y + r.y * r.y ) * ( area / 12 );
			cyz += ( 9.0 * mean.y * mean.z + p.y * p.z + q.y * q.z + r.y * r.z ) * ( area / 12 );
			czz += ( 9.0 * mean.z * mean.z + p.z * p.z + q.z * q.z + r.z * r.z ) * ( area / 12 );
		}

		weightedMean.divideScalar( areaSum );

		cxx /= areaSum;
		cxy /= areaSum;
		cxz /= areaSum;
		cyy /= areaSum;
		cyz /= areaSum;
		czz /= areaSum;

		cxx -= weightedMean.x * weightedMean.x;
		cxy -= weightedMean.x * weightedMean.y;
		cxz -= weightedMean.x * weightedMean.z;
		cyy -= weightedMean.y * weightedMean.y;
		cyz -= weightedMean.y * weightedMean.z;
		czz -= weightedMean.z * weightedMean.z;

		final covarianceMatrix = Matrix3();

		covarianceMatrix.elements[ 0 ] = cxx;
		covarianceMatrix.elements[ 1 ] = cxy;
		covarianceMatrix.elements[ 2 ] = cxz;
		covarianceMatrix.elements[ 3 ] = cxy;
		covarianceMatrix.elements[ 4 ] = cyy;
		covarianceMatrix.elements[ 5 ] = cyz;
		covarianceMatrix.elements[ 6 ] = cxz;
		covarianceMatrix.elements[ 7 ] = cyz;
		covarianceMatrix.elements[ 8 ] = czz;

		// 3. compute rotation, center and half sizes

		covarianceMatrix.eigenDecomposition( eigenDecomposition );

		final unitary = eigenDecomposition['unitary']!;

		final v1 = Vector3();
		final v2 = Vector3();
		final v3 = Vector3();

		unitary.extractBasis( v1, v2, v3 );

		double u1 = - double.infinity;
		double u2 = - double.infinity;
		double u3 = - double.infinity;
		double l1 = double.infinity;
		double l2 = double.infinity;
		double l3 = double.infinity;

		for ( int i = 0, l = points.length; i < l; i ++ ) {
			final p = points[ i ];

			u1 = math.max( v1.dot( p ), u1 );
			u2 = math.max( v2.dot( p ), u2 );
			u3 = math.max( v3.dot( p ), u3 );

			l1 = math.min( v1.dot( p ), l1 );
			l2 = math.min( v2.dot( p ), l2 );
			l3 = math.min( v3.dot( p ), l3 );
		}

		v1.multiplyScalar( 0.5 * ( l1 + u1 ) );
		v2.multiplyScalar( 0.5 * ( l2 + u2 ) );
		v3.multiplyScalar( 0.5 * ( l3 + u3 ) );

		// center
		center.add( v1 ).add( v2 ).add( v3 );

		halfSizes.x = u1 - l1;
		halfSizes.y = u2 - l2;
		halfSizes.z = u3 - l3;

		// halfSizes
		halfSizes.multiplyScalar( 0.5 );

		// rotation
		rotation.copy( unitary );

		return this;
	}

	/// Returns true if the given OBB is deep equal with this OBB.
	bool equals(OBB obb ) {
		return obb.center.equals( center ) &&
				obb.halfSizes.equals( halfSizes ) &&
				obb.rotation.equals( rotation );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'center': center.storage,
			'halfSizes': halfSizes.storage,
			'rotation': rotation.elements
		};
	}

	/// Restores this instance from the given JSON object.
	OBB fromJSON(Map<String,dynamic> json ) {
		center.fromArray( json['center'] );
		halfSizes.fromArray( json['halfSizes'] );
		rotation.fromArray( json['rotation'] );
		return this;
	}
}
