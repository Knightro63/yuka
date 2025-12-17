import '../core/mesh_geometry.dart';
import 'aabb.dart';
import 'ray.dart';
import 'vector3.dart';

final _v1 = Vector3();
final _v2 = Vector3();
final _v3 = Vector3();

final _xAxis = Vector3( 1, 0, 0 );
final _yAxis = Vector3( 0, 1, 0 );
final _zAxis = Vector3( 0, 0, 1 );

final _triangle = { 'a': Vector3(), 'b': Vector3(), 'c': Vector3() };
final _intersection = Vector3();
final _intersections = [];

/// Class representing a bounding volume hierarchy. The current implementation
/// represents single BVH nodes as AABBs. It accepts arbitrary branching factors
/// and can subdivide the given geometry until a defined hierarchy depth has been reached.
/// Besides, the hierarchy finalruction is performed top-down and the algorithm only
/// performs splits along the cardinal axes.
///
/// Reference: Bounding Volume Hierarchies in Real-Time Collision Detection
/// by Christer Ericson (chapter 6).
///
/// @author {@link https://github.com/robp94|robp94}
/// @author {@link https://github.com/Mugen87|Mugen87}
class BVH {
  double branchingFactor;
  double primitivesPerNode;
  double depth;

  BVHNode? root;

	BVH([ this.branchingFactor = 2, this.primitivesPerNode = 1, this.depth = 10 ]);

	/// Computes a BVH for the given mesh geometry.
	BVH fromMeshGeometry(MeshGeometry geometry ) {
		root = BVHNode();

		// primitives
		if ( geometry.indices != null ) geometry = geometry.toTriangleSoup();

		final vertices = geometry.vertices;

		for ( int i = 0, l = vertices.length; i < l; i ++ ) {
			root?.primitives.add( vertices[ i ] );
		}

		// centroids

		final primitives = root!.primitives;

		for ( int i = 0, l = primitives.length; i < l; i += 9 ) {
			_v1.fromArray( primitives, i );
			_v2.fromArray( primitives, i + 3 );
			_v3.fromArray( primitives, i + 6 );

			_v1.add( _v2 ).add( _v3 ).divideScalar( 3 );

			root?.centroids.addAll([ _v1.x, _v1.y, _v1.z ]);
		}

		// build
		root?.build( branchingFactor, primitivesPerNode, depth, 1 );

		return this;
	}

	/// Executes the given callback for each node of the BVH.
	BVH traverse(Function callback ) {
		root?.traverse( callback );
		return this;
	}
}

/// A single node in a bounding volume hierarchy (BVH).
///
/// @author {@link https://github.com/robp94|robp94}
/// @author {@link https://github.com/Mugen87|Mugen87}
class BVHNode {
  BVHNode? parent;
  final List<BVHNode> children = [];
  final List<double> centroids = [];
  final List<double> primitives = [];
  final AABB boundingVolume = AABB();

	/// Returns true if this BVH node is a root node.
	bool root() {
		return parent == null;
	}

	/// Returns true if this BVH node is a leaf node.
	bool leaf() {
		return children.isEmpty;
	}

	/// Returns the depth of this BVH node in its hierarchy.
	double getDepth() {
		double depth = 0;
		BVHNode? parent = this.parent;

		while ( parent != null ) {
			parent = parent.parent;
			depth ++;
		}

		return depth;
	}

	/// Executes the given callback for this BVH node and its ancestors.
	BVHNode traverse(Function callback ) {
		callback( this );

		for ( int i = 0, l = children.length; i < l; i ++ ) {
			children[ i ].traverse( callback );
		}

		return this;
	}

