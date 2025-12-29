import 'package:examples/playground/common/player.dart';
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/core/target_system.dart';
import 'package:examples/showcase/dive/core/weapon_system.dart';
import 'package:examples/showcase/dive/core/world.dart';
import 'package:examples/showcase/dive/etc/character_bounds.dart';
import 'package:examples/showcase/dive/evaluators/attack_evaluator.dart';
import 'package:examples/showcase/dive/evaluators/explore_evaluator.dart';
import 'package:examples/showcase/dive/evaluators/get_health_evaluator.dart';
import 'package:examples/showcase/dive/evaluators/get_weapon_evaluator.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

/// Class for representing the opponent bots in this game.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Enemy extends Vehicle {
  final positiveWeightings = [];
  final weightings = <double>[ 0, 0, 0, 0 ];
  final List<Map<String,dynamic>> directions = [
    { 'direction': Vector3( 0, 0, 1 ), 'name': 'soldier_forward' },
    { 'direction': Vector3( 0, 0, - 1 ), 'name': 'soldier_backward' },
    { 'direction': Vector3( - 1, 0, 0 ), 'name': 'soldier_left' },
    { 'direction': Vector3( 1, 0, 0 ), 'name': 'soldier_right' }
  ];
  final lookDirection = Vector3();
  final moveDirection = Vector3();
  final quaternion = Quaternion();
  final transformedDirection = Vector3();
  final worldPosition = Vector3();
  final customTarget = Vector3();

  World world;
  double currentTime = 0;
 
  int health = config['BOT']['MAX_HEALTH'];
  int maxHealth = config['BOT']['MAX_HEALTH'];
  CharcterStatus status = CharcterStatus.alive;

  Polygon? currentRegion;
  final currentPosition = Vector3();
  final previousPosition = Vector3();

  bool searchAttacker = false;
  final attackDirection = Vector3();
  double endTimeSearch = double.infinity;
  double searchTime = config['BOT']['SEARCH_FOR_ATTACKER_TIME'];

  bool ignoreHealth = false;
  bool ignoreShotgun = false;
  bool ignoreAssaultRifle = false;
  bool ignoreWeapons = false;
  double endTimeIgnoreHealth = double.infinity;
  double endTimeIgnoreShotgun = double.infinity;
  double endTimeIgnoreAssaultRifle = double.infinity;
  double ignoreItemsTimeout = config['BOT']['IGNORE_ITEMS_TIMEOUT'];

  double endTimeDying = double.infinity;
  double dyingTime = config['BOT']['DYING_TIME'];

  final head = GameEntity();
  final weaponContainer = GameEntity();
  late final bounds = CharacterBounds( this );

  final visionRegulator = Regulator( config['BOT']['VISION']['UPDATE_FREQUENCY'] );

	late final targetSystem = TargetSystem( this );
	final targetSystemRegulator = Regulator( config['BOT']['TARGET_SYSTEM']['UPDATE_FREQUENCY'] );

	late final weaponSystem = WeaponSystem( this );
	final weaponSelectionRegulator = Regulator( config['BOT']['WEAPON']['UPDATE_FREQUENCY'] );

  late final brain = Think( this );
	final goalArbitrationRegulator = Regulator( config['BOT']['GOAL']['UPDATE_FREQUENCY'] );

	late final memorySystem = MemorySystem( this );
  final List<MemoryRecord> memoryRecords = [];

  // debug
  three.Object3D? pathHelper;
  three.Object3D? hitboxHelper;
  three.AnimationMixer? mixer;
  List<Vector3>? path;
  Map<String,three.AnimationAction?> animations = {};

	Enemy( this.world ):super() {
    boundingRadius = config['BOT']['BOUNDING_RADIUS'];
    maxSpeed = config['BOT']['MOVEMENT']['MAX_SPEED'];
    updateOrientation = false;
		head.position.y = config['BOT']['HEAD_HEIGHT'];
		add( head );
		head.add( weaponContainer );

		// goal-driven agent design
		brain.addEvaluator( AttackEvaluator() );
		brain.addEvaluator( ExploreEvaluator() );
		brain.addEvaluator( GetHealthEvaluator( 1, ItemType.healthPack ) );
		brain.addEvaluator( GetWeaponEvaluator( 1, ItemType.assaultRifle ) );
		brain.addEvaluator( GetWeaponEvaluator( 1, ItemType.shotgun ) );
		memorySystem.memorySpan = config['BOT']['MEMORY']['SPAN'];

		// steering
		final followPathBehavior = FollowPathBehavior();
		followPathBehavior.active = false;
		followPathBehavior.nextWaypointDistance = config['BOT']['NAVIGATION']['NEXT_WAYPOINT_DISTANCE'];
		followPathBehavior.arrive.deceleration = config['BOT']['NAVIGATION']['ARRIVE_DECELERATION'];
		steering.add( followPathBehavior );

		final onPathBehavior = OnPathBehavior();
		onPathBehavior.active = false;
		onPathBehavior.path = followPathBehavior.path;
		onPathBehavior.radius = config['BOT']['NAVIGATION']['PATH_RADIUS'];
		onPathBehavior.weight = config['BOT']['NAVIGATION']['ONPATH_WEIGHT'];
		steering.add( onPathBehavior );

		final seekBehavior = SeekBehavior();
		seekBehavior.active = false;
		steering.add( seekBehavior );

		// vision
		vision = Vision( head );
	}

	/// Executed when this game entity is updated for the first time by its entity manager.
  @override
	Enemy start() {
		final run = animations['soldier_forward'];
		run?.enabled = true;

		final level = manager?.getEntityByName( 'level' );
		vision?.addObstacle( level! );

		bounds.init();
		weaponSystem.init();

		return this;
	}

	/// Updates the internal state of this game entity.
  @override
	Enemy update(double delta ) {
		super.update( delta );

		currentTime += delta;

		// ensure the enemy never leaves the level
		stayInLevel();

		// only update the core logic of the enemy if it is alive
		if ( status == CharcterStatus.alive ) {

			// update hitbox
		  bounds.update();

			// update perception
			if ( visionRegulator.ready() ) {
				updateVision();
			}

			// update memory system
			memorySystem.getValidMemoryRecords( currentTime, memoryRecords );

			// update target system
			if ( targetSystemRegulator.ready() ) {
				targetSystem.update();
			}

			// update goals
			brain.execute();

			if ( goalArbitrationRegulator.ready() ) {
				brain.arbitrate();
			}

			// update weapon selection
			if ( weaponSelectionRegulator.ready() ) {
				weaponSystem.selectBestWeapon();
			}

			// stop search for attacker if necessary
			if ( currentTime >= endTimeSearch ) {
				resetSearch();
			}

			// reset ignore flags if necessary
			if ( currentTime >= endTimeIgnoreHealth ) {
				ignoreHealth = false;
			}

			if ( currentTime >= endTimeIgnoreShotgun ) {
				ignoreShotgun = false;
			}

			if ( currentTime >= endTimeIgnoreAssaultRifle ) {
				ignoreAssaultRifle = false;
			}

			// updating the weapon system means updating the aiming and shooting.
			// so this call will change the actual heading/orientation of the enemy
			weaponSystem.update( delta );
		}

		// handle dying

		if ( status == CharcterStatus.dying ) {
			if ( currentTime >= endTimeDying ) {
				status = CharcterStatus.dead;
				endTimeDying = double.infinity;
			}
		}

		// handle death
		if ( status == CharcterStatus.dead ) {
			if ( world.debug ) {
				yukaConsole.info( 'DIVE.Enemy: Enemy with ID $uuid died.');
			}

			reset();

			world.spawningManager.respawnCompetitor( this );
		}

		// always update animations
		updateAnimations( delta );

		return this;
	}

	/// Ensures the enemy never leaves the level.
	Enemy stayInLevel() {
		// "currentPosition" represents the final position after the movement for a single
		// simualation step. it's now necessary to check if this point is still on
		// the navMesh
		currentPosition.copy( position );

		currentRegion = world.navMesh?.clampMovement(
			currentRegion,
			previousPosition,
			currentPosition,
			position // this is the result vector that gets clamped
		);

		// save this position for the next method invocation
		previousPosition.copy( position );

		// adjust height of the entity according to the ground
		final double distance = currentRegion?.plane.distanceToPoint( position ) ?? 0;
		position.y -= distance * config['NAVMESH']['HEIGHT_CHANGE_FACTOR']; // smooth transition

		return this;
	}

	/// Updates the vision component of this game entity and stores
	/// the result in the respective memory system.
	Enemy updateVision() {
		final memorySystem = this.memorySystem;
		final vision = this.vision;
		final competitors = world.competitors;

		for ( int i = 0, l = competitors.length; i < l; i ++ ) {
			final competitor = competitors[ i ];

			// ignore own entity and consider only living enemies
			if ( competitor == this || competitor.status != CharcterStatus.alive ) continue;

			if ( memorySystem.hasRecord( competitor ) == false ) {
				memorySystem.createRecord( competitor );
			}

			final record = memorySystem.getRecord( competitor );

			competitor.head.getWorldPosition( worldPosition );

			if ( vision?.visible( worldPosition ) == true && competitor.active ) {
				record?.timeLastSensed = currentTime;
				record?.lastSensedPosition.copy( competitor.position ); // it's intended to use the body's position here
				if ( record?.visible == false ) record?.timeBecameVisible = currentTime;
				record?.visible = true;
			} 
      else {
				record?.visible = false;
			}
		}

		return this;
	}

	/// Updates the animations of this game entity.
	Enemy updateAnimations(double delta ) {
		if ( status == CharcterStatus.alive ) {

			// directions
			getDirection( lookDirection );
			moveDirection.copy( velocity ).normalize();

			// rotation
			quaternion.lookAt( forward, moveDirection, up );

			// calculate weightings for movement animations
			positiveWeightings.length = 0;
			double sum = 0;

			for ( int i = 0, l = directions.length; i < l; i ++ ) {
				transformedDirection.copy( directions[ i ]['direction'] ).applyRotation( quaternion );
				final dot = transformedDirection.dot( lookDirection );
				weightings[ i ] = ( dot < 0 ) ? 0 : dot;
				final animation = animations[directions[ i ]['name']];

				if ( weightings[ i ] > 0.001 ) {
					animation?.enabled = true;
					positiveWeightings.add( i );
					sum += weightings[ i ];
				} 
        else {
					animation?.enabled = false;
					animation?.weight = 0;
				}
			}

			// the weightings for enabled animations have to be calculated in an additional
			// loop since the sum of weightings of all enabled animations has to be 1
			for ( int i = 0, l = positiveWeightings.length; i < l; i ++ ) {
				final index = positiveWeightings[ i ];
				final animation = animations[directions[ index ]['name']];
				animation?.weight = weightings[ index ] / sum;

				// scale the animtion based on the actual velocity
				animation?.timeScale = getSpeed() / maxSpeed;
			}
		}

		mixer?.update( delta );

		return this;
	}

	/// Adds the given health points to this entity.
	Enemy addHealth(int amount ) {
		health += amount;
		health = math.min( health, maxHealth ); // ensure that health does not exceed maxHealth

		if (world.debug ) {
			yukaConsole.info( 'DIVE.Enemy: Entity with ID $uuid receives $amount health points.'  );
		}

		return this;
	}

	/// Adds the given weapon to the internal weapon system.
	Enemy addWeapon(ItemType type ) {
		weaponSystem.addWeapon( type );

		// if the entity already has the weapon, increase the ammo
		world.uiManager.updateAmmoStatus();

		// bots should directly switch to collected weapons if they have
		// no current target
		if ( targetSystem.hasTarget() == false ) {
			weaponSystem.setNextWeapon( type );
		}

		return this;
	}

	/// Sets the animations of this game entity by creating a
	/// series of animation actions.
	Enemy setAnimations(three.AnimationMixer mixer, List<three.AnimationClip> clips ) {
		this.mixer = mixer;

		// actions
		for ( final clip in clips ) {
			final action = mixer.clipAction( clip );
			action?.play();
			action?.enabled = false;
			action?.name = clip.name;

			animations[action?.name ?? ''] = action;
		}

		return this;
	}

	/// Resets the enemy after a death.
	Enemy reset() {
		health = maxHealth;
		status = CharcterStatus.alive;

		// reset search for attacker
		resetSearch();

		// items
	  ignoreHealth = false;
		ignoreWeapons = false;

		// clear brain and memory
	  brain.clearSubgoals();
		memoryRecords.length = 0;
		memorySystem.clear();

		// reset target and weapon system
		targetSystem.reset();
		weaponSystem.reset();

		// reset all animations
		resetAnimations();

		// set default animation
		final run = animations['soldier_forward' ];
		run?.enabled = true;

		return this;
	}

	/// Resets all animations.
	Enemy resetAnimations() {
		for ( final animation in animations.values ) {
			animation?.enabled = false;
			animation?.time = 0;
			animation?.timeScale = 1;
		}

		return this;
	}

	/// Resets the search for an attacker.
	Enemy resetSearch() {
		searchAttacker = false;
		attackDirection.set( 0, 0, 0 );
		endTimeSearch = double.infinity;

		return this;
	}

	/// Inits the death of an entity.
	Enemy initDeath() {
		status = CharcterStatus.dying;
		endTimeDying = currentTime + dyingTime;
		velocity.set( 0, 0, 0 );

		// reset all steering behaviors
		for ( final behavior in steering.behaviors ) {
			behavior.active = false;
		}

		// reset all animations
		resetAnimations();

		// start death animation
		final index = MathUtils.randInt( 1, 2 );
		final dying = animations['soldier_death$index'];
		dying?.enabled = true;

		return this;
	}

	/// Returns the intesection point if a projectile intersects with this entity.
	/// If no intersection is detected, null is returned.
	Vector3? checkProjectileIntersection(Ray ray, Vector3 intersectionPoint ) {
		return bounds.intersectRay( ray, intersectionPoint );
	}

	/// Returns true if the enemy is at the given target position. The result of the test
	/// can be influenced with a configurable tolerance value.
	bool atPosition(Vector3 position ) {
		final tolerance = config['BOT']['NAVIGATION']['ARRIVE_TOLERANCE'] * config['BOT']['NAVIGATION']['ARRIVE_TOLERANCE'];
		final distance = this.position.squaredDistanceTo( position );
		return distance <= tolerance;
	}

	/// Ignores the given item type for a certain amount of time.
	Enemy ignoreItem( ItemType type ) {
		switch ( type ) {
			case ItemType.healthPack:
				ignoreHealth = true;
				endTimeIgnoreHealth = currentTime + ignoreItemsTimeout;
				break;
			case ItemType.shotgun:
				ignoreShotgun = true;
				endTimeIgnoreShotgun = currentTime + ignoreItemsTimeout;
				break;
			case ItemType.assaultRifle:
				ignoreAssaultRifle = true;
				endTimeIgnoreAssaultRifle = currentTime + ignoreItemsTimeout;
				break;
			default:
				yukaConsole.error( 'DIVE.Enemy: Invalid item type: $type');
				break;
		}

		return this;
	}

	/// Returns true if the given item type is currently ignored by the enemy.
	bool isItemIgnored(ItemType type ) {
		bool ignoreItem = false;

		switch ( type ) {
			case ItemType.healthPack:
				ignoreItem = ignoreHealth;
				break;
			case ItemType.shotgun:
				ignoreItem = ignoreShotgun;
				break;
			case ItemType.assaultRifle:
				ignoreItem = ignoreAssaultRifle;
				break;
			default:
				yukaConsole.error( 'DIVE.Enemy: Invalid item type: $type' );
				break;
		}

		return ignoreItem;
	}

	/// Removes the given entity from the memory system.
	Enemy removeEntityFromMemory(GameEntity entity ) {
		memorySystem.deleteRecord( entity );
		memorySystem.getValidMemoryRecords( currentTime, memoryRecords );

		return this;
	}

	/// Returns true if the enemy can move a step to the given dirction without
	/// leaving the level. The position vector is stored into the given vector.
	bool canMoveInDirection(Vector3 direction, Vector3 position ) {
		position.copy( direction ).applyRotation( rotation ).normalize();
		position.multiplyScalar( config['BOT']['MOVEMENT']['DODGE_SIZE'] ).add( this.position );

		final NavMesh? navMesh = world.navMesh;
		final region = navMesh?.getRegionForPoint( position, 1 );

		return region != null;
	}

	/// Ensure the enemy only changes it rotation around its y-axis by consider the target
	/// in a logical xz-plane which has the same height as the current position.
	/// In this way, the enemy never "tilts" its body. Necessary for levels with different heights.
  @override
	bool rotateTo(Vector3 target, double delta, [double? tolerance ]) {
		customTarget.copy( target );
		customTarget.y = position.y;
		return super.rotateTo( customTarget, delta, tolerance );
	}

	/// Holds the implementation for the message handling of this game entity.
  @override
	bool handleMessage(Telegram telegram ) {
		switch ( telegram.message ) {
			case 'hit':
				// reduce health
				health = health - (telegram.data!['damage'] as int);

				// logging
				if ( world.debug ) {
					yukaConsole.info( 'DIVE.Enemy: Enemy with ID $uuid hit by Game Entity with ID ${telegram.sender.uuid} receiving ${telegram.data?['damage']} damage.' );
				}

				// if the player is the sender and if the enemy still lives, change the style of the crosshairs
				if ( telegram.sender is Player && status == CharcterStatus.alive ) {
					world.uiManager.showHitIndication();
				}

				// check if the enemy is death
				if ( health <= 0 && status == CharcterStatus.alive ) {
				  initDeath();

					// inform all other competitors about its death
					final competitors = world.competitors;

					for ( int i = 0, l = competitors.length; i < l; i ++ ) {
						final competitor = competitors[ i ];
						if ( this != competitor ) sendMessage( competitor, Message.dead.name );
					}

					// update UI
					world.uiManager.addFragMessage( telegram.sender, this );
				} 
        else {
          final dynamic sender = telegram.sender;
					// if not, search for attacker if he is still alive
					if ( sender.status == CharcterStatus.alive ) {
						searchAttacker = true;
						endTimeSearch = currentTime + searchTime; // only search for a specific amount of time
						attackDirection.copy( telegram.data!['direction'] ).multiplyScalar( - 1 ); // negate the vector
					}
				}
				break;
			case 'dead':
				final sender = telegram.sender;
				final memoryRecord = memorySystem.getRecord( sender );

				// delete the dead enemy from the memory system when it was visible.
				// also update the target system so the bot looks for a different target
				if ( memoryRecord != null && memoryRecord.visible ) {
					removeEntityFromMemory( sender );
					targetSystem.update();
				}
				break;
		}

		return true;
	}
}
