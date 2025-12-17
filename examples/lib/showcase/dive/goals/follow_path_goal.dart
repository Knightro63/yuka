import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

/// Sub-goal for seeking the defined destination point.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class FollowPathGoal extends Goal {
  Vector3? to;

	FollowPathGoal( super.owner );

  @override
	void activate() {
		final owner = this.owner;
		final path = owner.path;

		//
		if ( path != null ) {
			if ( owner.world.debug ) {
				// update path helper
				final pathHelper = owner.pathHelper;

				pathHelper.geometry.dispose();
				pathHelper.geometry = three.BufferGeometry().setFromPoints( path );
				pathHelper.visible = owner.world.uiManager.debugParameter.showPaths;
			}

			// update path and steering
			final followPathBehavior = owner.steering.behaviors[ 0 ];
			followPathBehavior.active = true;
			followPathBehavior.path.clear();

			final onPathBehavior = owner.steering.behaviors[ 1 ];
			onPathBehavior.active = true;

			for ( int i = 0, l = path.length; i < l; i ++ ) {
				final waypoint = path[ i ];
				followPathBehavior.path.add( waypoint );
			}

			//
			to = path[ path.length - 1 ];
		} 
    else {
			status = GoalStatus.failed;
		}
	}

  @override
	void execute() {
		if ( active ) {
			final owner = this.owner;

			if ( owner.atPosition( to ) ) {
				status = GoalStatus.completed;
			}
		}
	}

  @override
	void terminate() {
		final owner = this.owner;

		final followPathBehavior = owner.steering.behaviors[ 0 ];
		followPathBehavior.active = false;

		final onPathBehavior = owner.steering.behaviors[ 1 ];
		onPathBehavior.active = false;
	}
}
