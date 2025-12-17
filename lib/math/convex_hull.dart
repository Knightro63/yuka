import 'package:yuka/math/math_utils.dart';

import '../core/console_logger/console_platform.dart';
import 'aabb.dart';
import 'half_edge.dart';
import 'line_segment.dart';
import 'plane.dart';
import 'polygon.dart';
import 'polyhedron.dart';
import 'sat.dart';
import 'vector3.dart';
import 'dart:math' as math;

final _line = LineSegment();
final _plane = Plane();
final _closestPoint = Vector3();
final _up = Vector3( 0, 1, 0 );
final _sat = SAT();
Polyhedron? _polyhedronAABB;

/// Class representing a convex hull. This is an implementation of the Quickhull algorithm
/// based on the presentation {@link http://media.steampowered.com/apps/valve/2014/DirkGregorius_ImplementingQuickHull.pdf Implementing QuickHull}
/// by Dirk Gregorius (Valve Software) from GDC 2014. The algorithm has an average runtime
/// complexity of O(nlog(n)), whereas in the worst case it takes O(n²).
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class ConvexHull extends Polyhedron {
  bool mergeFaces = true;
  double _tolerance = - 1;
  final _assigned = VertexList();
  final _unassigned = VertexList();
  final List<Vertex> _vertices = [];

	ConvexHull():super();

	/// Returns true if the given point is inside this convex hull.
	bool containsPoint(Vector3 point ) {
		final faces = this.faces;

		// use the internal plane abstraction of each face in order to test
		// on what half space the point lies
		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			// if the signed distance is greater than the tolerance value, the point
			// is outside and we can stop processing
			if ( faces[ i ].distanceToPoint( point ) > _tolerance ) return false;
		}

		return true;
	}

	/// Returns true if this convex hull intersects with the given AABB.
	bool intersectsAABB(AABB aabb ) {
		if ( _polyhedronAABB == null ) {
			// lazily create the (proxy) polyhedron if necessary
			_polyhedronAABB = Polyhedron().fromAABB( aabb );
		} 
    else {
			// otherwise just ensure up-to-date vertex data.
			// the topology of the polyhedron is equal for all AABBs
			final min = aabb.min;
			final max = aabb.max;
			final vertices = _polyhedronAABB!.vertices;

			vertices[ 0 ].set( max.x, max.y, max.z );
			vertices[ 1 ].set( max.x, max.y, min.z );
			vertices[ 2 ].set( max.x, min.y, max.z );
			vertices[ 3 ].set( max.x, min.y, min.z );
			vertices[ 4 ].set( min.x, max.y, max.z );
			vertices[ 5 ].set( min.x, max.y, min.z );
			vertices[ 6 ].set( min.x, min.y, max.z );
			vertices[ 7 ].set( min.x, min.y, min.z );

			aabb.getCenter( _polyhedronAABB!.centroid );
		}

		return _sat.intersects( this, _polyhedronAABB! );
	}

  /// Returns true if this convex hull intersects with the given one.
	bool intersectsConvexHull( ConvexHull convexHull ) {
		return _sat.intersects( this, convexHull );
	}

	/// Computes a convex hull that encloses the given set of points. The computation requires
	/// at least four points.
	ConvexHull fromPoints(List<Vector3> points ) {
		if ( points.length < 4 ) {
			yukaConsole.error( 'YUKA.ConvexHull: The given points array needs at least four points.' );
			return this;
		}

		// wrap all points into the internal vertex data structure
		for ( int i = 0, l = points.length; i < l; i ++ ) {
			_vertices.add( Vertex( points[ i ] ) );
		}

		// generate the convex hull
		_generate();
		return this;
	}

	// private API
	// adds a single face to the convex hull by connecting it with the respective horizon edge
	HalfEdge? _addAdjoiningFace( Vertex vertex, HalfEdge horizonEdge ) {
		// all the half edges are created in ccw order thus the face is always pointing outside the hull
		final face = Face( vertex.point, horizonEdge.prev?.vertex, horizonEdge.vertex );
		faces.add( face );
		// join face.getEdge( - 1 ) with the horizon's opposite edge face.getEdge( - 1 ) = face.getEdge( 2 )
		face.getEdge( - 1 )?.linkOpponent( horizonEdge.twin );
		return face.getEdge( 0 ); // the half edge whose vertex is the given one
	}

	// adds faces by connecting the horizon with the point of the convex hull
	List<Face> _addNewFaces( Vertex vertex, List<HalfEdge> horizon ) {
		final newFaces = <Face>[];
		HalfEdge? firstSideEdge;
		HalfEdge? previousSideEdge;

		for ( int i = 0, l = horizon.length; i < l; i ++ ) {
			// returns the right side edge
			HalfEdge? sideEdge = _addAdjoiningFace( vertex, horizon[ i ] );

			if ( firstSideEdge == null ) {
				firstSideEdge = sideEdge;
			} 
      else {
				// joins face.getEdge( 1 ) with previousFace.getEdge( 0 )
				sideEdge?.next?.linkOpponent( previousSideEdge );
			}

			newFaces.add( sideEdge?.polygon as Face );
			previousSideEdge = sideEdge;
		}

		// perform final join of faces
		firstSideEdge?.next?.linkOpponent( previousSideEdge );
		return newFaces;
	}

	// assigns a single vertex to the given face. that means this face can "see"
	// the vertex and its distance to the vertex is greater than all other faces
	ConvexHull _addVertexToFace(Vertex? vertex, Face face ) {
		vertex?.face = face;
		if ( face.outside == null ) {
			_assigned.append( vertex! );
			face.outside = vertex;
		} 
    else {
			_assigned.insertAfter( face.outside, vertex! );
		}

		return this;
	}

	// the base iteration of the algorithm. adds a vertex to the convex hull by
	// connecting faces from the horizon with it.
	ConvexHull _addVertexToHull(Vertex vertex ) {
		final horizon = <HalfEdge>[];
		_unassigned.clear();
		_computeHorizon( vertex.point, null, vertex.face, horizon );
		final newFaces = _addNewFaces( vertex, horizon );

		// reassign 'unassigned' vertices to the faces
		_resolveUnassignedPoints( newFaces );
		return this;
	}

	// frees memory by resetting internal data structures
	ConvexHull _reset() {
		_vertices.clear();
		_assigned.clear();
		_unassigned.clear();
		return this;
	}

	// computes the initial hull of the algorithm. it's a tetrahedron created
	// with the extreme vertices of the given set of points
	ConvexHull _computeInitialHull() {
		late Vertex v0, v1, v2, v3;

		final vertices = _vertices;
		final extremes = _computeExtremes();
		final min = extremes['min'] as Map<String,Vertex?>;
		final max = extremes['max'] as Map<String,Vertex?>;

		// 1. Find the two points 'p0' and 'p1' with the greatest 1d separation
		// (max.x - min.x)
		// (max.y - min.y)
		// (max.z - min.z)

		// check x
		double distance, maxDistance;

		maxDistance = max['x']!.point.x - min['x']!.point.x;
		v0 = min['x']!;
		v1 = max['x']!;

		// check y
		distance = max['y']!.point.y - min['y']!.point.y;

		if ( distance > maxDistance ) {
			v0 = min['y']!;
			v1 = max['y']!;

			maxDistance = distance;
		}

		// check z
		distance = max['z']!.point.z - min['z']!.point.z;

		if ( distance > maxDistance ) {
			v0 = min['z']!;
			v1 = max['z']!;
		}

		// 2. The next vertex 'v2' is the one farthest to the line formed by 'v0' and 'v1'
		maxDistance = - double.infinity;
		_line.set( v0.point, v1.point );

		for ( int i = 0, l = vertices.length; i < l; i ++ ) {
			final vertex = vertices[ i ];

			if ( vertex != v0 && vertex != v1 ) {
				_line.closestPointToPoint( vertex.point, true, _closestPoint );
				distance = _closestPoint.squaredDistanceTo( vertex.point );

				if ( distance > maxDistance ) {
					maxDistance = distance;
					v2 = vertex;
				}
			}
		}

		// 3. The next vertex 'v3' is the one farthest to the plane 'v0', 'v1', 'v2'

		maxDistance = - double.infinity;
		_plane.fromCoplanarPoints( v0.point, v1.point, v2.point );

		for ( int i = 0, l = vertices.length; i < l; i ++ ) {
			final vertex = vertices[ i ];

			if ( vertex != v0 && vertex != v1 && vertex != v2 ) {
				distance = _plane.distanceToPoint( vertex.point ).abs();
				if ( distance > maxDistance ) {
					maxDistance = distance;
					v3 = vertex;
				}
			}
		}

		// handle case where all points lie in one plane
		if ( _plane.distanceToPoint( v3.point ) == 0 ) {
			throw 'ERROR: YUKA.ConvexHull: All extreme points lie in a single plane. Unable to compute convex hull.';
		}

		// build initial tetrahedron

		final faces = this.faces;

		if ( _plane.distanceToPoint( v3.point ) < 0 ) {

			// the face is not able to see the point so 'plane.normal' is pointing outside the tetrahedron

			faces.addAll([
				Face( v0.point, v1.point, v2.point ),
				Face( v3.point, v1.point, v0.point ),
				Face( v3.point, v2.point, v1.point ),
				Face( v3.point, v0.point, v2.point )
			]);

			// set the twin edge

			// join face[ i ] i > 0, with the first face
			faces[ 1 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 1 ) );
			faces[ 2 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 2 ) );
			faces[ 3 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 0 ) );

			// join face[ i ] with face[ i + 1 ], 1 <= i <= 3
			faces[ 1 ].getEdge( 1 )?.linkOpponent( faces[ 2 ].getEdge( 0 ) );
			faces[ 2 ].getEdge( 1 )?.linkOpponent( faces[ 3 ].getEdge( 0 ) );
			faces[ 3 ].getEdge( 1 )?.linkOpponent( faces[ 1 ].getEdge( 0 ) );

		}
    else {
			// the face is able to see the point so 'plane.normal' is pointing inside the tetrahedron
			faces.addAll([
				Face( v0.point, v2.point, v1.point ),
				Face( v3.point, v0.point, v1.point ),
				Face( v3.point, v1.point, v2.point ),
				Face( v3.point, v2.point, v0.point )
			]);

			// set the twin edge
			// join face[ i ] i > 0, with the first face
			faces[ 1 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 0 ) );
			faces[ 2 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 2 ) );
			faces[ 3 ].getEdge( 2 )?.linkOpponent( faces[ 0 ].getEdge( 1 ) );

			// join face[ i ] with face[ i + 1 ], 1 <= i <= 3
			faces[ 1 ].getEdge( 0 )?.linkOpponent( faces[ 2 ].getEdge( 1 ) );
			faces[ 2 ].getEdge( 0 )?.linkOpponent( faces[ 3 ].getEdge( 1 ) );
			faces[ 3 ].getEdge( 0 )?.linkOpponent( faces[ 1 ].getEdge( 1 ) );
		}

		// initial assignment of vertices to the faces of the tetrahedron
		for ( int i = 0, l = vertices.length; i < l; i ++ ) {
			final vertex = vertices[ i ];

			if ( vertex != v0 && vertex != v1 && vertex != v2 && vertex != v3 ) {
				maxDistance = _tolerance;
				Face? maxFace;

				for ( int j = 0; j < 4; j ++ ) {
					distance = faces[ j ].distanceToPoint( vertex.point );
					if ( distance > maxDistance ) {
						maxDistance = distance;
						maxFace = faces[ j ] as Face?;
					}
				}
				if ( maxFace != null ) {
					_addVertexToFace( vertex, maxFace );
				}
			}
		}

		return this;
	}

	// computes the extreme vertices of used to compute the initial convex hull
	Map<String,dynamic> _computeExtremes() {
		final min = Vector3( double.infinity, double.infinity, double.infinity );
		final max = Vector3( - double.infinity, - double.infinity, - double.infinity );

		final Map<String,Vertex?> minVertices = { 'x': null, 'y': null, 'z': null };
		final Map<String,Vertex?> maxVertices = { 'x': null, 'y': null, 'z': null };

		// compute the min/max points on all six directions
		for ( int i = 0, l = _vertices.length; i < l; i ++ ) {

			final vertex = _vertices[ i ];
			final point = vertex.point;

			// update the min coordinates

			if ( point.x < min.x ) {
				min.x = point.x;
				minVertices['x'] = vertex;
			}

			if ( point.y < min.y ) {
				min.y = point.y;
				minVertices['y'] = vertex;
			}

			if ( point.z < min.z ) {
				min.z = point.z;
				minVertices['z'] = vertex;
			}

			// update the max coordinates
			if ( point.x > max.x ) {
				max.x = point.x;
				maxVertices['x'] = vertex;
			}

			if ( point.y > max.y ) {
				max.y = point.y;
				maxVertices['y'] = vertex;
			}

			if ( point.z > max.z ) {
				max.z = point.z;
				maxVertices['z'] = vertex;
			}
		}

		// use min/max vectors to compute an optimal epsilon
	  _tolerance = 3 * MathUtils.epsilon * (
			math.max( min.x.abs(), max.x.abs()) +
			math.max( min.y.abs(), max.y.abs()) +
			math.max( min.z.abs(), max.z.abs())
		);

		return { 'min': minVertices, 'max': maxVertices };
	}

	// computes the horizon, an array of edges enclosing the faces that are able
	// to see the vertex
	ConvexHull _computeHorizon(Vector3 eyePoint, HalfEdge? crossEdge, Face? face, List<HalfEdge>horizon ) {
		if ( face?.outside != null) {
			final startVertex = face!.outside;
			// remove all vertices from the given face
			_removeAllVerticesFromFace( face );
			// mark the face vertices to be reassigned to other faces
			_unassigned.appendChain( startVertex );
		}

		face?.active = false;

		HalfEdge? edge;

		if ( crossEdge == null ) {
			edge = crossEdge = face?.getEdge( 0 );
		} 
    else {
			// start from the next edge since 'crossEdge' was already analyzed
			// (actually 'crossEdge.twin' was the edge who called this method recursively)
			edge = crossEdge.next;
		}

		do{
			HalfEdge twinEdge = edge!.twin!;
			Polygon oppositeFace = twinEdge.polygon!;

			if ( oppositeFace.active == true) {
				if (oppositeFace.distanceToPoint( eyePoint ) > _tolerance ) {
					// the opposite face can see the vertex, so proceed with next edge
				  _computeHorizon( eyePoint, twinEdge, oppositeFace as Face, horizon );
				} 
        else {
					// the opposite face can't see the vertex, so this edge is part of the horizon
					horizon.add( edge );
				}
			}
			edge = edge.next;
		} while ( edge != crossEdge );

		return this;
	}

	// this method controls the basic flow of the algorithm
	ConvexHull _generate() {
		faces.clear();
		_computeInitialHull();
		Vertex? vertex = _nextVertexToAdd();

		while ( vertex != null ) {
			_addVertexToHull( vertex );
      vertex = _nextVertexToAdd();
		}

		_updateFaces();
		_postprocessHull();
		_reset();

		return this;
	}

	// final tasks after computing the hull
	ConvexHull _postprocessHull() {
		final faces = this.faces;
		final edges = this.edges;

		if ( mergeFaces == true ) {

			// merges faces if the result is still convex and coplanar

			final Map<String,dynamic> cache = {
				'leftPrev': null,
				'leftNext': null,
				'rightPrev': null,
				'rightNext': null
			};

			// gather unique edges and temporarily sort them
			computeUniqueEdges();

			edges.sort( ( a, b ){ return (b!.length() - a!.length()).toInt();});

			// process edges from longest to shortest
			for ( int i = 0, l = edges.length; i < l; i ++ ) {
				final entry = edges[ i ]!;
				if ( _mergePossible( entry ) == false ) continue;
				HalfEdge candidate = entry;

				// cache current references for possible restore
				cache['prev'] = candidate.prev;
				cache['next'] = candidate.next;
				cache['prevTwin'] = candidate.twin?.prev;
				cache['nextTwin'] = candidate.twin?.next;

				// temporarily change the first polygon in order to represent both polygons
				candidate.prev?.next = candidate.twin?.next;
				candidate.next?.prev = candidate.twin?.prev;
				candidate.twin?.prev?.next = candidate.next;
				candidate.twin?.next?.prev = candidate.prev;

				final polygon = candidate.polygon;
				polygon?.edge = candidate.prev;

				final ccw = (polygon?.plane.normal.dot( _up ) ?? 0) >= 0;

				if ( polygon?.convex( ccw ) == true && polygon?.coplanar( _tolerance ) == true ) {
					// correct polygon reference of all edges
					HalfEdge? edge = polygon?.edge;

					do{
						edge?.polygon = polygon;
						edge = edge?.next;
					} while ( edge != polygon?.edge );

					// delete obsolete polygon
					final index = faces.indexOf( entry.twin!.polygon! );
					faces.removeAt( index );
				} 
        else {
					// restore
					cache['prev']?.next = candidate;
					cache['next']?.prev = candidate;
					cache['prevTwin']?.next = candidate.twin;
					cache['nextTwin']?.prev = candidate.twin;
					polygon?.edge = candidate;
				}
			}

			// recompute centroid of faces
			for ( int i = 0, l = faces.length; i < l; i ++ ) {
				faces[ i ].computeCentroid();
			}
		}

		// compute centroid of convex hull and the final edge and vertex list
		computeCentroid();
		computeUniqueEdges();
		computeUniqueVertices();

		return this;
	}

	// checks if the given edge can be used to merge convex regions
	bool _mergePossible(HalfEdge edge ) {
		final polygon = edge.polygon;
		HalfEdge? currentEdge = edge.twin;

		do{
			// we can only use an edge to merge two regions if the adjacent region does not have any edges
			// apart from edge.twin already connected to the region.
			if ( currentEdge != edge.twin && currentEdge?.twin?.polygon == polygon ) return false;
			currentEdge = currentEdge?.next;
		} while ( edge.twin != currentEdge );

		return true;
	}

	// determines the next vertex that should added to the convex hull
	Vertex? _nextVertexToAdd() {
		Vertex? nextVertex;

		// if the 'assigned' list of vertices is empty, no vertices are left
		if ( _assigned.empty() == false ) {
			double maxDistance = 0;

			// grap the first available vertex and save the respective face
			Vertex? vertex = _assigned.first;
			final face = vertex?.face;

			// now calculate the farthest vertex that face can see
			do{
				final distance = face?.distanceToPoint( vertex!.point ) ?? 0;

				if ( distance > maxDistance ) {
					maxDistance = distance;
					nextVertex = vertex;
				}

				vertex = vertex?.next;
			} while ( vertex != null && vertex.face == face );
		}

		return nextVertex;
	}

	// updates the faces array after the computation of the convex hull
	// it ensures only visible faces are in the result set
	ConvexHull _updateFaces() {
		final faces = this.faces;
		final activeFaces = <Polygon>[];

		for ( int i = 0, l = faces.length; i < l; i ++ ) {
			final face = faces[ i ];
			// only respect visible but not deleted or merged faces
			if ( face.active ) {
				activeFaces.add( face );
			}
		}

		this.faces.clear();
		this.faces.addAll( activeFaces );

		return this;
	}

	// removes all vertices from the given face. necessary when deleting a face
	// which is necessary when the hull is going to be expanded
	ConvexHull _removeAllVerticesFromFace(Face face ) {
		if ( face.outside != null ) {
			// reference to the first and last vertex of this face
			final firstVertex = face.outside;
			firstVertex?.face = null;

			Vertex? lastVertex = face.outside;

			while ( lastVertex?.next != null && lastVertex?.next?.face == face ) {
				lastVertex = lastVertex?.next;
				lastVertex?.face = null;
			}

			face.outside = null;
			_assigned.removeChain( firstVertex!, lastVertex! );
		}

		return this;
	}

	// /// removes a single vertex from the given face
	// ConvexHull _removeVertexFromFace(Vertex vertex, Face face ) {
	// 	vertex.face = null;

	// 	if ( vertex == face.outside ) {
	// 		// fix face.outside link
	// 		if ( vertex.next != null && vertex.next?.face == face ) {
	// 			// face has at least 2 outside vertices, move the 'outside' reference
	// 			face.outside = vertex.next;
	// 		} 
  //     else {
	// 			// vertex was the only outside vertex that face had
	// 			face.outside = null;
	// 		}
	// 	}

	// 	_assigned.remove( vertex );

	// 	return this;
	// }

	// ensure that all unassigned points are reassigned to other faces of the
	// current convex hull. this method is always executed after the hull was
	// expanded
	ConvexHull _resolveUnassignedPoints(List<Face> newFaces ) {
		if ( _unassigned.empty() == false ) {
			Vertex? vertex = _unassigned.first;

			do{
				// buffer 'next' reference since addVertexToFace() can change it
				Vertex? nextVertex = vertex?.next;
				double maxDistance = _tolerance;
				Face? maxFace;

				for ( int i = 0, l = newFaces.length; i < l; i ++ ) {
					final face = newFaces[ i ];

					if ( face.active ) {
						final distance = face.distanceToPoint( vertex!.point );

						if ( distance > maxDistance ) {
							maxDistance = distance;
							maxFace = face;
						}
					}
				}

				if ( maxFace != null ) {
					_addVertexToFace( vertex, maxFace );
				}

				vertex = nextVertex;
			} while ( vertex != null );
		}

		return this;
	}
}

