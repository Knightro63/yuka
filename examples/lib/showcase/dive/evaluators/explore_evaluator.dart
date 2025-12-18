import 'package:examples/showcase/dive/goals/explore_goal.dart';
import 'package:yuka/yuka.dart';

/// Class for representing the explore goal evaluator. Can be used to compute a score that
/// represents the desirability of the respective top-level goal.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class ExploreEvaluator extends GoalEvaluator {

	ExploreEvaluator( [super.characterBias = 1] );

	/// Calculates the desirability. It's a score between 0 and 1 representing the desirability
	/// of a goal.
  @override
	double calculateDesirability( GameEntity owner) {
		return 0.1;
	}

	/// Executed if this goal evaluator produces the highest desirability.
  @override
	ExploreEvaluator setGoal(GameEntity owner ) {
    final dynamic temp = owner;
		final currentSubgoal = temp.brain.currentSubgoal();

		if ( currentSubgoal is! ExploreGoal ) {
			temp.brain.clearSubgoals();
			temp.brain.addSubgoal( ExploreGoal( temp ) );
		}

    return this;
	}
}
