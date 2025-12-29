
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/core/world.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:examples/showcase/dive/entities/health_pack.dart';
import 'package:examples/showcase/dive/entities/item.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/entities/weapon_item.dart';
import 'package:examples/showcase/dive/etc/scene_utils.dart';
import 'package:examples/showcase/dive/triggers/item_giver.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

/// This class is responsible for (re)spawning enemies.
///
/// @author {@link https://github.com/robp94|robp94}
/// @author {@link https://github.com/Mugen87|Mugen87}
class SpawningManager {
  World world;
  List<Map<String,dynamic>> spawningPoints = [];
  Map<dynamic,dynamic> itemTriggerMap = {};

	List<HealthPack> healthPacks = [];
	List<Vector3> healthPackSpawningPoints = [];

  // weapons
  List<WeaponItem> blasters = [];
  List<Vector3> blasterSpawningPoints = [];

  List<WeaponItem> shotguns = [];
  List<Vector3> shotgunSpawningPoints = [];

  List<WeaponItem> assaultRilfles = [];
  List<Vector3> assaultRilflesSpawningPoints = [];

	SpawningManager( this.world );

	/// Update method of this manager. Called per simluation step.
	SpawningManager update(double delta ) {
		updateItemList( healthPacks, delta );
		updateItemList( blasters, delta );
		updateItemList( shotguns, delta );
		updateItemList( assaultRilfles, delta );

		return this;
	}

	/// Updates the given item list.
	SpawningManager updateItemList(List itemsList, double delta ) {
		// check if a respawn is necessary
		for ( int i = 0, il = itemsList.length; i < il; i ++ ) {
			final item = itemsList[ i ];

			item.currentTime += delta;

			if ( item.currentTime >= item.nextSpawnTime ) {
				_respawnItem( item );
			}
		}

		return this;
	}

	/// Returns an array with items of the given type.
	List<Item>? getItemList(ItemType type ) {
		List<Item>? itemList;

		switch ( type ) {
			case ItemType.healthPack:
				itemList = healthPacks;
				break;
			case ItemType.blaster:
				itemList = blasters;
				break;
			case ItemType.shotgun:
				itemList = shotguns;
				break;
			case ItemType.assaultRifle:
				itemList = assaultRilfles;
				break;
		}

		return itemList;
	}

	/// Respawns the given competitor.
	SpawningManager respawnCompetitor(GameEntity competitor ) {
		final spawnPoint = getSpawnPoint( competitor )!;

		competitor.position.copy( spawnPoint['position'] );
		competitor.rotation.fromEuler( spawnPoint['rotation']['x'], spawnPoint['rotation']['y']!, spawnPoint['rotation']['z']! );

		if ( competitor is Player ) competitor.head.rotation.set( 0, 0, 0, 1 );
    if ( competitor is Enemy ) competitor.head.rotation.set( 0, 0, 0, 1 );

		return this;
	}

	/// Gets a suitable respawn point for the given enemy.
	Map<String,dynamic>? getSpawnPoint( enemy ) {
		final spawningPoints = this.spawningPoints;
		final competitors = world.competitors;

		double maxDistance = - double.infinity;
		Map<String,dynamic>? bestSpawningPoint;

		// searching for the spawning point furthest away from an enemy
		for ( int i = 0, il = spawningPoints.length; i < il; i ++ ) {
			final spawningPoint = spawningPoints[ i ];
			double closestDistance = double.infinity;

			for ( int j = 0, jl = competitors.length; j < jl; j ++ ) {
				final competitor = competitors[ j ];

				if ( competitor != enemy ) {
					final distance = spawningPoint['position'].squaredDistanceTo( competitor.position );

					if ( distance < closestDistance ) {
						closestDistance = distance;
					}
				}
			}

			if ( closestDistance > maxDistance ) {
				maxDistance = closestDistance;
				bestSpawningPoint = spawningPoint;
			}
		}

		return bestSpawningPoint;
	}

	/// Inits the spawning manager.
	SpawningManager init() {
		initSpawningPoints();
		initHealthPacks();
		initWeapons();

		return this;
	}

	/// Inits the spawning points from the parsed configuration file.
	SpawningManager initSpawningPoints() {
		final levelConfig = world.assetManager?.configs['level'];

		for ( final spawningPoint in levelConfig['competitorSpawningPoints'] ) {
			final List<double> position = List<double>.from(spawningPoint['position'].map((i) => i.toDouble()).toList());//List<double>.from(spawningPoint['position']);
			final List<double> rotation = List<double>.from(spawningPoint['rotation'].map((i) => i.toDouble()).toList());//List<double>.from(spawningPoint['rotation']);

			spawningPoints.add( <String,dynamic>{
				'position': Vector3().fromArray( position ),
				'rotation': { 'x': rotation[ 0 ], 'y': rotation[ 1 ], 'z': rotation[ 2 ] } // euler angles
			} );

		}

		for ( final spawningPoint in levelConfig['healthPackSpawningPoints'] ) {
			healthPackSpawningPoints.add( Vector3().fromUnknown( spawningPoint ) );
		}

		for ( final spawningPoint in levelConfig['shotgunSpawningPoints'] ) {
			shotgunSpawningPoints.add( Vector3().fromUnknown( spawningPoint ) );
		}

		for ( final spawningPoint in levelConfig['assaultRilflesSpawningPoints'] ) {
			assaultRilflesSpawningPoints.add( Vector3().fromUnknown( spawningPoint ) );
		}

		return this;
	}

