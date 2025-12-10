import '../core/console_logger/console_platform.dart';
import 'half_edge.dart';
import 'math_utils.dart';
import 'plane.dart';
import 'vector3.dart';

/// Class for representing a planar polygon with an arbitrary amount of edges.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class Polygon {
  final centroid = Vector3();
  HalfEdge? edge;
  bool active = true;
  final plane = Plane();

	/// Creates the polygon based on the given array of points in 3D space.
	/// The method assumes the contour (the sequence of points) is defined
	/// in CCW order.
	Polygon fromContour(List<Vector3> points ) {
		final edges = [];

		if ( points.length < 3 ) {
			yukaConsole.error( 'YUKA.Polygon: Unable to create polygon from contour. It needs at least three points.' );
			return this;
		}

		for ( int i = 0, l = points.length; i < l; i ++ ) {
			final edge = HalfEdge( points[ i ] );
			edges.add( edge );
		}

		// link edges
		for ( int i = 0, l = edges.length; i < l; i ++ ) {
			HalfEdge? current, prev, next;

			if ( i == 0 ) {
				current = edges[ i ];
				prev = edges[ l - 1 ];
			 	next = edges[ i + 1 ];
			} 
      else if ( i == ( l - 1 ) ) {
				current = edges[ i ];
			 	prev = edges[ i - 1 ];
				next = edges[ 0 ];
			} 
      else {
			 	current = edges[ i ];
				prev = edges[ i - 1 ];
				next = edges[ i + 1 ];
			}

			current?.prev = prev;
			current?.next = next;
			current?.polygon = this;
		}

		//
		edge = edges[ 0 ];

		//
		plane.fromCoplanarPoints( points[ 0 ], points[ 1 ], points[ 2 ] );

		return this;
	}

	/// Computes the centroid for this polygon.
	Polygon computeCentroid() {
		final centroid = this.centroid;
		HalfEdge? edge = this.edge;
		int count = 0;

		centroid.set( 0, 0, 0 );

		while ( edge != this.edge ) {
			centroid.add( edge!.vertex );
			count ++;
			edge = edge.next;
		}

		centroid.divideScalar( count.toDouble() );

		return this;
	}

	/// Returns true if the polygon contains the given point.
	bool contains(Vector3 point, [double epsilon = 1e-3 ]) {
		final plane = this.plane;
		HalfEdge? edge = this.edge;

		// convex test
		while ( edge != this.edge ) {
			final v1 = edge!.tail()!;
			final v2 = edge.head();

			if ( leftOn( v1, v2, point ) == false ) {
				return false;
			}

			edge = edge.next;
		}

		// ensure the given point lies within a defined tolerance range
		final distance = plane.distanceToPoint( point );

		if ( distance.abs() > epsilon ) {
			return false;
		}

		return true;
	}

	/// Returns true if the polygon is convex.
	bool convex( [bool ccw = true] ) {
		HalfEdge edge = this.edge!;

		while ( edge != this.edge ) {
			final v1 = edge.tail()!;
			final v2 = edge.head();
			final v3 = edge.next!.head();

			if ( ccw ) {
				if ( leftOn( v1, v2, v3 ) == false )	return false;
			} else {
				if ( leftOn( v3, v2, v1 ) == false ) return false;
			}

			edge = edge.next!;
		}

		return true;
	}

	/// Returns true if the polygon is coplanar.
	bool coplanar([double epsilon = 1e-3 ]) {
		final plane = this.plane;
		HalfEdge? edge = this.edge;

		while ( edge != this.edge ) {
			final distance = plane.distanceToPoint( edge!.vertex );

			if ( distance.abs() > epsilon ) {
				return false;
			}

			edge = edge.next;
		}

		return true;
	}

	/// Computes the signed distance from the given 3D vector to this polygon. The method
	/// uses the polygon's plane abstraction in order to compute this value.
	double distanceToPoint(Vector3 point ) {
		return plane.distanceToPoint( point );
	}

	/// Determines the contour (sequence of points) of this polygon and
	/// stores the result in the given array.
	List<Vector3> getContour(List<Vector3> result ) {
		HalfEdge? edge = this.edge;
		result.length = 0;

		while ( edge != this.edge ) {
			result.add( edge!.vertex );
			edge = edge.next;
		} 

		return result;
	}

  // from the book "Computational Geometry in C, Joseph O'Rourke"
  bool leftOn(Vector3 a, Vector3 b, Vector3 c ) {
    return MathUtils.area( a, b, c ) >= 0;
  }

  HalfEdge? getEdge(int i ){
    return null;
  }
}


