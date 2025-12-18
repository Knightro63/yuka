
import 'package:examples/showcase/dive/core/feature.dart';
import 'package:examples/showcase/dive/goals/attack_goal.dart';
import 'package:yuka/yuka.dart';

/// Class for representing the attack goal evaluator. Can be used to compute a score that
/// represents the desirability of the respective top-level goal.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AttackEvaluator extends GoalEvaluator {
  double tweaker = 1;

	AttackEvaluator( [super.characterBias = 1] );

	/// Calculates the desirability. It's a score between 0 and 1 representing the desirability
	/// of a goal.
  @override
	double calculateDesirability(GameEntity owner ) {
    final dynamic temp = owner;
		double desirability = 0;

		if ( temp.targetSystem.hasTarget() ) {
			desirability = tweaker * Feature.totalWeaponStrength( temp ) * Feature.health( temp );
		}

		return desirability;
	}

	/// Executed if this goal evaluator produces the highest desirability.
  @override
	AttackEvaluator setGoal(GameEntity owner ) {
    final dynamic temp = owner;
		final currentSubgoal = temp.brain.currentSubgoal();

		if ( currentSubgoal is! AttackGoal) {
			temp.brain.clearSubgoals();
			temp.brain.addSubgoal( AttackGoal( temp ) );
		}

    return this;
	}
}
