import '../core/console_logger/console_platform.dart';
import '../core/game_entity.dart';
import './trigger_region.dart';
import 'regions/rectangular_trigger_region.dart';
import 'regions/spherical_trigger_region.dart';

/// Base class for representing triggers. A trigger generates an action if a game entity
/// touches its trigger region, a predefine area in 3D space.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Trigger extends GameEntity {
  final Map<String,dynamic> _typesMap = {};
  late TriggerRegion region;

	/// Constructs a new trigger with the given values.
	Trigger([TriggerRegion? region]):super() {
    this.region = region ?? TriggerRegion();
    canActivateTrigger = false;
	}

	/// This method is called per simulation step for all game entities. If the game
  /// entity touches the region of the trigger, the respective action is executed.
	Trigger check(GameEntity entity ) {
		if (region.touching( entity ) == true ) {
			execute( entity );
		}

		return this;
	}

	/// This method is called when the trigger should execute its action.
	/// Must be implemented by all concrete triggers.
	void execute(GameEntity entity ) {}

	/// Updates the region of this trigger. Called by the {@link EntityManager} per
	/// simulation step.
	Trigger updateRegion() {
		region.update( this );
		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['region'] = region.toJSON();
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	Trigger fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );

		final Map<String,dynamic> regionJSON = json['region'];
		String type = regionJSON['type'];

		switch ( type ) {
			case 'TriggerRegion':
				region = TriggerRegion().fromJSON( regionJSON );
				break;
			case 'RectangularTriggerRegion':
				region = RectangularTriggerRegion().fromJSON( regionJSON );
				break;
			case 'SphericalTriggerRegion':
				region = SphericalTriggerRegion().fromJSON( regionJSON );
				break;
			default:
				// handle custom type
				final ctor = _typesMap[type];
				if ( ctor != null ) {
					region = ctor().fromJSON( regionJSON );
				} 
        else {
					yukaConsole.warning( 'YUKA.Trigger: Unsupported trigger region type:${regionJSON[type]}',  );
				}
		}

		return this;
	}

	/// Registers a custom type for deserialization. When calling {@link Trigger#fromJSON}
	/// the trigger is able to pick the correct constructor in order to create custom
	/// trigger regions.
	Trigger registerType(String type, constructor ) {
		_typesMap[type] = constructor;
		return this;
	}
}