class Face extends Polygon {
  late final Vector3 a;
  late final Vector3 b;
  late final Vector3 c;

  Vertex? outside;

	Face([Vector3? a, Vector3? b, Vector3? c]):super() {
    this.a = a ?? Vector3();
    this.b = b ?? Vector3();
    this.c = c ?? Vector3();

		fromContour( [ this.a, this.b, this.c ] );
	  computeCentroid();
    active = true;
	}

  @override
	HalfEdge? getEdge(int i ) {
		HalfEdge? edge = this.edge;

		while ( i > 0 ) {
			edge = edge?.next;
			i --;
		}

		while ( i < 0 ) {
			edge = edge?.prev;
			i ++;
		}

		return edge;
	}
}

// special data structures for the quick hull implementation

class Vertex {
  late final Vector3 point;

  Vertex? prev;
  Vertex? next;
  Face? face; // the face that is able to see this vertex

	Vertex([Vector3? point ]) {
		this.point = point ?? Vector3();
	}
}

class VertexList {
	Vertex? head;
	Vertex? tail;

	Vertex? get first => head;
	Vertex? get last => tail;

	VertexList clear() {
		head = tail = null;
		return this;
	}

	VertexList insertAfter(Vertex? target, Vertex vertex ) {
		vertex.prev = target;
		vertex.next = target?.next;

		if (vertex.next == null) {
			tail = vertex;
		} 
    else {
			vertex.next?.prev = vertex;
		}

		target?.next = vertex;
		return this;
	}

