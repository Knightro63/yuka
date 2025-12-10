import '../core/game_entity.dart';
import 'goal.dart';

/// Class representing a composite goal. Essentially it's a goal which consists of subgoals.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CompositeGoal extends Goal {
  final List<Goal> subgoals = [];

	/// Constructs a new composite goal.
	CompositeGoal([super.owner ]);

	/// Adds a goal as a subgoal to this instance.
	Goal addSubgoal(Goal goal ) {
		subgoals.insert(0, goal );
		return this;
	}

	/// Removes a subgoal from this instance.
	Goal removeSubgoal(Goal goal ) {
		final index = subgoals.indexOf( goal );
		subgoals.removeAt( index );

		return this;
	}

	/// Removes all subgoals and ensures {@link Goal#terminate} is called
	/// for each subgoal.
	Goal clearSubgoals() {
		final subgoals = this.subgoals;

		for ( int i = 0, l = subgoals.length; i < l; i ++ ) {
			final subgoal = subgoals[ i ];
			subgoal.terminate();
		}

		subgoals.length = 0;

		return this;
	}

	/// Returns the current subgoal. If no subgoals are defined, *null* is returned.
	Goal? currentSubgoal() {
		final length = subgoals.length;

		if ( length > 0 ) {
			return subgoals[ length - 1 ];
		} 
    else {
			return null;
		}
	}

	/// Executes the current subgoal of this composite goal.
	GoalStatus executeSubgoals() {
		final subgoals = this.subgoals;
		// remove all completed and failed goals from the back of the subgoal list

		for ( int i = subgoals.length - 1; i >= 0; i -- ) {
			final subgoal = subgoals[ i ];

			if ( ( subgoal.completed == true ) || ( subgoal.failed == true ) ) {

				// if the current subgoal is a composite goal, terminate its subgoals too
				if ( subgoal is CompositeGoal ) {
					subgoal.clearSubgoals();
				}

				// terminate the subgoal itself

				subgoal.terminate();
				subgoals.removeLast();
			} 
      else {
				break;
			}
		}

		// if any subgoals remain, process the one at the back of the list

		final subgoal = currentSubgoal();

		if ( subgoal != null ) {
			subgoal.activateIfInactive();
			subgoal.execute();

			// if subgoal is completed but more subgoals are in the list, return 'ACTIVE'
			// status in order to keep processing the list of subgoals

			if ( ( subgoal.completed == true ) && ( subgoals.length > 1 ) ) {
				return GoalStatus.active;
			} 
      else {
				return subgoal.status;
			}
		} 
    else {
			return GoalStatus.completed;
		}
	}

	/// Returns true if this composite goal has subgoals.
	bool hasSubgoals() {
		return subgoals.isNotEmpty;
	}

	/// Returns true if the given message was processed by the current subgoal.
  @override
	bool handleMessage( telegram ) {
		final subgoal = currentSubgoal();

		if ( subgoal != null ) {
			return subgoal.handleMessage( telegram );
		}

		return false;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['subgoals'] = [];

		for ( int i = 0, l = subgoals.length; i < l; i ++ ) {
			final subgoal = subgoals[ i ];
			json['subgoals'].add( subgoal.toJSON() );
		}

		return json;
	}

	/// Restores UUIDs with references to GameEntity objects.
  @override
	CompositeGoal resolveReferences(Map<String,GameEntity> entities ) {
		super.resolveReferences( entities );

		for ( int i = 0, l = subgoals.length; i < l; i ++ ) {
			final subgoal = subgoals[ i ];
			subgoal.resolveReferences( entities );
		}

		return this;
	}
}