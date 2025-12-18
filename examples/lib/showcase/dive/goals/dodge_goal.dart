import 'package:examples/showcase/dive/goals/seek_to_position_goal.dart';
import 'package:yuka/yuka.dart';

/// Sub-goal which makes the enemy dodge from side to side.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class DodgeGoal extends CompositeGoal {
  final _right = Vector3( 1, 0, 0 );
  final _left = Vector3( - 1, 0, 0 );
  bool right = true;
  final targetPosition = Vector3();

	DodgeGoal(super.owner, this.right );

  @override
	void activate() {
		clearSubgoals();

		final dynamic owner = this.owner;

		if ( right) {
			// dodge to right as long as there is enough space
			if ( owner.canMoveInDirection( _right, targetPosition ) ) {
				addSubgoal( SeekToPositionGoal( owner, targetPosition ) );
			} 
      else {
				// no space anymore, now dodge to left
				right = false;
				status = GoalStatus.inactive;
			}
		} 
    else {
			// dodge to left as long as there is enough space
			if ( owner.canMoveInDirection( _left, targetPosition ) ) {
				addSubgoal( SeekToPositionGoal( owner, targetPosition ) );
			} 
      else {
				// no space anymore, now dodge to right
				right = true;
				status = GoalStatus.inactive;
			}
		}
	}

  @override
	void execute() {
		if ( active ) {
			final dynamic owner = this.owner;

			// stop executing if the traget is not visible anymore
			if ( owner.targetSystem.isTargetShootable() == false ) {
				status = GoalStatus.completed;
			} 
      else {
				status = executeSubgoals();
				replanIfFailed();
				// if completed, set the status to inactive in order to repeat the goal
				if ( completed ) status = GoalStatus.inactive;
			}
		}
	}

  @override
	void terminate() {
		clearSubgoals();
	}
}
