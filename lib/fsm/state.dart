import '../core/game_entity.dart';
import '../core/telegram.dart';

/// Base class for representing a state in context of State-driven agent design.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
abstract class State {
	/// This method is called once during a state transition when the {@link StateMachine} makes
	/// this state active.
	void enter([GameEntity? owner]);

	/// This method is called per simulation step if this state is active.
	void execute([GameEntity? owner]);

	/// This method is called once during a state transition when the {@link StateMachine} makes
	/// this state inactive.
	void exit([GameEntity? owner]);

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON();

	/// Restores this instance from the given JSON object.
	State fromJSON(Map<String,dynamic> json);

	/// Restores UUIDs with references to GameEntity objects.
	State resolveReferences([Map<String,GameEntity>? owner]);

	/// This method is called when messaging between game entities occurs.
	bool onMessage([GameEntity? owner, Telegram? telegram]) {
		return false;
	}
}
