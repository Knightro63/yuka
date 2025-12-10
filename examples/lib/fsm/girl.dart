import 'package:three_js/three_js.dart';
import 'package:yuka/yuka.dart';
import 'states.dart';

class Girl extends GameEntity {
  late StateMachine stateMachine;
  AnimationMixer mixer;
  double currentTime = 0;
  double stateDuration = 5;
  double crossFadeDuration = 1;
  Map<String,AnimationAction> animations;
  Map<String,String> ui = {};

	Girl(this.mixer, this.animations ):super() {
		ui = {
			'currentState': 'WALK'
		};

		//
		stateMachine = StateMachine( this );
		stateMachine.add( 'IDLE',  IdleState());
		stateMachine.add( 'WALK', WalkState() );
		stateMachine.changeTo( 'IDLE' );
	}

  @override
	Girl update(double delta ) {
		currentTime += delta;
		stateMachine.update();
		mixer.update( delta );
		return this;
	}
}
