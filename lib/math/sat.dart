import 'half_edge.dart';
import 'polyhedron.dart';
import 'vector3.dart';

/// Implementation of the separating axis theorem (SAT). Used to detect intersections
/// between convex polyhedra. The code is based on the presentation {@link http://twvideo01.ubm-us.net/o1/vault/gdc2013/slides/822403Gregorius_Dirk_TheSeparatingAxisTest.pdf The Separating Axis Test between convex polyhedra}
/// by Dirk Gregorius (Valve Software) from GDC 2013.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SAT {
  final normal = Vector3();
  final oppositeNormal = Vector3();
  final directionA = Vector3();
  final directionB = Vector3();

  final c = Vector3();
  final d = Vector3();
  final v = Vector3();

	/// Returns true if the given convex polyhedra intersect. A polyhedron is just
	/// an array of {@link Polygon} objects.
	bool intersects(Polyhedron polyhedronA, Polyhedron polyhedronB ) {
		final resultAB = _checkFaceDirections( polyhedronA, polyhedronB );
		if ( resultAB ) return false;

		final resultBA = _checkFaceDirections( polyhedronB, polyhedronA );
		if ( resultBA ) return false;

		final resultEdges = _checkEdgeDirections( polyhedronA, polyhedronB );
		if ( resultEdges ) return false;

		// no separating axis found, the polyhedra must intersect
		return true;
	}

	// check possible separating axes from the first given polyhedron. the axes
	// are derived from the respective face normals
	bool _checkFaceDirections(Polyhedron polyhedronA, Polyhedron polyhedronB ) {
		final faces = polyhedronA.faces;

		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			final plane = face.plane;

			oppositeNormal.copy( plane.normal ).multiplyScalar( - 1 );

			final supportVertex = _getSupportVertex( polyhedronB, oppositeNormal );
			final distance = plane.distanceToPoint( supportVertex! );

			if ( distance > 0 ) return true; // separating axis found
		}

		return false;
	}

	// check with possible separating axes computed via the cross product between
	// all edge combinations of both polyhedra
	bool _checkEdgeDirections(Polyhedron polyhedronA, Polyhedron polyhedronB ) {
		final edgesA = polyhedronA.edges;
		final edgesB = polyhedronB.edges;

		for ( int i = 0, il = edgesA.length; i < il; i ++ ) {
			final edgeA = edgesA[ i ]!;
			for ( int j = 0, jl = edgesB.length; j < jl; j ++ ) {
				final edgeB = edgesB[ j ]!;
				edgeA.getDirection( directionA );
				edgeB.getDirection( directionB );

				// edge pruning: only consider edges if they build a face on the minkowski difference
				if ( _minkowskiFace( edgeA, directionA, edgeB, directionB ) ) {
					// compute axis
					final distance = _distanceBetweenEdges( edgeA, directionA, edgeB, directionB, polyhedronA );
					if ( distance > 0 ) return true; // separating axis found
				}
			}
		}

		return false;
	}

	// return the most extreme vertex into a given direction
	Vector3? _getSupportVertex(Polyhedron polyhedron, Vector3 direction ) {
		double maxProjection = - double.infinity;
		Vector3? supportVertex;

		// iterate over all polygons
		final vertices = polyhedron.vertices;

		for ( int i = 0, l = vertices.length; i < l; i ++ ) {
			final vertex = vertices[ i ];
			final projection = vertex.dot( direction );

			// check vertex to find the best support point
			if ( projection > maxProjection ) {
				maxProjection = projection;
				supportVertex = vertex;
			}
		}

		return supportVertex;
	}

	// returns true if the given edges build a face on the minkowski difference
	bool _minkowskiFace(HalfEdge edgeA, Vector3 directionA, HalfEdge edgeB, Vector3 directionB ) {
		// get face normals which define the vertices of the arcs on the gauss map
		final a = edgeA.polygon!.plane.normal;
		final b = edgeA.twin!.polygon!.plane.normal;
		c.copy( edgeB.polygon!.plane.normal );
		d.copy( edgeB.twin!.polygon!.plane.normal );

		// negate normals c and d to account for minkowski difference
		c.multiplyScalar( - 1 );
		d.multiplyScalar( - 1 );

		// compute triple products

		// it's not necessary to compute the cross product since edges of convex polyhedron
		// have same direction as the cross product between their adjacent face normals
		final cba = c.dot( directionA );
		final dba = d.dot( directionA );
		final adc = a.dot( directionB );
		final bdc = b.dot( directionB );

		// check signs of plane test
		return ( ( cba * dba ) ) < 0 && ( ( adc * bdc ) < 0 ) && ( ( cba * bdc ) > 0 );
	}

	// use gauss map to compute the distance between two edges
	double _distanceBetweenEdges(HalfEdge edgeA, Vector3 directionA, HalfEdge edgeB, Vector3 directionB, Polyhedron polyhedronA ) {
		// skip parallel edges
		if ( ( directionA.dot( directionB ) ).abs() == 1 ) return - double.infinity;

		// build plane through one edge
		normal.crossVectors( directionA, directionB ).normalize();

		// ensure normal points from polyhedron A to B
		if ( normal.dot( v.subVectors( edgeA.vertex, polyhedronA.centroid ) ) < 0 ) {
			normal.multiplyScalar( - 1 );
		}

		// compute the distance of any vertex on the other edge to that plane
		// no need to compute support points => O(1)
		return normal.dot( v.subVectors( edgeB.vertex, edgeA.vertex ) );
	}
}
