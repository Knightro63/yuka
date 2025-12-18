import 'package:examples/showcase/dive/goals/find_path_goal.dart';
import 'package:examples/showcase/dive/goals/follow_path_goal.dart';
import 'package:yuka/yuka.dart';

/// Top-Level goal that is used to manage the map exploration
/// of the enemy.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class ExploreGoal extends CompositeGoal {

	ExploreGoal( super.owner );

  @override
	void activate() {
		final dynamic owner = this.owner;

		// if this goal is reactivated then there may be some existing subgoals that must be removed
		clearSubgoals();

		// compute random position on map
		final region = owner.world.navMesh.getRandomRegion();
		final from = Vector3().copy( owner!.position );
		final to = Vector3().copy( region.centroid );

		// setup subgoals
		addSubgoal( FindPathGoal( owner, from, to ) );
		addSubgoal( FollowPathGoal( owner ) );
	}

  @override
	void execute() {
		status = executeSubgoals();
		replanIfFailed();
	}

  @override
	void terminate() {
		clearSubgoals();
	}
}