	/// Inits the collectable health packs.
	SpawningManager initHealthPacks() {
		final World world = this.world;

		for ( final spawningPoint in healthPackSpawningPoints ) {
			// health pack entity
			final healthPack = HealthPack();
			healthPack.position.copy( spawningPoint );

			final three.Object3D? renderComponent = world.assetManager?.models['healthPack']?.clone();
			renderComponent?.position.copyFromArray( healthPack.position.storage );
			healthPack.setRenderComponent( renderComponent, sync );

			healthPacks.add( healthPack );
			world.add( healthPack );

			// navigation
			healthPack.currentRegion = world.navMesh?.getRegionForPoint( healthPack.position, 1 );

			// trigger
			createTrigger( healthPack, config['HEALTH_PACK']['RADIUS'] );
		}

		return this;
	}

	/// Inits the collectable weapons.
	SpawningManager initWeapons() {

		final world = this.world;
		final assetManager = world.assetManager;

		for ( final spawningPoint in blasterSpawningPoints ) {
			// blaster item
			final blasterItem = WeaponItem( ItemType.blaster, config['BLASTER']['RESPAWN_TIME'], config['BLASTER']['AMMO'] );
			blasterItem.position.copy( spawningPoint );

			final renderComponent = assetManager?.models.get( 'blaster_low' ).clone();
			renderComponent.position.copyFromArray( blasterItem.position.storage );
			blasterItem.setRenderComponent( renderComponent, sync );

			blasters.add( blasterItem );
			world.add( blasterItem );

			// navigation
			blasterItem.currentRegion = world.navMesh?.getRegionForPoint( blasterItem.position, 1 );

			// trigger
			createTrigger( blasterItem, config['BLASTER']['RADIUS'] );
		}

		for ( final spawningPoint in shotgunSpawningPoints ) {

			// shotgun item
			final shotgunItem = WeaponItem( ItemType.shotgun, config['SHOTGUN']['RESPAWN_TIME'], config['SHOTGUN']['AMMO'] );
			shotgunItem.position.copy( spawningPoint );

			final three.Object3D? renderComponent = assetManager?.models['shotgun_low']?.clone();
			renderComponent?.position.copyFromArray( shotgunItem.position.storage );
			shotgunItem.setRenderComponent( renderComponent, sync );

			shotguns.add( shotgunItem );
			world.add( shotgunItem );

			// navigation
			shotgunItem.currentRegion = world.navMesh?.getRegionForPoint( shotgunItem.position, 1 );

			// trigger
			createTrigger( shotgunItem, config['SHOTGUN']['RADIUS'] );
		}

		for ( final spawningPoint in assaultRilflesSpawningPoints ) {

			// assault rifle item

			final assaultRilfleItem = WeaponItem( ItemType.assaultRifle, config['ASSAULT_RIFLE']['RESPAWN_TIME'], config['ASSAULT_RIFLE']['AMMO'] );
			assaultRilfleItem.position.copy( spawningPoint );

			final three.Object3D? renderComponent = assetManager?.models['assaultRifle_low']?.clone();
			renderComponent?.position.copyFromArray( assaultRilfleItem.position.storage );
			assaultRilfleItem.setRenderComponent( renderComponent, sync );

			assaultRilfles.add( assaultRilfleItem );
			this.world.add( assaultRilfleItem );

			// navigation
			assaultRilfleItem.currentRegion = world.navMesh?.getRegionForPoint( assaultRilfleItem.position, 1 );

			// trigger
			createTrigger( assaultRilfleItem, config['ASSAULT_RIFLE']['RADIUS'] );
		}

		return this;
	}

	/// Creates a trigger for the given item.
	SpawningManager createTrigger(Item item, double radius ) {
		final sphericalTriggerRegion = SphericalTriggerRegion( radius );

		final trigger = ItemGiver( sphericalTriggerRegion, item );
		item.add( trigger );

		itemTriggerMap[item] = trigger;

		// debugging

		if ( world.debug ) {
			final triggerHelper = SceneUtils.createTriggerHelper( trigger );
			trigger.setRenderComponent( triggerHelper, sync );

			world.helpers['itemHelpers'].add( triggerHelper );
			world.scene.add( triggerHelper );
		}

		return this;
	}

	/// Respawns the given item.
	SpawningManager _respawnItem( item ) {
		// reactivate trigger
		final trigger = itemTriggerMap[item];
		trigger.active = true;

		// reactivate item
		item.finishRespawn();

		return this;
	}

  // used to sync Yuka Game Entities with three.js objects
  void sync(GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}