import 'package:examples/showcase/dive/core/feature.dart';
import 'package:examples/showcase/dive/goals/get_item_goal.dart';
import 'package:yuka/yuka.dart';

/// Class for representing the get-weapon goal evaluator. Can be used to compute a score that
/// represents the desirability of the respective top-level goal.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class GetWeaponEvaluator extends GoalEvaluator {
  int? itemType;
  double tweaker = 0.15; // value used to tweak the desirability

	GetWeaponEvaluator( [super.characterBias = 1, this.itemType] );

	/// Calculates the desirability. It's a score between 0 and 1 representing the desirability
	/// of a goal.
  @override
	double calculateDesirability(GameEntity owner ) {
    final dynamic temp = owner;
		double desirability = 0;

		if ( temp.isItemIgnored( itemType ) == false ) {
			final distanceScore = Feature.distanceToItem( temp, itemType! );
			final weaponScore = Feature.individualWeaponStrength( temp, itemType );
			final healthScore = Feature.health( temp );

			desirability = tweaker * ( 1 - weaponScore ) * healthScore / distanceScore;

			desirability = MathUtils.clamp( desirability, 0, 1 );
		}

		return desirability;
	}

	/// Executed if this goal evaluator produces the highest desirability.
  @override
	GetWeaponEvaluator setGoal(GameEntity owner ) {
    final dynamic temp = owner;
		final currentSubgoal = temp.brain.currentSubgoal();

		if (currentSubgoal is! GetItemGoal) {
			temp.brain.clearSubgoals();
			temp.brain.addSubgoal( GetItemGoal( temp, itemType ) );
		}

    return this;
	}
}