import 'package:examples/showcase/dive/goals/charge_goal.dart';
import 'package:examples/showcase/dive/goals/dodge_goal.dart';
import 'package:examples/showcase/dive/goals/hunt_goal.dart';
import 'package:yuka/yuka.dart';

/// Top-Level goal that is used to manage the attack on a target.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AttackGoal extends CompositeGoal {
  final left = Vector3( - 1, 0, 0 );
  final right = Vector3( 1, 0, 0 );
  final targetPosition = Vector3();

	AttackGoal(super.owner );

  @override
	void activate() {
		// if this goal is reactivated then there may be some existing subgoals that must be removed
		clearSubgoals();
		final owner = this.owner;

		// if the enemy is able to shoot the target (there is line of sight between enemy and
		// target), then select a tactic to follow while shooting
		if ( owner.targetSystem.isTargetShootable() == true ) {
			// if the enemy has space to strafe then do so
			if ( owner.canMoveInDirection( left, targetPosition ) ) {
				addSubgoal( DodgeGoal( owner, false ) );
			} 
      else if ( owner.canMoveInDirection( right, targetPosition ) ) {
				addSubgoal( DodgeGoal( owner, true ) );
			} 
      else {
				// if not able to strafe, charge at the target's position
				addSubgoal( ChargeGoal( owner ) );
			}
		} 
    else {
			// if the target is not visible, go hunt it
			addSubgoal( HuntGoal( owner ) );
		}
	}

  @override
	void execute() {
		// it is possible for a enemy's target to die while this goal is active so we
		// must test to make sure the enemy always has an active target
		final owner = this.owner;

		if ( owner.targetSystem.hasTarget() == false ) {
			status = GoalStatus.completed;
		} 
    else {
			final currentSubgoal = this.currentSubgoal();
			final status = executeSubgoals();

			if ( currentSubgoal is DodgeGoal && currentSubgoal.inactive ) {
				// inactive dogde goals should be reactivated but without reactivating the enire attack goal
				this.status = GoalStatus.active;
			} 
      else {
				this.status = status;
				replanIfFailed();
			}
		}
	}

  @override
	void terminate() {
		this.clearSubgoals();
	}
}