import 'package:yuka/yuka.dart';

/// Class for representing the opponent bots in this game.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Enemy extends Vehicle {
  final positiveWeightings = [];
  final weightings = [ 0, 0, 0, 0 ];
  final directions = [
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

  dynamic world;

	Enemy( this.world ):super() {
		this.currentTime = 0;
		this.boundingRadius = CONFIG.BOT.BOUNDING_RADIUS;
		this.maxSpeed = CONFIG.BOT.MOVEMENT.MAX_SPEED;
		this.updateOrientation = false;
		this.health = CONFIG.BOT.MAX_HEALTH;
		this.maxHealth = CONFIG.BOT.MAX_HEALTH;
		this.status = STATUS_ALIVE;
		this.isPlayer = false;

		// current convex region of the navmesh the entity is in

		this.currentRegion = null;
		this.currentPosition = Vector3();
		this.previousPosition = Vector3();

		// searching for attackers

		this.searchAttacker = false;
		this.attackDirection = Vector3();
		this.endTimeSearch = double.infinity;
		this.searchTime = CONFIG.BOT.SEARCH_FOR_ATTACKER_TIME;

		// item related properties

		this.ignoreHealth = false;
		this.ignoreShotgun = false;
		this.ignoreAssaultRifle = false;
		this.endTimeIgnoreHealth = double.infinity;
		this.endTimeIgnoreShotgun = double.infinity;
		this.endTimeIgnoreAssaultRifle = double.infinity;
		this.ignoreItemsTimeout = CONFIG.BOT.IGNORE_ITEMS_TIMEOUT;

		// death animation

		this.endTimeDying = double.infinity;
		this.dyingTime = CONFIG.BOT.DYING_TIME;

		// head

		this.head = GameEntity();
		this.head.position.y = CONFIG.BOT.HEAD_HEIGHT;
		this.add( this.head );

		// the weapons are attached to the following container entity

		this.weaponContainer = GameEntity();
		this.head.add( this.weaponContainer );

		// bounds

		this.bounds = CharacterBounds( this );

		// animation

		this.mixer = null;
		this.animations = Map();

		// navigation path

		this.path = null;

		// goal-driven agent design

		this.brain = Think( this );
		this.brain.addEvaluator( AttackEvaluator() );
		this.brain.addEvaluator( ExploreEvaluator() );
		this.brain.addEvaluator( GetHealthEvaluator( 1, HEALTH_PACK ) );
		this.brain.addEvaluator( GetWeaponEvaluator( 1, WEAPON_TYPES_ASSAULT_RIFLE ) );
		this.brain.addEvaluator( GetWeaponEvaluator( 1, WEAPON_TYPES_SHOTGUN ) );


		this.goalArbitrationRegulator = Regulator( CONFIG.BOT.GOAL.UPDATE_FREQUENCY );

		// memory

		this.memorySystem = MemorySystem( this );
		this.memorySystem.memorySpan = CONFIG.BOT.MEMORY.SPAN;
		this.memoryRecords = Array();

		// steering

		final followPathBehavior = FollowPathBehavior();
		followPathBehavior.active = false;
		followPathBehavior.nextWaypointDistance = CONFIG.BOT.NAVIGATION.NEXT_WAYPOINT_DISTANCE;
		followPathBehavior._arrive.deceleration = CONFIG.BOT.NAVIGATION.ARRIVE_DECELERATION;
		this.steering.add( followPathBehavior );

		final onPathBehavior = OnPathBehavior();
		onPathBehavior.active = false;
		onPathBehavior.path = followPathBehavior.path;
		onPathBehavior.radius = CONFIG.BOT.NAVIGATION.PATH_RADIUS;
		onPathBehavior.weight = CONFIG.BOT.NAVIGATION.ONPATH_WEIGHT;
		this.steering.add( onPathBehavior );

		final seekBehavior = SeekBehavior();
		seekBehavior.active = false;
		this.steering.add( seekBehavior );

		// vision

		this.vision = Vision( this.head );
		this.visionRegulator = Regulator( CONFIG.BOT.VISION.UPDATE_FREQUENCY );

		// target system

		this.targetSystem = TargetSystem( this );
		this.targetSystemRegulator = Regulator( CONFIG.BOT.TARGET_SYSTEM.UPDATE_FREQUENCY );

		// weapon system

		this.weaponSystem = WeaponSystem( this );
		this.weaponSelectionRegulator = Regulator( CONFIG.BOT.WEAPON.UPDATE_FREQUENCY );

		// debug

		this.pathHelper = null;
		this.hitboxHelper = null;

	}

	/// Executed when this game entity is updated for the first time by its entity manager.
  @override
	Enemy start() {
		final run = this.animations.get( 'soldier_forward' );
		run.enabled = true;

		final level = manager?.getEntityByName( 'level' );
		vision?.addObstacle( level );

		this.bounds.init();
		this.weaponSystem.init();

		return this;
	}

	/// Updates the internal state of this game entity.
  @override
	Enemy update(double delta ) {
		super.update( delta );

		this.currentTime += delta;

		// ensure the enemy never leaves the level
		stayInLevel();

		// only update the core logic of the enemy if it is alive
		if ( this.status == STATUS_ALIVE ) {

			// update hitbox
			this.bounds.update();

			// update perception
			if ( this.visionRegulator.ready() ) {
				updateVision();
			}

			// update memory system
			this.memorySystem.getValidMemoryRecords( this.currentTime, this.memoryRecords );

			// update target system
			if ( this.targetSystemRegulator.ready() ) {
				this.targetSystem.update();
			}

			// update goals
			this.brain.execute();

			if ( this.goalArbitrationRegulator.ready() ) {
				this.brain.arbitrate();
			}

			// update weapon selection

			if ( this.weaponSelectionRegulator.ready() ) {
				this.weaponSystem.selectBestWeapon();
			}

			// stop search for attacker if necessary
			if ( this.currentTime >= this.endTimeSearch ) {
				resetSearch();
			}

			// reset ignore flags if necessary
			if ( this.currentTime >= this.endTimeIgnoreHealth ) {
				this.ignoreHealth = false;
			}

			if ( this.currentTime >= this.endTimeIgnoreShotgun ) {
				this.ignoreShotgun = false;
			}

			if ( this.currentTime >= this.endTimeIgnoreAssaultRifle ) {
				this.ignoreAssaultRifle = false;
			}

			// updating the weapon system means updating the aiming and shooting.
			// so this call will change the actual heading/orientation of the enemy
			this.weaponSystem.update( delta );
		}

		// handle dying

		if ( this.status == STATUS_DYING ) {
			if ( this.currentTime >= this.endTimeDying ) {
				this.status = STATUS_DEAD;
				this.endTimeDying = double.infinity;
			}
		}

		// handle death
		if ( this.status == STATUS_DEAD ) {
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

	/**
	* Ensures the enemy never leaves the level.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	stayInLevel() {

		// "currentPosition" represents the final position after the movement for a single
		// simualation step. it's now necessary to check if this point is still on
		// the navMesh

		this.currentPosition.copy( this.position );

		this.currentRegion = this.world.navMesh.clampMovement(
			this.currentRegion,
			this.previousPosition,
			this.currentPosition,
			this.position // this is the result vector that gets clamped
		);

		// save this position for the next method invocation

		this.previousPosition.copy( this.position );

		// adjust height of the entity according to the ground

		final distance = this.currentRegion.plane.distanceToPoint( this.position );

		this.position.y -= distance * CONFIG.NAVMESH.HEIGHT_CHANGE_FACTOR; // smooth transition

		return this;

	}

	/**
	* Updates the vision component of this game entity and stores
	* the result in the respective memory system.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	updateVision() {

		final memorySystem = this.memorySystem;
		final vision = this.vision;

		final competitors = this.world.competitors;

		for ( let i = 0, l = competitors.length; i < l; i ++ ) {

			final competitor = competitors[ i ];

			// ignore own entity and consider only living enemies

			if ( competitor === this || competitor.status !== STATUS_ALIVE ) continue;

			if ( memorySystem.hasRecord( competitor ) === false ) {

				memorySystem.createRecord( competitor );

			}

			final record = memorySystem.getRecord( competitor );

			competitor.head.getWorldPosition( worldPosition );

			if ( vision.visible( worldPosition ) === true && competitor.active ) {

				record.timeLastSensed = this.currentTime;
				record.lastSensedPosition.copy( competitor.position ); // it's intended to use the body's position here
				if ( record.visible === false ) record.timeBecameVisible = this.currentTime;
				record.visible = true;

			} else {

				record.visible = false;

			}

		}

		return this;

	}

	/**
	* Updates the animations of this game entity.
	*
	* @param {Number} delta - The time delta.
	* @return {Enemy} A reference to this game entity.
	*/
	updateAnimations( delta ) {

		if ( this.status === STATUS_ALIVE ) {

			// directions

			this.getDirection( lookDirection );
			moveDirection.copy( this.velocity ).normalize();

			// rotation

			quaternion.lookAt( this.forward, moveDirection, this.up );

			// calculate weightings for movement animations

			positiveWeightings.length = 0;
			let sum = 0;

			for ( let i = 0, l = directions.length; i < l; i ++ ) {

				transformedDirection.copy( directions[ i ].direction ).applyRotation( quaternion );
				final dot = transformedDirection.dot( lookDirection );
				weightings[ i ] = ( dot < 0 ) ? 0 : dot;
				final animation = this.animations.get( directions[ i ].name );

				if ( weightings[ i ] > 0.001 ) {

					animation.enabled = true;
					positiveWeightings.push( i );
					sum += weightings[ i ];

				} else {

					animation.enabled = false;
					animation.weight = 0;

				}

			}

			// the weightings for enabled animations have to be calculated in an additional
			// loop since the sum of weightings of all enabled animations has to be 1

			for ( let i = 0, l = positiveWeightings.length; i < l; i ++ ) {

				final index = positiveWeightings[ i ];
				final animation = this.animations.get( directions[ index ].name );
				animation.weight = weightings[ index ] / sum;

				// scale the animtion based on the actual velocity

				animation.timeScale = this.getSpeed() / this.maxSpeed;

			}

		}

		this.mixer.update( delta );

		return this;

	}

	/**
	* Adds the given health points to this entity.
	*
	* @param {Number} amount - The amount of health to add.
	* @return {Enemy} A reference to this game entity.
	*/
	addHealth( amount ) {

		this.health += amount;

		this.health = Math.min( this.health, this.maxHealth ); // ensure that health does not exceed maxHealth

		if ( this.world.debug ) {

			console.log( 'DIVE.Enemy: Entity with ID %s receives %i health points.', this.uuid, amount );

		}

		return this;

	}

	/*
	* Adds the given weapon to the internal weapon system.
	*
	* @param {WEAPON_TYPES} type - The weapon type.
	* @return {Enemy} A reference to this game entity.
	*/
	addWeapon( type ) {

		this.weaponSystem.addWeapon( type );

		// if the entity already has the weapon, increase the ammo

		this.world.uiManager.updateAmmoStatus();

		// bots should directly switch to collected weapons if they have
		// no current target

		if ( this.targetSystem.hasTarget() === false ) {

			this.weaponSystem.setNextWeapon( type );

		}

		return this;

	}

	/**
	* Sets the animations of this game entity by creating a
	* series of animation actions.
	*
	* @param {AnimationMixer} mixer - The animation mixer.
	* @param {Array} clips - An array of animation clips.
	* @return {Enemy} A reference to this game entity.
	*/
	setAnimations( mixer, clips ) {

		this.mixer = mixer;

		// actions

		for ( final clip of clips ) {

			final action = mixer.clipAction( clip );
			action.play();
			action.enabled = false;
			action.name = clip.name;

			this.animations.set( action.name, action );

		}

		return this;

	}

	/**
	* Resets the enemy after a death.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	reset() {

		this.health = this.maxHealth;
		this.status = STATUS_ALIVE;

		// reset search for attacker

		this.resetSearch();

		// items

		this.ignoreHealth = false;
		this.ignoreWeapons = false;

		// clear brain and memory

		this.brain.clearSubgoals();

		this.memoryRecords.length = 0;
		this.memorySystem.clear();

		// reset target and weapon system

		this.targetSystem.reset();
		this.weaponSystem.reset();

		// reset all animations

		this.resetAnimations();

		// set default animation

		final run = this.animations.get( 'soldier_forward' );
		run.enabled = true;

		return this;

	}

	/**
	* Resets all animations.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	resetAnimations() {

		for ( let animation of this.animations.values() ) {

			animation.enabled = false;
			animation.time = 0;
			animation.timeScale = 1;

		}

		return this;

	}

	/**
	* Resets the search for an attacker.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	resetSearch() {

		this.searchAttacker = false;
		this.attackDirection.set( 0, 0, 0 );
		this.endTimeSearch = double.infinity;

		return this;

	}

	/**
	* Inits the death of an entity.
	*
	* @return {Enemy} A reference to this game entity.
	*/
	initDeath() {

		this.status = STATUS_DYING;
		this.endTimeDying = this.currentTime + this.dyingTime;

		this.velocity.set( 0, 0, 0 );

		// reset all steering behaviors

		for ( let behavior of this.steering.behaviors ) {

			behavior.active = false;

		}

		// reset all animations

		this.resetAnimations();

		// start death animation

		final index = MathUtils.randInt( 1, 2 );
		final dying = this.animations.get( 'soldier_death' + index );
		dying.enabled = true;

		return this;

	}

	/**
	* Returns the intesection point if a projectile intersects with this entity.
	* If no intersection is detected, null is returned.
	*
	* @param {Ray} ray - The ray that defines the trajectory of this bullet.
	* @param {Vector3} intersectionPoint - The intersection point.
	* @return {Vector3} The intersection point.
	*/
	checkProjectileIntersection( ray, intersectionPoint ) {

		return this.bounds.intersectRay( ray, intersectionPoint );

	}

	/**
	* Returns true if the enemy is at the given target position. The result of the test
	* can be influenced with a configurable tolerance value.
	*
	* @param {Vector3} position - The target position.
	* @return {Boolean} Whether the enemy is at the given target position or not.
	*/
	atPosition( position ) {

		final tolerance = CONFIG.BOT.NAVIGATION.ARRIVE_TOLERANCE * CONFIG.BOT.NAVIGATION.ARRIVE_TOLERANCE;

		final distance = this.position.squaredDistanceTo( position );

		return distance <= tolerance;

	}

	/**
	* Ignores the given item type for a certain amount of time.
	*
	* @param {Number} type - The item type.
	* @return {Enemy} A reference to this game entity.
	*/
	ignoreItem( type ) {

		switch ( type ) {

			case HEALTH_PACK:
				this.ignoreHealth = true;
				this.endTimeIgnoreHealth = this.currentTime + this.ignoreItemsTimeout;
				break;

			case WEAPON_TYPES_SHOTGUN:
				this.ignoreShotgun = true;
				this.endTimeIgnoreShotgun = this.currentTime + this.ignoreItemsTimeout;
				break;

			case WEAPON_TYPES_ASSAULT_RIFLE:
				this.ignoreAssaultRifle = true;
				this.endTimeIgnoreAssaultRifle = this.currentTime + this.ignoreItemsTimeout;
				break;

			default:
				console.error( 'DIVE.Enemy: Invalid item type:', type );
				break;

		}

		return this;

	}

	/**
	* Returns true if the given item type is currently ignored by the enemy.
	*
	* @param {Number} type - The item type.
	* @return {Boolean} Whether the given item type is ignored or not.
	*/
	isItemIgnored( type ) {

		let ignoreItem = false;

		switch ( type ) {

			case HEALTH_PACK:
				ignoreItem = this.ignoreHealth;
				break;

			case WEAPON_TYPES_SHOTGUN:
				ignoreItem = this.ignoreShotgun;
				break;

			case WEAPON_TYPES_ASSAULT_RIFLE:
				ignoreItem = this.ignoreAssaultRifle;
				break;

			default:
				console.error( 'DIVE.Enemy: Invalid item type:', type );
				break;

		}

		return ignoreItem;

	}

	/**
	* Removes the given entity from the memory system.
	*
	* @param {GameEntity} entity - The entity to remove
	* @return {Enemy} A reference to this game entity.
	*/
	removeEntityFromMemory( entity ) {

		this.memorySystem.deleteRecord( entity );
		this.memorySystem.getValidMemoryRecords( this.currentTime, this.memoryRecords );

		return this;

	}

	/**
	* Returns true if the enemy can move a step to the given dirction without
	* leaving the level. The position vector is stored into the given vector.
	*
	* @param {Vector3} direction - The direction vector.
	* @param {Vector3} position - The position vector.
	* @return {Boolean} Whether the enemy can move a bit to the left or not.
	*/
	canMoveInDirection( direction, position ) {

		position.copy( direction ).applyRotation( this.rotation ).normalize();
		position.multiplyScalar( CONFIG.BOT.MOVEMENT.DODGE_SIZE ).add( this.position );

		final navMesh = this.world.navMesh;
		final region = navMesh.getRegionForPoint( position, 1 );

		return region !== null;

	}

	/**
	* Ensure the enemy only changes it rotation around its y-axis by consider the target
	* in a logical xz-plane which has the same height as the current position.
	* In this way, the enemy never "tilts" its body. Necessary for levels with different heights.
	*
	* @param {Vector3} target - The target position.
	* @param {Number} delta - The time delta.
	* @param {Number} tolerance - A tolerance value in radians to tweak the result
	* when a game entity is considered to face a target.
	* @return {Boolean} Whether the entity is faced to the target or not.
	*/
	rotateTo( target, delta, tolerance ) {

		customTarget.copy( target );
		customTarget.y = this.position.y;

		return super.rotateTo( customTarget, delta, tolerance );

	}

	/**
	* Holds the implementation for the message handling of this game entity.
	*
	* @param {Telegram} telegram - The telegram with the message data.
	* @return {Boolean} Whether the message was processed or not.
	*/
	handleMessage( telegram ) {

		switch ( telegram.message ) {

			case MESSAGE_HIT:

				// reduce health

				this.health -= telegram.data.damage;

				// logging

				if ( this.world.debug ) {

					console.log( 'DIVE.Enemy: Enemy with ID %s hit by Game Entity with ID %s receiving %i damage.', this.uuid, telegram.sender.uuid, telegram.data.damage );

				}

				// if the player is the sender and if the enemy still lives, change the style of the crosshairs

				if ( telegram.sender.isPlayer && this.status === STATUS_ALIVE ) {

					this.world.uiManager.showHitIndication();

				}

				// check if the enemy is death

				if ( this.health <= 0 && this.status === STATUS_ALIVE ) {

					this.initDeath();

					// inform all other competitors about its death

					final competitors = this.world.competitors;

					for ( let i = 0, l = competitors.length; i < l; i ++ ) {

						final competitor = competitors[ i ];

						if ( this !== competitor ) this.sendMessage( competitor, MESSAGE_DEAD );

					}

					// update UI

					this.world.uiManager.addFragMessage( telegram.sender, this );

				} else {

					// if not, search for attacker if he is still alive

					if ( telegram.sender.status === STATUS_ALIVE ) {

						this.searchAttacker = true;
						this.endTimeSearch = this.currentTime + this.searchTime; // only search for a specific amount of time
						this.attackDirection.copy( telegram.data.direction ).multiplyScalar( - 1 ); // negate the vector

					}

				}

				break;

			case MESSAGE_DEAD:

				final sender = telegram.sender;
				final memoryRecord = this.memorySystem.getRecord( sender );

				// delete the dead enemy from the memory system when it was visible.
				// also update the target system so the bot looks for a different target

				if ( memoryRecord && memoryRecord.visible ) {
					this.removeEntityFromMemory( sender );
					this.targetSystem.update();
				}

				break;
		}

		return true;
	}
}
