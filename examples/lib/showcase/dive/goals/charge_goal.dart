import 'package:examples/showcase/dive/goals/find_path_goal.dart';
import 'package:examples/showcase/dive/goals/follow_path_goal.dart';
import 'package:yuka/yuka.dart';

/// Sub-goal for seeking the enemy's target during a battle.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class ChargeGoal extends CompositeGoal {

	ChargeGoal( super.owner );

  @override
	void activate() {
		clearSubgoals();

		final dynamic owner = this.owner;

		// seek to the current position of the target
		final target = owner.targetSystem.getTarget();

		// it's important to use path finding since an enemy might be visible
		// but not directly reachable via a seek behavior because of an obstacle
		final from = Vector3().copy( owner!.position );
		final to = Vector3().copy( target.position );

		// setup subgoals
		addSubgoal( FindPathGoal( owner, from, to ) );
		addSubgoal( FollowPathGoal( owner ) );
	}

  @override
	void execute() {
    final dynamic owner = this.owner;
		// stop executing if the traget is not visible anymore
		if ( owner.targetSystem.isTargetShootable() == false ) {
			status = GoalStatus.completed;
		} 
    else {
			status = executeSubgoals();
			replanIfFailed();
		}
	}

  @override
	void terminate() {
		clearSubgoals();
	}
}
