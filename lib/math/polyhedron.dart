import "aabb.dart";
import "half_edge.dart";
import "polygon.dart";
import "vector3.dart";

/// Base class for polyhedra. It is primarily designed for the internal usage in Yuka.
/// Objects of this class are always build up from faces. The edges, vertices and
/// the polyhedron's centroid have to be derived from a valid face definition with the
/// respective methods.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Polyhedron {
  List<Polygon> faces = [];
  List<HalfEdge?> edges = [];
  List<Vector3> vertices = [];
  Vector3 centroid = Vector3();

	/// Computes the centroid of this polyhedron. Assumes its faces
	/// have valid centroids.
	Polyhedron computeCentroid() {
		final centroid = this.centroid;
		List<Polygon> faces = this.faces;

		centroid.set( 0, 0, 0 );

		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			centroid.add( face.centroid );
		}

		centroid.divideScalar( faces.length.toDouble() );

		return this;
	}

	/// Computes unique vertices of this polyhedron. Assumes {@link Polyhedron#faces}
	/// is properly set.
	Polyhedron computeUniqueVertices() {
		final faces = this.faces;
		final vertices = this.vertices;

		vertices.clear();

		final uniqueVertices = <Vector3>[];

		// iterate over all faces
		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			HalfEdge? edge = face.edge;

			// process all edges of a faces
			while ( edge != face.edge ) {
				// add vertex to set (assuming half edges share unique vertices)
				uniqueVertices.add( edge!.vertex );
				edge = edge.next;
			}
		}

		vertices.addAll( uniqueVertices );

		return this;
	}

	/// Computes unique edges of this polyhedron. Assumes {@link Polyhedron#faces}
	/// is properly set.
	Polyhedron computeUniqueEdges() {
		final faces = this.faces;
		final edges = this.edges;

		edges.clear();

		// iterate over all faces
		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			HalfEdge? edge = face.edge;

			// process all edges of a faces
			while ( edge != face.edge ) {
				// only add the edge if the twin was not added before
				if ( edges.contains( edge!.twin ) == false ) {
					edges.add( edge );
				}

				edge = edge.next;
			}
		}

		return this;
	}

	/// Configures this polyhedron so it does represent the given AABB.
	Polyhedron fromAABB(AABB aabb ) {
		faces.clear();
		this.vertices.clear();

		final min = aabb.min;
		final max = aabb.max;

		final vertices = [
			Vector3( max.x, max.y, max.z ),
			Vector3( max.x, max.y, min.z ),
			Vector3( max.x, min.y, max.z ),
			Vector3( max.x, min.y, min.z ),
			Vector3( min.x, max.y, max.z ),
			Vector3( min.x, max.y, min.z ),
			Vector3( min.x, min.y, max.z ),
			Vector3( min.x, min.y, min.z )
		];

		this.vertices.addAll( vertices );

		final sideTop = Polygon().fromContour( [
			vertices[ 4 ],
			vertices[ 0 ],
			vertices[ 1 ],
			vertices[ 5 ]
		] );

		final sideRight = Polygon().fromContour( [
			vertices[ 2 ],
			vertices[ 3 ],
			vertices[ 1 ],
			vertices[ 0 ]
		] );

		final sideFront = Polygon().fromContour( [
			vertices[ 6 ],
			vertices[ 2 ],
			vertices[ 0 ],
			vertices[ 4 ]
		] );

		final sideBack = Polygon().fromContour( [
			vertices[ 3 ],
			vertices[ 7 ],
			vertices[ 5 ],
			vertices[ 1 ]
		] );

		final sideBottom = Polygon().fromContour( [
			vertices[ 3 ],
			vertices[ 2 ],
			vertices[ 6 ],
			vertices[ 7 ]
		] );

		final sideLeft = Polygon().fromContour( [
			vertices[ 7 ],
			vertices[ 6 ],
			vertices[ 4 ],
			vertices[ 5 ]
		] );

		// link edges

		sideTop.edge?.linkOpponent( sideLeft.edge?.prev );
		sideTop.edge?.next?.linkOpponent( sideFront.edge?.prev );
		sideTop.edge?.next?.next?.linkOpponent( sideRight.edge?.prev );
		sideTop.edge?.prev?.linkOpponent( sideBack.edge?.prev );

		sideBottom.edge?.linkOpponent( sideBack.edge?.next );
		sideBottom.edge?.next?.linkOpponent( sideRight.edge?.next );
		sideBottom.edge?.next?.next?.linkOpponent( sideFront.edge?.next );
		sideBottom.edge?.prev?.linkOpponent( sideLeft.edge?.next );

		sideLeft.edge?.linkOpponent( sideBack.edge?.next?.next );
		sideBack.edge?.linkOpponent( sideRight.edge?.next?.next );
		sideRight.edge?.linkOpponent( sideFront.edge?.next?.next );
		sideFront.edge?.linkOpponent( sideLeft.edge?.next?.next );

		//
		faces.addAll( [sideTop, sideRight, sideFront, sideBack, sideBottom, sideLeft] );

		// compute centroids
		sideTop.computeCentroid();
		sideRight.computeCentroid();
		sideFront.computeCentroid();
		sideBack.computeCentroid();
		sideBottom.computeCentroid();
		sideLeft.computeCentroid();

		aabb.getCenter( centroid );

		//
		computeUniqueEdges();

		return this;
	}
}
