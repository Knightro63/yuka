import '../core/game_entity.dart';
import '../math/aabb.dart';
import '../math/polygon.dart';
import '../math/vector3.dart';
import 'cell.dart';

/// This class is used for cell-space partitioning, a basic approach for implementing
/// a spatial index. The 3D space is divided up into a number of cells. A cell contains a
/// list of references to all the entities it contains. Compared to other spatial indices like
/// octrees, the division of the 3D space is coarse and often not balanced but the computational
/// overhead for calculating the index of a specific cell based on a position vector is very fast.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CellSpacePartitioning {
  final clampedPosition = Vector3();
  final aabb = AABB();
  final List<Vector3> contour = [];

  double width;
  double height;
  double depth;
  int cellsX;
  int cellsY;
  int cellsZ;

  late double _halfWidth;
  late double _halfHeight;
  late double _halfDepth;

  late final Vector3 _min;
  late final Vector3 _max;

  List<Cell> cells = [];

	/// Constructs a new spatial index with the given values.
	CellSpacePartitioning( this.width, this.height, this.depth, this.cellsX, this.cellsY, this.cellsZ ) {
		_halfWidth = width / 2;
		_halfHeight = height / 2;
		_halfDepth = depth / 2;

		_min = Vector3( - _halfWidth, - _halfHeight, - _halfDepth );
		_max = Vector3( _halfWidth, _halfHeight, _halfDepth );

		//

		final cellSizeX = width / cellsX;
		final cellSizeY = height / cellsY;
		final cellSizeZ = depth / cellsZ;

		for ( int i = 0; i < cellsX; i ++ ) {
			final x = ( i * cellSizeX ) - _halfWidth;

			for ( int j = 0; j < cellsY; j ++ ) {
				final y = ( j * cellSizeY ) - _halfHeight;

				for ( int k = 0; k < cellsZ; k ++ ) {

					final z = ( k * cellSizeZ ) - _halfDepth;

					final min = Vector3();
					final max = Vector3();

					min.set( x, y, z );

					max.x = min.x + cellSizeX;
					max.y = min.y + cellSizeY;
					max.z = min.z + cellSizeZ;

					final aabb = AABB( min, max );
					final cell = Cell( aabb );
					cells.add( cell );
				}
			}
		}
	}

	/// Updates the partitioning index of a given game entity.
	int updateEntity(GameEntity entity, [int currentIndex = - 1 ]) {
		final newIndex = getIndexForPosition( entity.position );

		if ( currentIndex != newIndex ) {
			addEntityToPartition( entity, newIndex );

			if ( currentIndex != - 1 ) {
				removeEntityFromPartition( entity, currentIndex );
			}
		}

		return newIndex;
	}

	/// Adds an entity to a specific partition.
	CellSpacePartitioning addEntityToPartition(GameEntity entity, int index ) {
		final cell = cells[ index ];
		cell.add( entity );

		return this;
	}

	/// Removes an entity from a specific partition.
	CellSpacePartitioning removeEntityFromPartition(GameEntity entity, int index ) {
		final cell = cells[ index ];
		cell.remove( entity );

		return this;
	}

	/// Computes the partition index for the given position vector.
	int getIndexForPosition(Vector3 position ) {
		clampedPosition.copy( position ).clamp( _min, _max );

		int indexX = ( ( ( cellsX * ( clampedPosition.x + _halfWidth ) ) / width ).floor() ).abs();
		int indexY = ( ( ( cellsY * ( clampedPosition.y + _halfHeight ) ) / height ).floor() ).abs();
		int indexZ = ( ( ( cellsZ * ( clampedPosition.z + _halfDepth ) ) / depth ).floor() ).abs();

		// handle index overflow
		if ( indexX == cellsX ) indexX = cellsX - 1;
		if ( indexY == cellsY ) indexY = cellsY - 1;
		if ( indexZ == cellsZ ) indexZ = cellsZ - 1;

		// calculate final index
		return ( indexX * cellsY * cellsZ ) + ( indexY * cellsZ ) + indexZ;
	}

	/// Performs a query to the spatial index according the the given position and
	/// radius. The method approximates the query position and radius with an AABB and
	/// then performs an intersection test with all non-empty cells in order to determine
	/// relevant partitions. Stores the result in the given result array.
	List query(Vector3 position, double radius, List result ) {
		final cells = this.cells;

		result.length = 0;

		// approximate range with an AABB which allows fast intersection test
		aabb.min.copy( position ).subScalar( radius );
		aabb.max.copy( position ).addScalar( radius );

		// test all non-empty cells for an intersection
		for ( int i = 0, l = cells.length; i < l; i ++ ) {
			final cell = cells[ i ];

			if ( cell.empty() == false && cell.intersects( aabb ) == true ) {
				result.addAll( cell.entries );
			}
		}

		return result;
	}

	/// Removes all entities from all partitions.
	CellSpacePartitioning makeEmpty() {
		final cells = this.cells;

		for ( int i = 0, l = cells.length; i < l; i ++ ) {
			cells[ i ].makeEmpty();
		}

		return this;
	}

	/// Adds a polygon to the spatial index. A polygon is approximated with an AABB.
	CellSpacePartitioning addPolygon(Polygon polygon ) {
		final cells = this.cells;

		polygon.getContour( contour );
		aabb.fromPoints( contour );

		for ( int i = 0, l = cells.length; i < l; i ++ ) {
			final cell = cells[ i ];

			if ( cell.intersects( aabb ) == true ) {
				cell.add( polygon );
			}
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {

		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'cells': [],
			'width': width,
			'height': height,
			'depth': depth,
			'cellsX': cellsX,
			'cellsY': cellsY,
			'cellsZ': cellsZ,
			'_halfWidth': _halfWidth,
			'_halfHeight': _halfHeight,
			'_halfDepth': _halfDepth,
			'_min': _min.storage,
			'_max': _max.storage
		};

		for ( int i = 0, l = cells.length; i < l; i ++ ) {
			json['cells'].add( cells[ i ].toJSON() );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	CellSpacePartitioning fromJSON(Map<String,dynamic> json ) {
		cells.length = 0;

		width = json['width'];
		height = json['height'];
		depth = json['depth'];
		cellsX = json['cellsX'];
		cellsY = json['cellsY'];
		cellsZ = json['cellsZ'];

		_halfWidth = json['_halfWidth'];
		_halfHeight = json['_halfHeight'];
		_halfDepth = json['_halfHeight'];

		_min.fromArray( json['_min'] );
		_max.fromArray( json['_max'] );

		for ( int i = 0, l = json['cells'].length; i < l; i ++ ) {
			cells.add( Cell().fromJSON( json['cells'][ i ] ) );
		}

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	CellSpacePartitioning resolveReferences(Map<String,GameEntity> entities ) {
		for ( int i = 0, l = cells.length; i < l; i ++ ) {
			cells[ i ].resolveReferences( entities );
		}

		return this;
	}
}
