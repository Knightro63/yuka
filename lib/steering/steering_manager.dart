import '../constants.dart';
import '../core/console_logger/console_platform.dart';
import '../core/game_entity.dart';
import '../math/vector3.dart';
import 'behaviors/alignment_behavior.dart';
import 'behaviors/arrive_behavior.dart';
import 'behaviors/cohesion_behavior.dart';
import 'behaviors/evade_behavior.dart';
import 'behaviors/flee_behavior.dart';
import 'behaviors/follow_path_behavior.dart';
import 'behaviors/interpose_behavior.dart';
import 'behaviors/obstacle_avoidance_behavior.dart';
import 'behaviors/offset_pursuit_behavior.dart';
import 'behaviors/pursuit_behavior.dart';
import 'behaviors/seek_behavior.dart';
import 'behaviors/separation_behavior.dart';
import 'behaviors/wander_behavior.dart';
import 'steering_behavior.dart';
import 'vehicle.dart';

/// This class is responsible for managing the steering of a single vehicle. The steering manager
/// can manage multiple steering behaviors and combine their produced force into a single one used
/// by the vehicle.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SteeringManager {
  final force = Vector3();
  final Vehicle vehicle;
  List<SteeringBehavior> behaviors = [];

  final _steeringForce = Vector3(); // the calculated steering force per simulation step
  final Map<String,dynamic>_typesMap = {}; // used for deserialization of custom behaviors

	/// Constructs a steering manager.
	SteeringManager(this.vehicle );

	/// Adds the given steering behavior to this steering manager.
	SteeringManager add(SteeringBehavior behavior ) {
		behaviors.add( behavior );
		return this;
	}

	/// Removes the given steering behavior from this steering manager.
	SteeringManager remove(SteeringBehavior behavior ) {
		final index = behaviors.indexOf( behavior );
		behaviors.removeAt( index );

		return this;
	}

	/// Clears the internal state of this steering manager.
	SteeringManager clear() {
		behaviors.length = 0;
		return this;
	}

	/// Calculates the steering forces for all active steering behaviors and
	/// combines it into a single result force. This method is called in
	Vector3 calculate(double delta, Vector3 result ) {
		_calculateByOrder( delta );
		return result.copy( _steeringForce );
	}

	// this method calculates how much of its max steering force the vehicle has
	// left to apply and then applies that amount of the force to add
	bool _accumulate(Vector3 forceToAdd ) {
		// calculate how much steering force the vehicle has used so far
		final magnitudeSoFar = _steeringForce.length;

		// calculate how much steering force remains to be used by this vehicle
		final magnitudeRemaining = vehicle.maxForce - magnitudeSoFar;

		// return false if there is no more force left to use
		if ( magnitudeRemaining <= 0 ) return false;

		// calculate the magnitude of the force we want to add
		final magnitudeToAdd = forceToAdd.length;

		// restrict the magnitude of forceToAdd, so we don't exceed the max force of the vehicle
		if ( magnitudeToAdd > magnitudeRemaining ) {
			forceToAdd.normalize().multiplyScalar( magnitudeRemaining );
		}

		// add force
		_steeringForce.add( forceToAdd );

		return true;
	}

	void _calculateByOrder(double delta ) {
		final behaviors = this.behaviors;

		// reset steering force
		_steeringForce.set( 0, 0, 0 );

		// calculate for each behavior the respective force
		for ( int i = 0, l = behaviors.length; i < l; i ++ ) {
			final behavior = behaviors[ i ];

			if ( behavior.active == true ) {
				force.set( 0, 0, 0 );
				behavior.calculate( vehicle, force, delta );
				force.multiplyScalar( behavior.weight );
				if ( _accumulate( force ) == false ) return;
			}
		}
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> data = {
			'type': 'SteeringManager',
			'behaviors': []
		};

		final behaviors = this.behaviors;

		for ( int i = 0, l = behaviors.length; i < l; i ++ ) {
			final behavior = behaviors[ i ];
			data['behaviors'].add( behavior.toJSON() );
		}

		return data;

	}

	/// Restores this instance from the given JSON object.
	SteeringManager fromJSON(Map<String,dynamic> json ) {
		clear();

		final behaviorsJSON = json['behaviors'];

		for ( int i = 0, l = behaviorsJSON.length; i < l; i ++ ) {
			final behaviorJSON = behaviorsJSON[ i ];
			final type = behaviorJSON.type;

			dynamic behavior;

			switch ( type ) {
				case 'SteeringBehavior':
					behavior = SteeringBehavior().fromJSON( behaviorJSON );
					break;
				case 'AlignmentBehavior':
					behavior = AlignmentBehavior().fromJSON( behaviorJSON );
					break;
				case 'ArriveBehavior':
					behavior = ArriveBehavior().fromJSON( behaviorJSON );
					break;
				case 'CohesionBehavior':
					behavior = CohesionBehavior().fromJSON( behaviorJSON );
					break;
				case 'EvadeBehavior':
					behavior = EvadeBehavior().fromJSON( behaviorJSON );
					break;
				case 'FleeBehavior':
					behavior = FleeBehavior().fromJSON( behaviorJSON );
					break;
				case 'FollowPathBehavior':
					behavior = FollowPathBehavior().fromJSON( behaviorJSON );
					break;
				case 'InterposeBehavior':
					behavior = InterposeBehavior().fromJSON( behaviorJSON );
					break;
				case 'ObstacleAvoidanceBehavior':
					behavior = ObstacleAvoidanceBehavior().fromJSON( behaviorJSON );
					break;
				case 'OffsetPursuitBehavior':
					behavior = OffsetPursuitBehavior().fromJSON( behaviorJSON );
					break;
				case 'PursuitBehavior':
					behavior = PursuitBehavior().fromJSON( behaviorJSON );
					break;
				case 'SeekBehavior':
					behavior = SeekBehavior().fromJSON( behaviorJSON );
					break;
				case 'SeparationBehavior':
					behavior = SeparationBehavior().fromJSON( behaviorJSON );
					break;
				case 'WanderBehavior':
					behavior = WanderBehavior().fromJSON( behaviorJSON );
					break;
				default:
					// handle custom type
					final ctor = _typesMap.get( type );

					if ( ctor != null ) {
						behavior = ctor().fromJSON( behaviorJSON );
					} 
          else {
						yukaConsole.warning( 'YUKA.SteeringManager: Unsupported steering behavior type: $type' );
						continue;
					}
			}

			add( behavior );
		}

		return this;
	}

	/// Registers a custom type for deserialization. When calling {@link SteeringManager#fromJSON}
	///the steering manager is able to pick the correct constructor in order to create custom
	/// steering behavior.
	SteeringManager registerType(String type, Function constructor ) {
		_typesMap[type] =  constructor;
		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	SteeringManager resolveReferences(Map<String,GameEntity> entities ) {
		final behaviors = this.behaviors;

		for ( int i = 0, l = behaviors.length; i < l; i ++ ) {
			final behavior = behaviors[ i ];
			behavior.resolveReferences( entities );
		}

		return this;
	}
}