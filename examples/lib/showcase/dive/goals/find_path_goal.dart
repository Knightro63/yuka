import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:yuka/yuka.dart';

/// Sub-goal for finding the next random location
/// on the map that the enemy is going to seek.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class FindPathGoal extends Goal {
  final Vector3 from;
  final Vector3 to;

	FindPathGoal( super.owner, this.from, this.to );

  @override
	void activate() {
		final dynamic owner = this.owner;
		final pathPlanner = owner.world.pathPlanner;

		owner.path = null; // reset previous path

		// perform async path finding
		pathPlanner.findPath( owner, from, to, onPathFound );
	}

  @override
	void execute() {
		final dynamic owner = this.owner;

		if ( owner.path != null) {
			// when a path was found, mark this goal as completed
			status = GoalStatus.completed;
		}
	}

  void onPathFound(Vehicle owner, List<Vector3> path ) {
    if(owner is Enemy) owner.path = path;
  }
}


