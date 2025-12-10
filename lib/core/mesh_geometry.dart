import 'dart:typed_data';

import '../math/aabb.dart';
import '../math/bounding_sphere.dart';
import '../math/matrix4.dart';
import '../math/plane.dart';
import '../math/ray.dart';
import '../math/vector3.dart';

/// Class for representing a polygon mesh. The faces consist of triangles.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MeshGeometry {
  BoundingSphere boundingSphere = BoundingSphere();
  final triangle = { 'a': Vector3(), 'b': Vector3(), 'c': Vector3() };
  final rayLocal = Ray();
  final plane = Plane();
  final inverseMatrix = Matrix4();
  final closestIntersectionPoint = Vector3();
  final closestTriangle = { 'a': Vector3(), 'b': Vector3(), 'c': Vector3() };

  late final List<double> vertices;
  List<int>? indices;
  AABB aabb = AABB();
  bool backfaceCulling = true;

	/// Constructs a mesh geometry.
	MeshGeometry([List<double>? vertices, this.indices ]) {
		this.vertices = vertices ?? [];
		computeBoundingVolume();
	}

	/// Computes the internal bounding volumes of this mesh geometry.
	MeshGeometry computeBoundingVolume() {
		final vertices = this.vertices;
		final vertex = Vector3();

		final aabb = this.aabb;
		final boundingSphere = this.boundingSphere;

		// compute AABB
		aabb.min.set( double.infinity, double.infinity, double.infinity );
		aabb.max.set( - double.infinity, - double.infinity, - double.infinity );

		for ( int i = 0, l = vertices.length; i < l; i += 3 ) {
			vertex.x = vertices[ i ];
			vertex.y = vertices[ i + 1 ];
			vertex.z = vertices[ i + 2 ];
			aabb.expand( vertex );
		}

		// compute bounding sphere
		aabb.getCenter( boundingSphere.center );
		boundingSphere.radius = boundingSphere.center.distanceTo( aabb.max );

		return this;
	}

	/// Performs a ray intersection test with the geometry of the obstacle and stores
	/// the intersection point in the given result vector. If no intersection is detected,
	/// *null* is returned.
	Vector3? intersectRay(Ray ray, Matrix4 worldMatrix, bool closest, Vector3 intersectionPoint, [Vector3? normal]) {
		// check bounding sphere first in world space
		boundingSphere.copy( boundingSphere ).applyMatrix4( worldMatrix );
		if ( ray.intersectsBoundingSphere( boundingSphere ) ) {
			// transform the ray into the local space of the obstacle
			worldMatrix.getInverse( inverseMatrix );
			rayLocal.copy( ray ).applyMatrix4( inverseMatrix );
      //print(rayLocal.intersectsAABB( aabb ));
			// check AABB in local space since its more expensive to convert an AABB to world space than a bounding sphere
			if ( rayLocal.intersectsAABB( aabb ) ) {
				// now perform more expensive test with all triangles of the geometry
				final vertices = this.vertices;
				final indices = this.indices;

				double minDistance = double.infinity;
				bool found = false;

				if ( indices == null ) {
					// non-indexed geometry
					for ( int i = 0, l = vertices.length; i < l; i += 9 ) {
						triangle['a']?.set( vertices[ i ], vertices[ i + 1 ], vertices[ i + 2 ] );
						triangle['b']?.set( vertices[ i + 3 ], vertices[ i + 4 ], vertices[ i + 5 ] );
						triangle['c']?.set( vertices[ i + 6 ], vertices[ i + 7 ], vertices[ i + 8 ] );

						if ( rayLocal.intersectTriangle( triangle, backfaceCulling, intersectionPoint ) != null ) {
							if ( closest ) {
								final distance = intersectionPoint.squaredDistanceTo( rayLocal.origin );

								if ( distance < minDistance ) {
									minDistance = distance;

									closestIntersectionPoint.copy( intersectionPoint );
									closestTriangle['a']?.copy( triangle['a']! );
									closestTriangle['b']?.copy( triangle['b']! );
									closestTriangle['c']?.copy( triangle['c']! );
									found = true;
								}
							} 
              else {
								found = true;
								break;
							}
						}
					}
				} 
        else {
					// indexed geometry
					for ( int i = 0, l = indices.length; i < l; i += 3 ) {
						final a = indices[ i ];
						final b = indices[ i + 1 ];
						final c = indices[ i + 2 ];

						final stride = 3;

						triangle['a']?.set( vertices[ ( a * stride ) ], vertices[ ( a * stride ) + 1 ], vertices[ ( a * stride ) + 2 ] );
						triangle['b']?.set( vertices[ ( b * stride ) ], vertices[ ( b * stride ) + 1 ], vertices[ ( b * stride ) + 2 ] );
						triangle['c']?.set( vertices[ ( c * stride ) ], vertices[ ( c * stride ) + 1 ], vertices[ ( c * stride ) + 2 ] );
						
            if ( rayLocal.intersectTriangle( triangle, backfaceCulling, intersectionPoint ) != null ) {
							if ( closest ) {
								final distance = intersectionPoint.squaredDistanceTo( rayLocal.origin );

								if ( distance < minDistance ) {
									minDistance = distance;
									closestIntersectionPoint.copy( intersectionPoint );
									closestTriangle['a']?.copy( triangle['a']! );
									closestTriangle['b']?.copy( triangle['b']! );
									closestTriangle['c']?.copy( triangle['c']! );
									found = true;
								}
							} 
              else {
								found = true;
								break;
							}
						}
					}
				}

				// intersection was found
				if ( found ) {
					if ( closest ) {
						// restore closest intersection point and triangle
						intersectionPoint.copy( closestIntersectionPoint );
						triangle['a']?.copy( closestTriangle['a']! );
						triangle['b']?.copy( closestTriangle['b']! );
						triangle['c']?.copy( closestTriangle['c']! );
					}

					// transform intersection point back to world space
					intersectionPoint.applyMatrix4( worldMatrix );

					// compute normal of triangle in world space if necessary
					if ( normal != null ) {
						plane.fromCoplanarPoints( triangle['a']!, triangle['b']!, triangle['c']! );
						normal.copy( plane.normal );
						normal.transformDirection( worldMatrix );
					}

					return intersectionPoint;
				}
			}
		}

		return null;
	}

	/// Returns a geometry without containing indices. If the geometry is already
	/// non-indexed, the method performs no changes.
	MeshGeometry toTriangleSoup() {
		final indices = this.indices;

		if ( indices != null) {
			final vertices = this.vertices;
			final newVertices = Float32List( indices.length * 3 );

			for ( int i = 0, l = indices.length; i < l; i ++ ) {
				final a = indices[ i ];
				final stride = 3;

				newVertices[ i * stride ] = vertices[ a * stride ];
				newVertices[ ( i * stride ) + 1 ] = vertices[ ( a * stride ) + 1 ];
				newVertices[ ( i * stride ) + 2 ] = vertices[ ( a * stride ) + 2 ];
			}

			return MeshGeometry( newVertices );
		} 
    else {
			return this;
		}
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString()
		};

		json['indices'] = {
			'type': indices.runtimeType.toString(),
			'data': indices
		};

		json['vertices'] = vertices;
		json['backfaceCulling'] = backfaceCulling;
		json['aabb'] = aabb.toJSON();
		json['boundingSphere'] = boundingSphere.toJSON();

		return json;
	}

	/// Restores this instance from the given JSON object.
	MeshGeometry fromJSON(Map<String,dynamic> json ) {
		aabb = AABB().fromJSON( json['aabb'] );
		boundingSphere = BoundingSphere().fromJSON( json['boundingSphere'] );
		backfaceCulling = json['backfaceCulling'];

		vertices = Float32List.fromList( json['vertices'] );

		switch ( json['indices']['type'] ) {
			case 'Uint16Array':
				indices = Uint16List( json['indices']['data'] );
				break;
			case 'Uint32Array':
				indices = Uint32List( json['indices']['data'] );
				break;
			case 'null':
				indices = null;
				break;
		}

		return this;
	}
}
