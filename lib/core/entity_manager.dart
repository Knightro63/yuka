import '../partitioning/cell_space_partitioning.dart';
import '../steering/vehicle.dart';
import '../trigger/trigger.dart';
import 'console_logger/console_platform.dart';
import 'game_entity.dart';
import 'message_dispatcher.dart';
import 'moving_entity.dart';

/// This class is used for managing all central objects of a game like
/// game entities.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class EntityManager {
  final candidates = [];
  List<GameEntity> entities = [];
  CellSpacePartitioning? spatialIndex;
  final List<Trigger> _triggers = [];
  final Map<GameEntity,int> _indexMap = {}; 
  final Map<String,dynamic> _typesMap = {};
  final _messageDispatcher = MessageDispatcher();

	/// Adds a game entity to this entity manager.
	EntityManager add(GameEntity entity ) {
		entities.add( entity );
		entity.manager = this;
		return this;
	}

	/// Removes a game entity from this entity manager.
	EntityManager remove(GameEntity entity ) {
		final index = entities.indexOf( entity );
		entities.removeAt( index );

		entity.manager = null;

		return this;
	}

	/// Clears the internal state of this entity manager.
	EntityManager clear() {
		entities.length = 0;
		_messageDispatcher.clear();
		return this;
	}

	/// Returns an entity by the given name. If no game entity is found, *null*
	/// is returned. This method should be used once (e.g. at {@link GameEntity#start})
	/// and the result should be cached for later use.
	GameEntity? getEntityByName(String name ) {
		final entities = this.entities;

		for ( int i = 0, l = entities.length; i < l; i ++ ) {
			final entity = entities[ i ];
			if ( entity.name == name ) return entity;
		}

		return null;
	}

	/// The central update method of this entity manager. Updates all
	/// game entities and delayed messages.
	EntityManager update(double delta ) {
		final entities = this.entities;
		final triggers = _triggers;

		// update entities

		for ( int i = ( entities.length - 1 ); i >= 0; i -- ) {
			final entity = entities[ i ];
			updateEntity( entity, delta );
		}

		// process triggers (this is done after the entity update to ensure
		// up-to-date world matries)
		for ( int i = ( triggers.length - 1 ); i >= 0; i -- ) {
			final trigger = triggers[ i ];
			processTrigger( trigger );
		}

		_triggers.length = 0; // reset

		// handle messaging
		_messageDispatcher.dispatchDelayedMessages( delta );
    
		return this;
	}

	/// Updates a single entity.
	EntityManager updateEntity(GameEntity entity, double delta ) {
		if ( entity.active == true ) {
			updateNeighborhood( entity );

			// check if start() should be executed
			if ( entity.started == false ) {
				entity.start();
				entity.started = true;
			}

			// update entity
			entity.update( delta );

			// update children
			final children = entity.children;

			for ( int i = ( children.length - 1 ); i >= 0; i -- ) {
				final child = children[ i ];
				updateEntity( child, delta );
			}

			// if the entity is a trigger, save the reference for further processing

			if ( entity is Trigger ) {
				_triggers.add( entity );
			}

			// update spatial index

			if ( spatialIndex != null ) {
				int currentIndex = _indexMap[entity] ?? - 1;
				currentIndex = spatialIndex!.updateEntity( entity, currentIndex );
				_indexMap[entity] = currentIndex;
			}

			// update render component
			final renderComponent = entity.renderComponent;
			final renderComponentCallback = entity.renderComponentCallback;

			if ( renderComponent != null && renderComponentCallback != null ) {
				renderComponentCallback( entity, renderComponent );
			}
		}

		return this;
	}

	/// Updates the neighborhood of a single game entity.
	EntityManager updateNeighborhood(GameEntity entity ) {
		if ( entity.updateNeighborhood == true ) {
			entity.neighbors.length = 0;

			// determine candidates

			if ( spatialIndex != null ) {
				spatialIndex?.query( entity.position, entity.neighborhoodRadius, candidates );
			} 
      else {
				// worst case runtime complexity with O(n²)
				candidates.length = 0;
				candidates.addAll( entities );
			}

			// verify if candidates are within the predefined range

			final neighborhoodRadiusSq = ( entity.neighborhoodRadius * entity.neighborhoodRadius );

			for ( int i = 0, l = candidates.length; i < l; i ++ ) {
				final candidate = candidates[ i ];

				if ( entity != candidate && candidate.active == true ) {
					final distanceSq = entity.position.squaredDistanceTo( candidate.position );
					if ( distanceSq <= neighborhoodRadiusSq ) {
						entity.neighbors.add( candidate );
					}
				}
			}
		}

		return this;
	}

	/// Processes a single trigger.
	EntityManager processTrigger(Trigger trigger ) {
		trigger.updateRegion(); // ensure its region is up-to-date

		final entities = this.entities;

		for ( int i = ( entities.length - 1 ); i >= 0; i -- ) {
			final entity = entities[ i ];

			if ( trigger != entity && entity.active == true && entity.canActivateTrigger == true ) {
				trigger.check( entity );
			}
		}

		return this;
	}

	/// Interface for game entities so they can send messages to other game entities.
	EntityManager sendMessage(GameEntity sender, GameEntity receiver, String message, double delay, [Map<String,dynamic>? data ]) {
    _messageDispatcher.dispatch( sender, receiver, message, delay, data );
		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> data = {
			'type': runtimeType.toString(),
			'entities': [],
			'_messageDispatcher': _messageDispatcher.toJSON()
		};

		// entities

		processEntity( entity ) {
			data['entities'].add( entity.toJSON() );
			for ( int i = 0, l = entity.children.length; i < l; i ++ ) {
				processEntity( entity.children[ i ] );
			}
		}

		for ( int i = 0, l = entities.length; i < l; i ++ ) {
			// recursively process all entities
			processEntity( entities[ i ] );
		}

		return data;
	}

	/// Restores this instance from the given JSON object.
	EntityManager fromJSON(Map<String,dynamic> json ) {
		clear();

		final entitiesJSON = json['entities'];
		final messageDispatcherJSON = json['_messageDispatcher'];

		// entities

		final Map<String,dynamic> entitiesMap = {};

		for ( int i = 0, l = entitiesJSON.length; i < l; i ++ ) {
			final entityJSON = entitiesJSON[ i ];
			final type = entityJSON.type;

			dynamic entity;

			switch ( type ) {
				case 'GameEntity':
					entity = GameEntity().fromJSON( entityJSON );
					break;
				case 'MovingEntity':
					entity = MovingEntity().fromJSON( entityJSON );
					break;
				case 'Vehicle':
					entity = Vehicle().fromJSON( entityJSON );
					break;
				case 'Trigger':
					entity = Trigger().fromJSON( entityJSON );
					break;
				default:

					// handle custom type

					final ctor = _typesMap[type];
					if ( ctor != null ) {
						entity = ctor().fromJSON( entityJSON );
					} 
          else {
						yukaConsole.warning( 'YUKA.EntityManager: Unsupported entity type: $type');
						continue;
					}
			}

			entitiesMap[entity.uuid] = entity;

			if ( entity.parent == null ) add( entity );
		}

		// resolve UUIDs to game entity objects

		for ( final entity in entitiesMap.values ) {
			entity.resolveReferences( entitiesMap );
		}

		// restore delayed messages
		_messageDispatcher.fromJSON( messageDispatcherJSON );

		return this;
	}

	/// Registers a custom type for deserialization. When calling {@link EntityManager#fromJSON}
	/// the entity manager is able to pick the correct constructor in order to create custom
	/// game entities.
	EntityManager registerType(String type, Function constructor ) {
		_typesMap[type] = constructor;
		return this;
	}
}
