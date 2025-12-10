import '../core/game_entity.dart';

/// Base class for representing a goal evaluator in context of Goal-driven agent design.
///
/// @author {@link https://github.com/Mugen87|Mugen87}

class GoalEvaluator {
  double characterBias;

	/// Constructs a new goal evaluator.
	GoalEvaluator([ this.characterBias = 1 ]);
	/// Calculates the desirability. It's a score between 0 and 1 representing the desirability
	/// of a goal. This goal is considered as a top level strategy of the agent like *Explore* or
	/// *AttackTarget*. Must be implemented by all concrete goal evaluators.
	double calculateDesirability(GameEntity owner) {
		return 0;
	}

	/// Executed if this goal evaluator produces the highest desirability. Must be implemented
	/// by all concrete goal evaluators.
	void setGoal(GameEntity owner) {}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'characterBias': characterBias
		};
	}

	/// Restores this instance from the given JSON object.
	GoalEvaluator fromJSON(Map<String,dynamic> json ) {
		characterBias = json['characterBias'];
		return this;
	}
}