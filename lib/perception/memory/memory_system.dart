

import '../../core/game_entity.dart';
import 'memory_record.dart';
import '../../constants.dart';

/// Class for representing the memory system of a game entity. It is used for managing,
/// filtering, and remembering sensory input.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MemorySystem {
  GameEntity? owner;
  final List<MemoryRecord> records = [];
  final Map<GameEntity,MemoryRecord> recordsMap = {};
  double memorySpan = 1;

	/// Constructs a new memory system.
	MemorySystem([ this.owner  ]);

	/// Returns the memory record of the given game entity.
	MemoryRecord? getRecord(GameEntity entity ) {
		return recordsMap[entity];
	}

	/// Creates a memory record for the given game entity.
	MemorySystem createRecord(GameEntity entity ) {
		final record = MemoryRecord( entity );

		records.add( record );
		recordsMap[entity] =  record;

		return this;
	}

	/// Deletes the memory record for the given game entity.
	MemorySystem deleteRecord(GameEntity entity ) {
		final record = getRecord( entity )!;
		final index = records.indexOf( record );

		records.removeAt( index );
		recordsMap.remove( entity );

		return this;
	}

	/// Returns true if there is a memory record for the given game entity.
	bool hasRecord(GameEntity entity ) {
		return recordsMap.containsKey( entity );
	}

	/// Removes all memory records from the memory system.
	MemorySystem clear() {
		records.length = 0;
		recordsMap.clear();

		return this;
	}

	/// Determines all valid memory record and stores the result in the given array.
	List<MemoryRecord> getValidMemoryRecords(double currentTime, List<MemoryRecord> result ) {
		final records = this.records;
		result.clear();

		for ( int i = 0, l = records.length; i < l; i ++ ) {
			final record = records[ i ];

			if ( ( currentTime - record.timeLastSensed ) <= memorySpan ) {
				result.add( record );
			}
		}

		return result;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'owner': owner?.uuid,
			'records': [],
			'memorySpan': memorySpan
		};

		final records = this.records;

		for ( int i = 0, l = records.length; i < l; i ++ ) {
			final record = records[ i ];
			json['records']?.add( record.toJSON() );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	MemorySystem fromJSON(Map<String,dynamic> json ) {
		owner = json['owner']; // uuid
		memorySpan = json['memorySpan'];

		final recordsJSON = json['records'];

		for ( int i = 0, l = recordsJSON.length; i < l; i ++ ) {
			final recordJSON = recordsJSON[ i ];
			final record = MemoryRecord().fromJSON( recordJSON );

			records.add( record );
		}

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	MemorySystem resolveReferences( Map<String,GameEntity> entities ) {
		owner = entities.get( owner! );

		// records
		final records = this.records;

		for ( int i = 0, l = records.length; i < l; i ++ ) {
			final record = 	records[ i ];

			record.resolveReferences( entities );
			recordsMap[record.entity!] =  record;
		}

		return this;
	}
}
