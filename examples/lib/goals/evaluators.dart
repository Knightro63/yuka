import 'package:examples/goals/girl.dart';
import 'package:examples/goals/goals.dart';
import 'package:yuka/yuka.dart';

class RestEvaluator extends GoalEvaluator {
  @override
	double calculateDesirability(GameEntity owner ) {
    owner as Girl;
		return ( owner.tired() == true ) ? 1 : 0;
	}

  @override
	void setGoal(GameEntity owner ) {
    owner as Girl;
		final currentSubgoal = owner.brain.currentSubgoal();

		if ( ( currentSubgoal is RestGoal ) == false ) {
			owner.brain.clearSubgoals();
			owner.brain.addSubgoal( RestGoal( owner ) );
		}
	}
}

class GatherEvaluator extends GoalEvaluator {
  @override
	double calculateDesirability(GameEntity owner) {
		return 0.5;
	}

  @override
	void setGoal(GameEntity owner ) {
    owner as Girl;
		final currentSubgoal = owner.brain.currentSubgoal();

		if ( ( currentSubgoal is GatherGoal ) == false ) {
			owner.brain.clearSubgoals();
			owner.brain.addSubgoal( GatherGoal( owner ) );
		}
	}
}
