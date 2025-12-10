import '../../core/game_entity.dart';
import '../../math/vector3.dart';
import '../../constants.dart';

/// Class for representing the memory information about a single game entity.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MemoryRecord {
  bool visible = false;
  GameEntity? entity;
  double timeBecameVisible = - double.infinity;
  double timeLastSensed = - double.infinity;
  final lastSensedPosition = Vector3();

	/// Constructs a new memory record.
	MemoryRecord([this.entity]);

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'entity': entity?.uuid,
			'timeBecameVisible': timeBecameVisible.toString(),
			'timeLastSensed': timeLastSensed.toString(),
			'lastSensedPosition': lastSensedPosition.storage,
			'visible': visible
		};
	}

	/// Restores this instance from the given JSON object.
	MemoryRecord fromJSON(Map<String,dynamic> json ) {
		entity = json['entity']; // uuid
		timeBecameVisible = double.parse( json['timeBecameVisible'] );
		timeLastSensed = double.parse( json['timeLastSensed'] );
		lastSensedPosition.fromArray( json['lastSensedPosition'] );
		visible = json['visible'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	MemoryRecord resolveReferences( Map<String,GameEntity>entities ) {
		entity = entities.get( entity! );
		return this;
	}
}
