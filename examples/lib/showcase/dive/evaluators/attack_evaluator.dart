
import 'package:examples/showcase/dive/core/feature.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
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
    owner as Enemy;
		double desirability = 0;

		if ( owner.targetSystem.hasTarget() ) {
			desirability = tweaker * Feature.totalWeaponStrength( owner ) * Feature.health( owner );
		}

		return desirability;
	}

	/// Executed if this goal evaluator produces the highest desirability.
  @override
	AttackEvaluator setGoal(GameEntity owner ) {
    owner as Enemy;
		final currentSubgoal = owner.brain.currentSubgoal();

		if ( currentSubgoal is! AttackGoal) {
			owner.brain.clearSubgoals();
			owner.brain.addSubgoal( AttackGoal( owner ) );
		}

    return this;
	}
}