	VertexList append(Vertex vertex ) {
		if (head == null ) {
			head = vertex;
		} 
    else {
			tail?.next = vertex;
		}

		vertex.prev = tail;
		vertex.next = null; // the tail has no subsequent vertex
		tail = vertex;

		return this;
	}

	VertexList appendChain(Vertex? vertex ) {
		if ( head == null ) {
			head = vertex;
		} 
    else {
			tail?.next = vertex;
		}

		vertex?.prev = tail;

		while ( vertex?.next != null ) {
			vertex = vertex?.next;
		}

		tail = vertex;

		return this;
	}

	VertexList remove(Vertex vertex ) {
		if ( vertex.prev == null ) {
			head = vertex.next;
		} 
    else {
			vertex.prev?.next = vertex.next;
		}

		if ( vertex.next == null ) {
			tail = vertex.prev;
		} 
    else {
			vertex.next?.prev = vertex.prev;
		}

		vertex.prev = null;
		vertex.next = null;

		return this;
	}

	VertexList removeChain(Vertex a, Vertex b ) {
		if ( a.prev == null ) {
			head = b.next;
		} else {
			a.prev?.next = b.next;
		}

		if ( b.next == null ) {
			tail = a.prev;
		} 
    else {
			b.next?.prev = a.prev;
		}

		a.prev = null;
		b.next = null;

		return this;
	}

	bool empty() {
		return head == null;
	}
}