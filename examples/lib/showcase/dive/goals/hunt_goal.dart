import 'package:examples/showcase/dive/goals/find_path_goal.dart';
import 'package:examples/showcase/dive/goals/follow_path_goal.dart';
import 'package:yuka/yuka.dart';

/// Sub-goal for searching the current target of an enemy.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HuntGoal extends CompositeGoal {

	HuntGoal(super.owner );

  @override
	void activate() {
		clearSubgoals();

		final owner = this.owner;

		// seek to the last sensed position
		final targetPosition = owner.targetSystem.getLastSensedPosition();

		// it's important to use path finding since there might be obstacle
		// between the current and target position
		final from = Vector3().copy( owner!.position );
		final to = Vector3().copy( targetPosition );

		// setup subgoals
		addSubgoal( FindPathGoal( owner, from, to ) );
		addSubgoal( FollowPathGoal( owner ) );
	}

  @override
	void execute() {
		final owner = this.owner;

		// hunting is not necessary if the target becomes visible again
		if ( owner.targetSystem.isTargetShootable() ) {
			status = GoalStatus.completed;
		} 
    else {
			status = executeSubgoals();

			// if the enemy is at the last sensed position, forget about
			// the bot, update the target system and consider this goal as completed
			if ( completed ) {
				final target = owner.targetSystem.getTarget();
				owner.removeEntityFromMemory( target );
				owner.targetSystem.update();
			}
      else {
				replanIfFailed();
			}
		}
	}

  @override
	void terminate() {
		clearSubgoals();
	}
}
