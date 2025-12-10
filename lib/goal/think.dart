import '../core/console_logger/console_platform.dart';
import 'composite_goal.dart';
import 'goal.dart';
import 'goal_evaluator.dart';

/// Class for representing the brain of a game entity.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Think extends CompositeGoal {
  final List<GoalEvaluator> evaluators = [];
  final Map<String,dynamic> _typesMap = {};

	/// Constructs a new *Think* object.
	Think([super.owner]);

	/// Executed when this goal is activated.
  @override
	void activate() {
		arbitrate();
	}

	/// Executed in each simulation step.
  @override
	void execute() {
		activateIfInactive();
		final subgoalStatus = executeSubgoals();

		if ( subgoalStatus == GoalStatus.completed || subgoalStatus == GoalStatus.failed ) {
			status = GoalStatus.inactive;
		}
	}

	/// Executed when this goal is satisfied.
  @override
	terminate() {
		clearSubgoals();
	}

	/// Adds the given goal evaluator to this instance.
	Think addEvaluator(GoalEvaluator evaluator ) {
		evaluators.add( evaluator );
		return this;
	}

	/// Removes the given goal evaluator from this instance.
	Think removeEvaluator(GoalEvaluator evaluator ) {
		final index = evaluators.indexOf( evaluator );
		evaluators.removeAt( index );
		return this;
	}

	/// This method represents the top level decision process of an agent.
	/// It iterates through each goal evaluator and selects the one that
	/// has the highest score as the current goal.
	Think arbitrate() {
		final evaluators = this.evaluators;

		double bestDesirability = - 1;
		GoalEvaluator? bestEvaluator;

		// try to find the best top-level goal/strategy for the entity
		for ( int i = 0, l = evaluators.length; i < l; i ++ ) {
			final evaluator = evaluators[ i ];

			double desirability = evaluator.calculateDesirability( owner! );
			desirability *= evaluator.characterBias;

			if ( desirability >= bestDesirability ) {
				bestDesirability = desirability;
				bestEvaluator = evaluator;
			}
		}

		// use the evaluator to set the respective goal
		if ( bestEvaluator != null ) {
			bestEvaluator.setGoal( owner! );
		} 
    else {
			yukaConsole.error( 'YUKA.Think: Unable to determine goal evaluator for game entity: $owner');
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['evaluators'] = [];

		for ( int i = 0, l = evaluators.length; i < l; i ++ ) {
			final evaluator = evaluators[ i ];
			json['evaluators'].add( evaluator.toJSON() );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	Think fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		final typesMap = _typesMap;

		evaluators.length = 0;
		terminate();

		// evaluators
		for ( int i = 0, l = json['evaluators'].length; i < l; i ++ ) {
			final evaluatorJSON = json['evaluators'][ i ];
			final type = evaluatorJSON['type'];
			final ctor = typesMap[type];

			if ( ctor != null ) {
				final evaluator = ctor().fromJSON( evaluatorJSON );
				evaluators.add( evaluator );
			} 
      else {
				yukaConsole.warning( 'YUKA.Think: Unsupported goal evaluator type: $type');
				continue;
			}
		}

		// goals
		parseGoal(Map<String,dynamic> goalJSON ) {
			final type = goalJSON['type'];
			final ctor = typesMap[type];

			if ( ctor != null ) {
				final goal = ctor().fromJSON( goalJSON );
				final subgoalsJSON = goalJSON['subgoals'];

				if ( subgoalsJSON != null ) {

					// composite goal
					for ( int i = 0, l = subgoalsJSON.length; i < l; i ++ ) {
						final subgoal = parseGoal( subgoalsJSON[ i ] );
						if ( subgoal ) goal.subgoals.add( subgoal );
					}
				}

				return goal;
			} 
      else {
				yukaConsole.warning( 'YUKA.Think: Unsupported goal evaluator type: $type' );
				return;
			}
		}

		for ( int i = 0, l = json['subgoals'].length; i < l; i ++ ) {
			final subgoal = parseGoal( json['subgoals'][ i ] );
			if ( subgoal ) subgoals.add( subgoal );
		}

		return this;
	}

	/// Registers a custom type for deserialization. When calling {@link Think#fromJSON}
	/// this instance is able to pick the correct constructor in order to create custom
	/// goals or goal evaluators.
	Think registerType(String type, Function constructor ) {
		_typesMap[type] = constructor;
		return this;
	}
}
