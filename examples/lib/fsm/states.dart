import 'package:yuka/yuka.dart';
import './girl.dart';

class IdleState extends State {
  IdleState():super();

  @override
	void enter([GameEntity? girl ]) {
    girl as Girl;
		final idle = girl.animations['IDLE'];
		idle?.reset().fadeIn( girl.crossFadeDuration );

		//
		girl.ui['currentState'] = 'IDLE';
	}

	@override
	void execute([GameEntity? girl ]) {
    girl as Girl;
		if ( girl.currentTime >= girl.stateDuration ) {
			girl.currentTime = 0;
			girl.stateMachine.changeTo( 'WALK' );
		}
	}

	@override
	void exit([GameEntity? girl ]) {
    girl as Girl;
		final idle = girl.animations['IDLE'];
		idle?.fadeOut( girl.crossFadeDuration );
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON(){
    return {};
  }

	/// Restores this instance from the given JSON object.
  @override
	State fromJSON(Map<String,dynamic> json){
    return this;
  }

	/// Restores UUIDs with references to GameEntity objects.
  @override
	State resolveReferences([Map<String,GameEntity>? owner]){
    return this;
  }
}

class WalkState extends State {
  WalkState():super();

	@override
	void enter([GameEntity? girl ]) {
    girl as Girl;
		girl.ui['currentState'] = 'WALK';
		final walk = girl.animations['WALK'];
		walk?.reset().fadeIn( girl.crossFadeDuration );
	}

	@override
	void execute([GameEntity? girl ]) {
    girl as Girl;
		if ( girl.currentTime >= girl.stateDuration ) {
			girl.currentTime = 0;
			girl.stateMachine.changeTo( 'IDLE' );
		}
	}

	@override
	void exit([GameEntity? girl ]) {
    girl as Girl;
		final walk = girl.animations['WALK'];
		walk?.fadeOut( girl.crossFadeDuration );
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON(){
    return {};
  }

	/// Restores this instance from the given JSON object.
  @override
	State fromJSON(Map<String,dynamic> json){
    return this;
  }

	/// Restores UUIDs with references to GameEntity objects.
  @override
	State resolveReferences([Map<String,GameEntity>? owner]){
    return this;
  }
}