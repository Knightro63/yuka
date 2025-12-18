import '../core/game_entity.dart';
import 'trigger.dart';

/// Base class for representing trigger regions. It's a predefine region in 3D space,
/// owned by one or more triggers. The shape of the trigger can be arbitrary.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class TriggerRegion {
  double radius = 0;

	/// Returns true if the bounding volume of the given game entity touches/intersects
	/// the trigger region. Must be implemented by all concrete trigger regions.
	bool touching([GameEntity? entity]) {
		return false;
	}

	/// Updates this trigger region. Must be implemented by all concrete trigger regions.
	TriggerRegion update([Trigger? trigger]) {
		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString()
		};
	}

	/// Restores this instance from the given JSON object.
	TriggerRegion fromJSON(Map<String,dynamic> json) {
		return this;
	}
}
