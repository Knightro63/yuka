import '../constants.dart';
import '../core/game_entity.dart';
import '../core/telegram.dart';

enum GoalStatus{
	active, // the goal has been activated and will be processed each update step
	inactive, // the goal is waiting to be activated
	completed, // the goal has completed and will be removed on the next update
	failed // the goal has failed and will either replan or be removed on the next update
}

/// Base class for representing a goal in context of Goal-driven agent design.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Goal {
  GameEntity? owner;
  GoalStatus status = GoalStatus.inactive;

	/// Constructs a new goal.
	Goal([this.owner]);

	/// Executed when this goal is activated.
	void activate() {}

	/// Executed in each simulation step.
	void execute() {}

	/// Executed when this goal is satisfied.
	void terminate() {}

	/// Goals can handle messages. Many don't though, so this defines a default behavior
	bool handleMessage( Telegram telegram  ) {
		return false;
	}

	/// Returns true if the status of this goal is *ACTIVE*.
	bool get active => status == GoalStatus.active;

	/// Returns true if the status of this goal is *INACTIVE*.
	bool get inactive => status == GoalStatus.inactive;

	/// Returns true if the status of this goal is *COMPLETED*.
	bool get completed => status == GoalStatus.completed;

	/// Returns true if the status of this goal is *FAILED*.
	bool get failed => status == GoalStatus.failed;

	/// Ensures the goal is replanned if it has failed.
	Goal replanIfFailed() {
		if ( failed == true ) {
			status = GoalStatus.inactive;
		}

		return this;
	}

	/// Ensures the goal is activated if it is inactive.
	Goal activateIfInactive() {
		if ( inactive == true ) {
			status = GoalStatus.active;
			activate();
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'owner': owner?.uuid,
			'status': status
		};

	}

	/// Restores this instance from the given JSON object.
	Goal fromJSON(Map<String,dynamic> json ) {
		owner = json['owner']; // uuid
		status = json['status'];
		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	Goal resolveReferences(Map<String,GameEntity> entities ) {
		owner = entities.get( owner! );
		return this;
	}
}


