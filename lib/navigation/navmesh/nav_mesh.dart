import 'dart:math' as math;
import '../../graph/core/graph.dart';
import '../../graph/search/a_star.dart';
import '../../math/half_edge.dart';
import '../../math/line_segment.dart';
import '../../math/polygon.dart';
import '../../math/vector3.dart';
import '../../partitioning/cell_space_partitioning.dart';
import '../core/nav_edge.dart';
import '../core/nav_node.dart';
import 'corridor.dart';

/// Implementation of a navigation mesh. A navigation mesh is a network of convex polygons
/// which define the walkable areas of a game environment. A convex polygon allows unobstructed travel
/// from any point in the polygon to any other. This is useful because it enables the navigation mesh
/// to be represented using a graph where each node represents a convex polygon and their respective edges
/// represent the neighborly relations to other polygons. More compact navigation graphs lead
/// to faster graph search execution.
///
/// This particular implementation is able to merge convex polygons into bigger ones as long
/// as they keep their convexity and coplanarity. The performance of the path finding process and convex region tests
/// for complex navigation meshes can be improved by using a spatial index like {@link CellSpacePartitioning}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class NavMesh {
  final pointOnLineSegment = Vector3();
  final edgeDirection = Vector3();
  final movementDirection = Vector3();
  final newPosition = Vector3();
  final lineSegment = LineSegment();
  final edges = <HalfEdge>[];
  final Map<String,dynamic> closestBorderEdge = {
    'edge': null,
    'closestPoint': Vector3()
  };

  Graph graph = Graph();
  List<Polygon> regions = [];
  CellSpacePartitioning? spatialIndex;
  double epsilonCoplanarTest = 1e-3;
  double epsilonContainsTest = 1;
  bool mergeConvexRegions = true;
  final List<HalfEdge> _borderEdges = [];

	/// Constructs a navigation mesh.
	NavMesh() {
		graph.digraph = true;	
  }

	/// Creates the navigation mesh from an array of convex polygons.
	NavMesh fromPolygons(List<Polygon> polygons ) {
		clear();

		//
		final initialEdgeList = [];
		final sortedEdgeList = [];

		// setup list with all edges
		for ( int i = 0, l = polygons.length; i < l; i ++ ) {
			final polygon = polygons[ i ];
			HalfEdge? edge = polygon.edge;

			while ( edge != polygon.edge ) {
				initialEdgeList.add( edge );
				edge = edge?.next;
			}

			//
			regions.add( polygon );
		}

		// setup twin references and sorted list of edges
		for ( int i = 0, il = initialEdgeList.length; i < il; i ++ ) {

			HalfEdge edge0 = initialEdgeList[ i ];

			if ( edge0.twin != null ) continue;

			for ( int j = i + 1, jl = initialEdgeList.length; j < jl; j ++ ) {
				HalfEdge edge1 = initialEdgeList[ j ];

				if ( edge0.tail()!.equals( edge1.head() ) && edge0.head().equals( edge1.tail()! ) ) {
					// opponent edge found, set twin references
					edge0.linkOpponent( edge1 );

					// add edge to list
					final cost = edge0.squaredLength;
					sortedEdgeList.add( {
						'cost': cost,
						'edge': edge0
					} );

					// there can only be a single twin
					break;
				}
			}
		}

		sortedEdgeList.sort( descending );

		// half-edge data structure is now complete, begin build of convex regions
		_buildRegions( sortedEdgeList );

		// now build the navigation graph
		_buildGraph();

		return this;
	}

	/// Clears the internal state of this navigation mesh.
	NavMesh clear() {
		graph.clear();
		regions.length = 0;
		spatialIndex = null;

		return this;
	}

	/// Returns the closest convex region for the given point in 3D space.
	Polygon? getClosestRegion(Vector3 point ) {
		final regions = this.regions;
		Polygon? closesRegion;
		double minDistance = double.infinity;

		for ( int i = 0, l = regions.length; i < l; i ++ ) {
			final region = regions[ i ];
			final distance = point.squaredDistanceTo( region.centroid );

			if ( distance < minDistance ) {
				minDistance = distance;
				closesRegion = region;
			}
		}

		return closesRegion;
	}

	/// Returns at random a convex region from the navigation mesh.
	Polygon getRandomRegion() {
		final regions = this.regions;
		int index = ( math.Random().nextDouble() * ( regions.length ) ).floor();
		if ( index == regions.length ) index = regions.length - 1;
		return regions[ index ];
	}

	/// Returns the region that contains the given point. The computational overhead
	/// of this method for complex navigation meshes can be reduced by using a spatial index.
	/// If no convex region contains the point, *null* is returned.
	Polygon? getRegionForPoint(Vector3 point, [double epsilon = 1e-3] ) {
		List<Polygon> regions;

		if ( spatialIndex != null ) {
			final index = spatialIndex!.getIndexForPosition( point );
			regions = spatialIndex!.cells[ index ].entries as List<Polygon>;
		} 
		else {
			regions = this.regions;
		}

		//

		for ( int i = 0, l = regions.length; i < l; i ++ ) {
			final region = regions[ i ];
			if ( region.contains( point, epsilon ) == true ) {
				return region;
			}
		}

		return null;
	}

	/// Returns the node index for the given region. The index represents
	/// the navigation node of a region in the navigation graph.
	int getNodeIndex(Polygon region ) {
		return regions.indexOf( region );
	}

	/// Returns the shortest path that leads from the given start position to the end position.
	/// The computational overhead of this method for complex navigation meshes can greatly
	/// reduced by using a spatial index.
	List<Vector3> findPath(Vector3 from, Vector3 to ) {
		final graph = this.graph;
		final path = <Vector3>[];

		Polygon? fromRegion = getRegionForPoint( from, epsilonContainsTest );
		Polygon? toRegion = getRegionForPoint( to, epsilonContainsTest );

		if ( fromRegion == null || toRegion == null ) {
			// if source or target are outside the navmesh, choose the nearest convex region
			fromRegion ??= getClosestRegion( from );
			toRegion ??= getClosestRegion( to );
		}

		// check if both convex region are identical

		if ( fromRegion == toRegion ) {
			// no search necessary, directly create the path
			path.add( Vector3().copy( from ) );
			path.add( Vector3().copy( to ) );
			return path;
		} 
		else {
			// source and target are not in same region, perform search
			final source = getNodeIndex( fromRegion! );
			final target = getNodeIndex( toRegion! );

			final astar = AStar( graph, source, target );
			astar.search();

			if ( astar.found == true ) {

				final polygonPath = astar.getPath();

				final corridor = Corridor();
				corridor.push( from, from );

				// push sequence of portal edges to corridor

				final Map<String,Vector3?> portalEdge = { 'left': null, 'right': null };

				for ( int i = 0, l = ( polygonPath.length - 1 ); i < l; i ++ ) {
					final region = regions[ polygonPath[ i ] ];
					final nextRegion = regions[ polygonPath[ i + 1 ] ];

					_getPortalEdge( region, nextRegion, portalEdge );
					corridor.push( portalEdge['left']!, portalEdge['right']! );
				}

				corridor.push( to, to );
				path.addAll( corridor.generate() );
			}

			return path;
		}
	}

	/// This method can be used to restrict the movement of a game entity on the navigation mesh.
	/// Instead of preventing any form of translation when a game entity hits a border edge, the
	/// movement is clamped along the contour of the navigation mesh. The computational overhead
	/// of this method for complex navigation meshes can be reduced by using a spatial index.
	Polygon clampMovement(Polygon? currentRegion, Vector3 startPosition, Vector3 endPosition, Vector3 clampPosition ) {
		Polygon? newRegion = getRegionForPoint( endPosition, epsilonContainsTest );

		// if newRegion is null, "endPosition" lies outside of the navMesh
		if ( newRegion == null ) {
			if ( currentRegion == null ) throw( 'YUKA.NavMesh.clampMovement(): No current region available.' );

			// determine closest border edge
			_getClosestBorderEdge( startPosition, closestBorderEdge );

			final closestEdge = closestBorderEdge['edge'];
			final closestPoint = closestBorderEdge['closestPoint'];

			// calculate movement and edge direction
			closestEdge.getDirection( edgeDirection );
			final length = movementDirection.subVectors( endPosition, startPosition ).length;

			// this value influences the speed at which the entity moves along the edge
			double f = 0;

			// if startPosition and endPosition are equal, length becomes zero.
			// it's important to test this edge case in order to avoid NaN values.
			if ( length != 0 ) {
				movementDirection.divideScalar( length );
				f = edgeDirection.dot( movementDirection );
			}

			// calculate position on the edge
			newPosition.copy( closestPoint ).add( edgeDirection.multiplyScalar( f * length ) );

			// the following value "t" tells us if the point exceeds the line segment
			lineSegment.set( closestEdge.prev.vertex, closestEdge.vertex );
			final t = lineSegment.closestPointToPointParameter( newPosition, false );

			//
			if ( t >= 0 && t <= 1 ) {
				// point is within line segment, we can safely use the position
				clampPosition.copy( newPosition );
			} 
			else {
				// check, if the point lies outside the navMesh
				newRegion = getRegionForPoint( newPosition, epsilonContainsTest );

				if ( newRegion != null ) {
					// if not, everything is fine
					clampPosition.copy( newPosition );
					return newRegion;
				}

				// otherwise prevent movement
				clampPosition.copy( startPosition );
			}

			return currentRegion;
		} 
		else {
			// return the region
			return newRegion;
		}
	}

	/// Updates the spatial index by assigning all convex regions to the
	/// partitions of the spatial index.
	NavMesh updateSpatialIndex() {
		if ( spatialIndex != null ) {
			spatialIndex?.makeEmpty();

			final regions = this.regions;

			for ( int i = 0, l = regions.length; i < l; i ++ ) {
				final region = regions[ i ];
				spatialIndex!.addPolygon( region );
			}
		}

		return this;
	}

	_buildRegions( edgeList ) {
		final regions = this.regions;

		final Map<String,HalfEdge?> cache = {
			'leftPrev': null,
			'leftNext': null,
			'rightPrev': null,
			'rightNext': null
		};

		if ( mergeConvexRegions == true ) {

			// process edges from longest to shortest

			for ( int i = 0, l = edgeList.length; i < l; i ++ ) {
				final entry = edgeList[ i ];

				HalfEdge? candidate = entry.edge;

				// cache current references for possible restore
				cache['prev'] = candidate?.prev;
				cache['next'] = candidate?.next;
				cache['prevTwin'] = candidate?.twin?.prev;
				cache['nextTwin'] = candidate?.twin?.next;

				// temporarily change the first polygon in order to represent both polygons

				candidate?.prev?.next = candidate.twin?.next;
				candidate?.next?.prev = candidate.twin?.prev;
				candidate?.twin?.prev?.next = candidate.next;
				candidate?.twin?.next?.prev = candidate.prev;

				final polygon = candidate?.polygon;
				polygon?.edge = candidate?.prev;

				if ( polygon?.convex() == true && polygon?.coplanar( epsilonCoplanarTest ) == true ) {
					// correct polygon reference of all edges
					HalfEdge? edge = polygon?.edge;

					while ( edge != polygon?.edge ) {
						edge?.polygon = polygon;
						edge = edge?.next;
					}

					// delete obsolete polygon

					final index = regions.indexOf( entry.edge.twin.polygon );
					regions.removeAt( index );
				} 
				else {
					// restore
					cache['prev']?.next = candidate;
					cache['next']?.prev = candidate;
					cache['prevTwin']?.next = candidate?.twin;
					cache['nextTwin']?.prev = candidate?.twin;

					polygon?.edge = candidate;
				}
			}
		}

		// after the merging of convex regions, do some post-processing

		for ( int i = 0, l = regions.length; i < l; i ++ ) {
			final region = regions[ i ];

			// compute the centroid of the region which can be used as
			// a destination point in context of path finding
			region.computeCentroid();

			// gather all border edges used by clampMovement()
			HalfEdge? edge = region.edge;
			while ( edge != region.edge ) {
				if ( edge?.twin == null ) _borderEdges.add( edge! );
				edge = edge?.next;
			}
		}
	}

	_buildGraph() {
		final graph = this.graph;
		final regions = this.regions;

		// for each region, the code creates an array of directly accessible regions
		final regionNeighbourhood = [];

		for ( int i = 0, l = regions.length; i < l; i ++ ) {
			final region = regions[ i ];
			final nodeIndices = [];
			regionNeighbourhood.add( nodeIndices );

			HalfEdge? edge = region.edge;

			// iterate through all egdes of the region (in other words: along its contour)
			while ( edge != region.edge ) {

				// check for a portal edge
				if ( edge?.twin != null ) {
					final nodeIndex = getNodeIndex( edge!.twin!.polygon! );
					nodeIndices.add( nodeIndex ); // the node index of the adjacent region

					// add node for this region to the graph if necessary
					if ( graph.hasNode( getNodeIndex( edge.polygon! ) ) == false ) {
						final node = NavNode( getNodeIndex( edge.polygon! ), edge.polygon!.centroid );
						graph.addNode( node );
					}
				}

				edge = edge?.next;
			}
		}

		// add navigation edges
		for ( int i = 0, il = regionNeighbourhood.length; i < il; i ++ ) {
			final indices = regionNeighbourhood[ i ];
			final from = i;

			for ( int j = 0, jl = indices.length; j < jl; j ++ ) {
				final to = indices[ j ];

				if ( from != to ) {
					if ( graph.hasEdge( from, to ) == false ) {
						final nodeFrom = graph.getNode( from )!;
						final nodeTo = graph.getNode( to )!;
						final cost = nodeFrom.position.distanceTo( nodeTo.position );

						graph.addEdge( NavEdge( from, to, cost ) );
					}
				}
			}
		}

		return this;
	}

	NavMesh _getClosestBorderEdge(Vector3 point, closestBorderEdge ) {
		List<HalfEdge>? borderEdges;
		double minDistance = double.infinity;

		if (spatialIndex != null ) {
			edges.clear();

			final index = spatialIndex?.getIndexForPosition( point ) ?? 0;
			final regions = spatialIndex?.cells[ index ].entries;

			for ( int i = 0, l = (regions?.length ?? 0); i < l; i ++ ) {
				final region = regions![ i ];

				HalfEdge? edge = region.edge;

				while ( edge != region.edge ) {
					if ( edge?.twin == null ) edges.add( edge! );
					edge = edge?.next;
				}
			}

			// use only border edges from adjacent convex regions (fast)
			borderEdges = edges;
		} 
    else {
			// use all border edges (slow)
			borderEdges = _borderEdges;
		}

		//
		for ( int i = 0, l = borderEdges.length; i < l; i ++ ) {
			final edge = borderEdges[ i ];

			lineSegment.set( edge.prev!.vertex, edge.vertex );
			final t = lineSegment.closestPointToPointParameter( point );
			lineSegment.at( t, pointOnLineSegment );

			final distance = pointOnLineSegment.squaredDistanceTo( point );

			if ( distance < minDistance ) {
				minDistance = distance;
				closestBorderEdge.edge = edge;
				closestBorderEdge.closestPoint.copy( pointOnLineSegment );
			}
		}

		return this;
	}

	// Determines the portal edge that can be used to reach the given polygon over its twin reference.
	Map<String, dynamic> _getPortalEdge(Polygon region1, Polygon region2, Map<String,dynamic> portalEdge ) {
		HalfEdge? edge = region1.edge;

		while ( edge != region1.edge ) {
			if ( edge?.twin != null ) {
				if ( edge!.twin?.polygon == region2 ) {
					// the direction of portal edges are reversed. so "left" is the edge's origin vertex and "right"
					// is the destintation vertex. More details in issue #5
					portalEdge['left'] = edge.prev?.vertex;
					portalEdge['right'] = edge.vertex;
					return portalEdge;
				}
			}
			edge = edge?.next;
		}

		portalEdge['left'] = null;
		portalEdge['right'] = null;

		return portalEdge;
	}

  int descending( a,  b ) {
    return ( a['cost'] < b['cost'] ) ? 1 : ( a['cost'] > b['cost'] ) ? - 1 : 0;
  }
}

