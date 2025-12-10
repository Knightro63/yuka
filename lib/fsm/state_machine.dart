import '../constants.dart';

import '../core/console_logger/console_platform.dart';
import '../core/game_entity.dart';
import './state.dart';

/// Finite state machine (FSM) for implementing State-driven agent design.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class StateMachine {
  GameEntity? owner;
  State? currentState;
  State? previousState;
  State? globalState;
  final Map<String,State> states = {};
  final Map<String,dynamic> _typesMap = {};

	/// Constructs a new state machine with the given values.
	StateMachine([ this.owner ]);

	/// Updates the internal state of the FSM. Usually called by {@link GameEntity#update}.
	StateMachine update() {
		if ( globalState != null ) {
			globalState?.execute( owner );
		}

		if ( currentState != null ) {
			currentState?.execute( owner );
		}

		return this;
	}

	/// Adds a new state with the given ID to the state machine.
	StateMachine add(String id, State? state ) {//State?
		if ( state is State ) {
			states[id] = state;
		} 
    else {
			yukaConsole.warning( 'YUKA.StateMachine: .add() needs a parameter of type "YUKA.State".' );
		}

		return this;
	}

	/// Removes a state via its ID from the state machine.
	StateMachine remove(String id ) {
		states.remove( id );
		return this;
	}

	/// Returns the state for the given ID.
	State? get(String id ) {
		return states[id];
	}

	/// Performs a state change to the state defined by its ID.
	StateMachine changeTo(String id ) {
		final state = get( id );
		_change( state );
		return this;
	}

	/// Returns to the previous state.
	StateMachine revert() {
		_change( previousState );
		return this;
	}

	/// Returns true if this FSM is in the given state.
	bool insert( id ) {
		final state = get( id );
		return ( state == currentState );
	}

	/// Tries to dispatch the massage to the current or global state and returns true
	/// if the message was processed successfully.
	bool handleMessage( telegram ) {
		// first see, if the current state is valid and that it can handle the message

		if (currentState != null && currentState?.onMessage( owner, telegram ) == true ) {
			return true;
		}

		// if not, and if a global state has been implemented, send the message to the global state

		if (globalState != null && globalState?.onMessage( owner, telegram ) == true ) {
			return true;
		}

		return false;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'owner': owner?.uuid,
			'currentState': null,
			'previousState': null,
			'globalState': null,
			'states': []
		};

		final Map<String,dynamic> statesMap = {};

		// states

		for ( final s in states.keys ) {
      final id = s;
      final state = states[s];
			json['states'].add( {
				'type': runtimeType.toString(),
				'id': id,
				'state': state?.toJSON()
			} );

			statesMap[id] = state;
		}

		json['currentState'] = statesMap['currentState'];
		json['previousState'] = statesMap['previousState'];
		json['globalState'] = statesMap['globalState'];

		return json;
	}

	/// Restores this instance from the given JSON object.
	StateMachine fromJSON(Map<String,dynamic> json ) {
		owner = json['owner'];
		final statesJSON = json['states'];

		for (int i = 0, l = statesJSON.length; i < l; i ++ ) {
			final stateJSON = statesJSON[ i ];
			final type = stateJSON['type'];

			final ctor = _typesMap[type];

			if ( ctor != null ) {
				final id = stateJSON.id;
				final state = ctor().fromJSON( stateJSON.state );

				add( id, state );
			} 
      else {
				yukaConsole.warning( 'YUKA.StateMachine: Unsupported state type: $type' );
				continue;
			}
		}

		//
		currentState = json['currentState'];// != null ) ? ( this[json.currentState] ?? null ) : null;
		previousState = json['previousState'];// != null ) ? ( this[json.previousState] ?? null ) : null;
		globalState = json['globalState'];// != null ) ? ( this[json.globalState] ?? null ) : null;

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	StateMachine resolveReferences(Map<String,GameEntity> entities ) {
		owner = entities.get(owner!);

		for (final state in states.values ) {
			state.resolveReferences( entities );
		}

		return this;
	}

	/// Registers a custom type for deserialization. When calling {@link StateMachine#fromJSON}
	/// the state machine is able to pick the correct constructor in order to create custom states.
	StateMachine registerType( String type, Function constructor ) {
		_typesMap[type] = constructor;
		return this;
	}

	//
	void _change(State? state ) {
		previousState = currentState;
		if ( currentState != null ) {
			currentState?.exit( owner );
		}

		currentState = state;
		currentState?.enter( owner );
	}
}
