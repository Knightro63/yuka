import 'package:examples/goals/girl.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

final inverseMatrix = Matrix4();
final localPosition = Vector3();

class RestGoal extends Goal {

	RestGoal( super.owner );

  @override
	void activate() {
		final owner = this.owner as Girl;

		owner.ui['currentGoal'] = 'REST';
		owner.ui['currentSubgoal'] = 'PLACEHOLDER';

		//
		final idle = owner.animations['IDLE'];
		idle?.reset().fadeIn( owner.crossFadeDuration );
	}

  @override
	void execute() {
		final owner = this.owner as Girl;

		owner.currentTime += owner.deltaTime;

		if ( owner.currentTime >= owner.restDuration ) {
			status = GoalStatus.completed;
		}
	}

  @override
	void terminate() {
		final owner = this.owner as Girl;
		owner.currentTime = 0;
		owner.fatigueLevel = 0;
	}
}

//

class GatherGoal extends CompositeGoal {

	GatherGoal( super.owner );

  @override
	void activate() {
	  clearSubgoals();

		final owner = this.owner as Girl;
		owner.ui['currentGoal'] = 'GATHER';

		addSubgoal( FindNextCollectibleGoal( owner ) );
		addSubgoal( SeekToCollectibleGoal( owner ) );
		addSubgoal( PickUpCollectibleGoal( owner ) );

		final idle = owner.animations['IDLE'];
		idle?.fadeOut( owner.crossFadeDuration );
	}

  @override
	void execute() {
		status = executeSubgoals();
		replanIfFailed();
	}
}

//
class FindNextCollectibleGoal extends Goal {
  String? animationId;
	FindNextCollectibleGoal( super.owner );

  @override
	void activate() {

		final owner = this.owner as Girl;

		// update UI

		owner.ui['currentSubgoal'] = 'FIND_NEXT';

		// select closest collectible

		final entities = owner.manager?.entities;
		double minDistance = double.infinity;

		for ( int i = 0, l = (entities?.length ?? 0); i < l; i ++ ) {

			final entity = entities?[ i ];

			if ( entity != owner ) {
				final squaredDistance = owner.position.squaredDistanceTo( entity!.position );

				if ( squaredDistance < minDistance ) {
					minDistance = squaredDistance;
					owner.currentTarget = entity;
				}
			}
		}

		// determine if the girl should perform a left or right turn in order to face
		// the collectible

		owner.worldMatrix().getInverse( inverseMatrix );
		localPosition.copy( owner.currentTarget.position ).applyMatrix4( inverseMatrix );

	  animationId = ( localPosition.x >= 0 ) ? 'LEFT_TURN' : 'RIGHT_TURN';

		final turn = owner.animations[animationId];
		turn?.reset().fadeIn( owner.crossFadeDuration );
	}

  @override
	void execute() {
		final owner = this.owner as Girl;

		if ( owner.currentTarget != null ) {
			if ( owner.rotateTo( owner.currentTarget.position, owner.deltaTime ) == true ) {
				status = GoalStatus.completed;
			}
		} 
    else {
			status = GoalStatus.failed;
		}
	}

  @override
	void terminate() {
		final owner = this.owner as Girl;
		final turn = owner.animations[animationId];
		turn?.fadeOut( owner.crossFadeDuration );
	}
}

//

class SeekToCollectibleGoal extends Goal {

	SeekToCollectibleGoal( super.owner );

  @override
	void activate() {
		final owner = this.owner as Girl;

		// update UI
		owner.ui['currentSubgoal'] = 'SEEK';

		//
		if ( owner.currentTarget != null ) {
			final arriveBehavior = owner.steering.behaviors[ 0 ];
			arriveBehavior.target.copy(owner.currentTarget.position);
			arriveBehavior.active = true;
		} 
    else {
		  status = GoalStatus.failed;
		}

		//
		final walk = owner.animations['WALK'];
		walk?.reset().fadeIn( owner.crossFadeDuration );

	}

  @override
	void execute() {
		if ( active ) {
			final owner = this.owner as Girl;
			final squaredDistance = owner.position.squaredDistanceTo( owner.currentTarget.position );

			if ( squaredDistance < 0.25 ) {
				status = GoalStatus.completed;
			}

			// adjust animation speed based on the actual velocity of the girl

			final animation = owner.animations['WALK'];
			animation?.timeScale = math.min( 0.75, owner.getSpeed() / owner.maxSpeed );
		}
	}

  @override
	void terminate() {
		final owner = this.owner as Girl;

		final arriveBehavior = owner.steering.behaviors[ 0 ];
		arriveBehavior.active = false;
	  owner.velocity.set( 0, 0, 0 );

		final walk = owner.animations['WALK'];
		walk?.fadeOut( owner.crossFadeDuration );
	}
}

//

class PickUpCollectibleGoal extends Goal {
  double collectibleRemoveTimeout = 3; // the time in seconds after a collectible is removed
	PickUpCollectibleGoal( super.owner );

  @override
	void activate() {
		final owner = this.owner as Girl;

		owner.ui['currentSubgoal'] = 'PICK_UP';
		final gather = owner.animations['GATHER'];
		gather?.reset().fadeIn( owner.crossFadeDuration );
	}

  @override
  void execute() {
		final owner = this.owner as Girl;
		owner.currentTime += owner.deltaTime;

		if ( owner.currentTime >= owner.pickUpDuration ) {
			status = GoalStatus.completed;
		} 
    else if ( owner.currentTime >= collectibleRemoveTimeout ) {
			if ( owner.currentTarget != null ) {
				owner.sendMessage( owner.currentTarget, 'PickedUp' );
				owner.currentTarget = null;
			}
		}
	}

  @override
	void terminate() {
		final owner = this.owner as Girl;
		owner.currentTime = 0;
		owner.fatigueLevel ++;
		final gather = owner.animations['GATHER'];
		gather?.fadeOut( owner.crossFadeDuration );
	}
}