	/// Builds this BVH node. That means the respective bounding volume
  /// is computed and the node's primitives are distributed under child nodes.
	/// This only happens if the maximum hierarchical depth is not yet reached and
	/// the node does contain enough primitives required for a split.
	BVHNode build(double branchingFactor, double primitivesPerNode, double maxDepth, double currentDepth ) {
		computeBoundingVolume();

		// check depth and primitive count
		final primitiveCount = primitives.length / 9;
		final newPrimitiveCount = ( primitiveCount / branchingFactor ).floor();

		if ( ( currentDepth <= maxDepth ) && ( newPrimitiveCount >= primitivesPerNode ) ) {
			// split (distribute primitives on child BVH nodes)
			split( branchingFactor );

			// proceed with build on the next hierarchy level
			for ( int i = 0; i < branchingFactor; i ++ ) {
				children[ i ].build( branchingFactor, primitivesPerNode, maxDepth, currentDepth + 1 );
			}
		}

		return this;
	}

	/// Computes the AABB for this BVH node.
	BVHNode computeBoundingVolume() {
		final primitives = this.primitives;
		final aabb = boundingVolume;

		// compute AABB

		aabb.min.set( double.infinity, double.infinity, double.infinity );
		aabb.max.set( - double.infinity, - double.infinity, - double.infinity );

		for ( int i = 0, l = primitives.length; i < l; i += 3 ) {
			_v1.x = primitives[ i ];
			_v1.y = primitives[ i + 1 ];
			_v1.z = primitives[ i + 2 ];

			aabb.expand( _v1 );
		}

		return this;
	}

	/// Computes the split axis. Right now, only the cardinal axes
	/// are potential split axes.
	Vector3 computeSplitAxis() {
		double maxX, maxY, maxZ = maxY = maxX = - double.infinity;
		double minX, minY, minZ = minY = minX = double.infinity;

		final centroids = this.centroids;

		for ( int i = 0, l = centroids.length; i < l; i += 3 ) {
			final x = centroids[ i ];
			final y = centroids[ i + 1 ];
			final z = centroids[ i + 2 ];

			if ( x > maxX ) {
				maxX = x;
			}

			if ( y > maxY ) {
				maxY = y;
			}

			if ( z > maxZ ) {
				maxZ = z;
			}

			if ( x < minX ) {
				minX = x;
			}

			if ( y < minY ) {
				minY = y;
			}

			if ( z < minZ ) {
				minZ = z;
			}
		}

		final rangeX = maxX - minX;
		final rangeY = maxY - minY;
		final rangeZ = maxZ - minZ;

		if ( rangeX > rangeY && rangeX > rangeZ ) {
			return _xAxis;
		} 
    else if ( rangeY > rangeZ ) {
			return _yAxis;
		} 
    else {
			return _zAxis;
		}
	}

	/// Splits the node and distributes node's primitives over child nodes.
	BVHNode split(double branchingFactor ) {
		final centroids = this.centroids;
		final primitives = this.primitives;

		// create (empty) child BVH nodes

		for ( int i = 0; i < branchingFactor; i ++ ) {
			children.add(BVHNode());
			children[ i ].parent = this;
		}

		// sort primitives along split axis

		final axis = computeSplitAxis();
		final sortedPrimitiveIndices = [];

		for ( int i = 0, l = centroids.length; i < l; i += 3 ) {
			_v1.fromArray( centroids, i );

			// the result from the dot product is our sort criterion.
			// it represents the projection of the centroid on the split axis

			final p = _v1.dot( axis );
			final primitiveIndex = i ~/ 3;

			sortedPrimitiveIndices.add( { 'index': primitiveIndex, 'p': p } );
		}

		sortedPrimitiveIndices.sort( sortPrimitives );

		// distribute data

		final primitveCount = sortedPrimitiveIndices.length;
		final primitivesPerChild = ( primitveCount / branchingFactor ).floor();

		var childIndex = 0;
		var primitivesIndex = 0;

		for ( int i = 0; i < primitveCount; i ++ ) {
			// selected child
			primitivesIndex ++;

			// check if we try to add more primitives to a child than "primitivesPerChild" defines.
			// move primitives to the next child
			if ( primitivesIndex > primitivesPerChild ) {

				// ensure "childIndex" does not overflow (meaning the last child takes all remaining primitives)
				if ( childIndex < ( branchingFactor - 1 ) ) {
					primitivesIndex = 1; // reset primitive index
					childIndex ++; // raise child index
				}
			}

			final child = children[ childIndex ];

			// move data to the next level
			// 1. primitives
			final primitiveIndex = sortedPrimitiveIndices[ i ]['index'];
			final stride = primitiveIndex * 9; // remember the "primitives" array holds raw vertex data defining triangles

			_v1.fromArray( primitives, stride );
			_v2.fromArray( primitives, stride + 3 );
			_v3.fromArray( primitives, stride + 6 );

			child.primitives.addAll( [_v1.x, _v1.y, _v1.z] );
			child.primitives.addAll( [_v2.x, _v2.y, _v2.z] );
			child.primitives.addAll( [_v3.x, _v3.y, _v3.z] );

			// 2. centroid
			_v1.fromArray( centroids, primitiveIndex * 3 );
			child.centroids.addAll( [_v1.x, _v1.y, _v1.z] );
		}

		// remove centroids/primitives after split from this node

		this.centroids.length = 0;
		this.primitives.length = 0;

		return this;
	}

