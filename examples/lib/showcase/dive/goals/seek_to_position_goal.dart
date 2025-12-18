import 'package:yuka/yuka.dart';

/// Sub-goal for seeking a target position.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SeekToPositionGoal extends Goal {
  late final Vector3 target;

	SeekToPositionGoal(super.owner, [Vector3? target]) {
		this.target = target ?? Vector3();
	}

  @override
	void activate() {
		final dynamic owner = this.owner;

		final seekBehavior = owner.steering.behaviors[ 2 ];
		seekBehavior.target.copy( target );
		seekBehavior.active = true;
	}

  @override
	void execute() {
    final dynamic owner = this.owner;
		if ( owner.atPosition( target ) ) {
			status = GoalStatus.completed;
		}
	}

  @override
	void terminate() {
    final dynamic owner = this.owner;
		final seekBehavior = owner.steering.behaviors[ 2 ];
		seekBehavior.active = false;
	}
}
