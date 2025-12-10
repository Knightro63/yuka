import '../core/game_entity.dart';
import '../math/vector3.dart';
import 'vehicle.dart';

/// Base class for all concrete steering behaviors. They produce a force that describes
/// where an agent should move and how fast it should travel to get there.
///
/// Note: All built-in steering behaviors assume a {@link Vehicle#mass} of one. Different values can lead to an unexpected results.
class SteeringBehavior {
  double weight = 1;
  bool active = true;
  Vector3 target = Vector3();

	/// Calculates the steering force for a single simulation step.
	Vector3? calculate(Vehicle vehicle, Vector3 force, [double? delta ]){
    return null;
  }

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'active': active,
			'weight': weight
		};
	}

	/// Restores this instance from the given JSON object.
	SteeringBehavior fromJSON(Map<String,dynamic> json ) {
		active = json['active'];
		weight = json['weight'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	SteeringBehavior? resolveReferences(Map<String,GameEntity> entities ){
    return null;
  }
}
