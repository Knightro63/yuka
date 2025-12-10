import 'package:examples/goals/evaluators.dart';
import 'package:three_js/three_js.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

class Girl extends Vehicle {
  final AnimationMixer mixer;
  final Map<String,AnimationAction> animations;
  late final Map<String,String> ui;
  late final Think brain;

  double fatigueLevel = 0; // current level of fatigue
  double restDuration = 5; //  duration of a rest phase in seconds
  double pickUpDuration = 6; //  duration of a pick phase in seconds
  double crossFadeDuration = 0.5; // duration of a crossfade in seconds
  double currentTime = 0; // tracks the current time of an action
  double deltaTime = 0; // the current time delta value
  double maxFatigue = 3; // the girl needs to rest if this amount of fatigue is reached

  dynamic currentTarget;

	Girl(this.mixer, this.animations ):super(){

		maxTurnRate = math.pi * 0.5;
		maxSpeed = 1.5;

		final idle = animations['IDLE'];
		idle?.enabled = true;

		ui = {
			'currentGoal': 'SEEK',
			'currentSubgoal': 'FIND_NEXT'
		};

		// goal-driven agent design
		brain = Think( this );

		brain.addEvaluator( RestEvaluator() );
		brain.addEvaluator( GatherEvaluator() );

		// steering
		final arriveBehavior = ArriveBehavior();
		arriveBehavior.deceleration = 1.5;
		steering.add( arriveBehavior );
	}

  @override
	Girl update(double delta ) {
		super.update( delta );
		deltaTime = delta;
		brain.execute();
		brain.arbitrate();
		mixer.update( delta );
		return this;
	}

	bool tired() {
		return ( fatigueLevel >= maxFatigue );
	}
}