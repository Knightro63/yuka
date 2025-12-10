import '../core/game_entity.dart';
import '../math/aabb.dart';

/// Class for representing a single partition in context of cell-space partitioning.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Cell {
  late AABB aabb;
  final entries = <dynamic>[];

	/// Constructs a new cell with the given values.
	Cell([AABB? aabb]) {
		this.aabb = aabb ?? AABB();
	}

	/// Adds an entry to this cell.
	Cell add( entry ) {
		entries.add( entry );
		return this;
	}

	/// Removes an entry from this cell.
	Cell remove( entry ) {
		final index = entries.indexOf( entry );
		entries.removeAt( index );
		return this;
	}

	/// Removes all entries from this cell.
	Cell makeEmpty() {
		entries.length = 0;
		return this;
	}

	/// Returns true if this cell is empty.
	bool empty() {
		return entries.isEmpty;
	}

	/// Returns true if the given AABB intersects the internal bounding volume of this cell.
	bool intersects(AABB aabb ) {
		return this.aabb.intersectsAABB( aabb );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'aabb': aabb.toJSON(),
			'entries': []
		};

		final entries = this.entries;

		for ( int i = 0, l = entries.length; i < l; i ++ ) {
			json['entries'].add( entries[ i ].uuid );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	Cell fromJSON(Map<String,dynamic> json ) {
		aabb.fromJSON( json['aabb'] );
    entries.clear();
		entries.addAll(json['entries'].subList());

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	Cell resolveReferences(Map<String,GameEntity> entities ) {
		final entries = this.entries;

		for ( int i = 0, l = entries.length; i < l; i ++ ) {
			entries[ i ] = entities[entries[ i ]];
		}

		return this;
	}
}