	/// Performs a ray/BVH node intersection test and stores the closest intersection point
	/// to the given 3D vector. If no intersection is detected, *null* is returned.
	Vector3? intersectRay(Ray ray, Vector3 result ) {
		// gather all intersection points along the hierarchy
		if ( ray.intersectAABB( boundingVolume, result ) != null ) {
			if ( leaf() == true ) {
				final vertices = primitives;

				for ( int i = 0, l = vertices.length; i < l; i += 9 ) {
					// remember: we assume primitives are triangles
					_triangle['a']?.fromArray( vertices, i );
					_triangle['b']?.fromArray( vertices, i + 3 );
					_triangle['c']?.fromArray( vertices, i + 6 );

					if ( ray.intersectTriangle( _triangle, true, result ) != null ) {
						_intersections.add( result.clone() );
					}
				}
			} 
      else {
				// process childs
				for ( int i = 0, l = children.length; i < l; i ++ ) {
					children[ i ].intersectRay( ray, result );
				}
			}
		}

		// determine the closest intersection point in the root node (so after
		// the hierarchy was processed)
		if ( root() == true ) {
			if ( _intersections.isNotEmpty ) {
				double minDistance = double.infinity;

				for ( int i = 0, l = _intersections.length; i < l; i ++ ) {
					final squaredDistance = ray.origin.squaredDistanceTo( _intersections[ i ] );

					if ( squaredDistance < minDistance ) {
						minDistance = squaredDistance;
						result.copy( _intersections[ i ] );
					}
				}

				// reset array
				_intersections.length = 0;

				// return closest intersection point
				return result;
			}
      else {
				// no intersection detected
				return null;
			}
		} 
    else {
			// always return null for non-root nodes
			return null;
		}
	}

	/// Performs a ray/BVH node intersection test. Returns either true or false if
	/// there is a intersection or not.
	bool intersectsRay(Ray ray ) {
		if ( ray.intersectAABB( boundingVolume, _intersection ) != null ) {
			if ( leaf() == true ) {
				final vertices = primitives;

				for ( int i = 0, l = vertices.length; i < l; i += 9 ) {
					// remember: we assume primitives are triangles
					_triangle['a']?.fromArray( vertices, i );
					_triangle['b']?.fromArray( vertices, i + 3 );
					_triangle['c']?.fromArray( vertices, i + 6 );

					if ( ray.intersectTriangle( _triangle, true, _intersection ) != null ) {
						return true;
					}
				}

				return false;
			}
       else {
				// process child BVH nodes
				for ( int i = 0, l = children.length; i < l; i ++ ) {
					if ( children[ i ].intersectsRay( ray ) == true ) {
						return true;
					}
				}
				return false;
			}
		} 
    else {
			return false;
		}
	}
  
  int sortPrimitives( a, b ) {
    return (a['p'] - b['p']).toInt();
  }
}
