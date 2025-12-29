import 'package:examples/showcase/dive/core/weapon_system.dart';
import 'package:examples/showcase/dive/core/world.dart';
import 'package:examples/showcase/dive/weapons/projectile.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;
import 'package:yuka/yuka.dart';
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';

/// Class for representing the human player of the game.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Player extends MovingEntity {

  final intersectionPoint = Vector3();
  final targetPosition = Vector3();
  final projectile = Projectile();
  final attackDirection = Vector3();
  final lookDirection = Vector3();
  final cross = Vector3();

  World world;
  
  double currentTime = 0;
  int health = config['PLAYER']['MAX_HEALTH'];
  int maxHealth = config['PLAYER']['MAX_HEALTH'];
  double endTimeDying = double.infinity;
  double dyingTime = config['PLAYER']['DYING_TIME'];
  double height = config['PLAYER']['HEAD_HEIGHT'];

  final head = GameEntity();
  final weaponContainer = GameEntity();

	final bounds = AABB();
	final boundsDefinition = AABB( Vector3( - 0.25, 0, - 0.25 ), Vector3( 0.25, 1.8, 0.25 ) );

  CharcterStatus status = CharcterStatus.alive;

  late final WeaponSystem weaponSystem;
  Polygon? currentRegion;
  final currentPosition = Vector3();
  final previousPosition = Vector3();

	three.AnimationMixer? mixer;
	Map<String,three.AnimationAction?> animations = {};
  late Map<String,dynamic> ui = {
    'health': health,
  };

	Player( this.world ):super() {
    name = 'Player';
		boundingRadius = config['PLAYER']['BOUNDING_RADIUS'];
		updateOrientation = false;
		maxSpeed = config['PLAYER']['MAX_SPEED'];

		// the camera is attached to the player's head
		head.forward.set( 0, 0, - 1 );
		add( head );

		head.add( weaponContainer );

		// the player uses the weapon system, too
		weaponSystem = WeaponSystem( this );
		weaponSystem.init();
	}

	/// Updates the internal state of this game entity.
  @override
	Player update(double delta ) {
		super.update( delta );
		currentTime += delta;

		// ensure the enemy never leaves the level
		stayInLevel();

		//
		if ( status == CharcterStatus.alive ) {
			// update weapon system
			weaponSystem.updateWeaponChange();

			// update bounds
			bounds.copy( boundsDefinition ).applyMatrix4( worldMatrix() );
		}

		//
		if ( status == CharcterStatus.dying ) {
			if ( currentTime >= endTimeDying ) {
				status = CharcterStatus.dead;
				endTimeDying = double.infinity;
			}
		}

		//
		if ( status == CharcterStatus.dead ) {
			if ( world.debug ) yukaConsole.info( 'DIVE.Player: Player died.' );
			reset();
			world.spawningManager.respawnCompetitor( this );
			world.fpsControls?.sync();
		}

		//
	  mixer?.update( delta );
    (head.renderComponent as three.Object3D).updateMatrix();

		return this;
	}

	/// Resets the player after a death.
	Player reset() {
		health = maxHealth;
	  status = CharcterStatus.alive;

		weaponSystem.reset();

		world.fpsControls?.reset();

		world.uiManager.showFPSInterface();

		final animation = animations['player_death'];
		animation?.stop();

		return this;

	}

	/// Inits the death of the player.
	Player initDeath() {
		status = CharcterStatus.dying;
		endTimeDying = currentTime + dyingTime;

		velocity.set( 0, 0, 0 );

		final animation = animations['player_death'];
		animation?.play();

		weaponSystem.hideCurrentWeapon();

		world.fpsControls?.active = false;
		world.uiManager.hideFPSInterface();

		return this;
	}

	/// Fires a round at the player's target with the current armed weapon.
	Player shoot() {
		final head = this.head;
		final world = this.world;

		// simulate a shot in order to retrieve the closest intersection point
		final ray = projectile.ray;

		head.getWorldPosition( ray.origin );
		head.getWorldDirection( ray.direction );

		projectile.owner = this;

		final result = world.checkProjectileIntersection( projectile, intersectionPoint );

		// now calculate the distance to the closest intersection point. if no point was found,
		// choose a point on the ray far away from the origin
		final double distance = ( result == null ) ? 1000 : ray.origin.distanceTo( intersectionPoint );
		targetPosition.copy( ray.origin ).add( ray.direction.multiplyScalar( distance ) );

		// fire
		weaponSystem.shoot( targetPosition );

		// update UI
		world.uiManager.updateAmmoStatus();

		return this;
	}

	/// Reloads the current weapon of the player.
	Player reload() {
		weaponSystem.reload();
		return this;
	}

	/// Changes the weapon to the defined type.
	Player changeWeapon(ItemType type ) {
		weaponSystem.setNextWeapon( type );
		return this;
	}

	/// Returns true if the player has a weapon of the given type.
	bool hasWeapon(ItemType type ) {
		return weaponSystem.getWeapon( type ) != null;
	}

	/// Indicates if the player does currently use an automatic weapon.
	bool isAutomaticWeaponUsed() {
		return ( weaponSystem.currentWeapon?.type == ItemType.assaultRifle );
	}

	/// Activates this game entity. Enemies will shot at the player and
  /// the current weapon is rendered.
	Player activate() {
		active = true;
		weaponSystem.currentWeapon?.renderComponent?.visible = true;

		return this;
	}

	/// Deactivates this game entity. Enemies will not shot at the player and
	/// the current weapon is not rendered.
	Player deactivate() {
		active = false;
		weaponSystem.currentWeapon?.renderComponent?.visible = false;

		return this;
	}

	/// Returns the intesection point if a projectile intersects with this entity.
	/// If no intersection is detected, null is returned.
	Vector3? checkProjectileIntersection(Ray ray, Vector3 intersectionPoint ) {
		return ray.intersectAABB( bounds, intersectionPoint );
	}

	/// Ensures the player never leaves the level.
	Player stayInLevel() {
		// "currentPosition" represents the final position after the movement for a single
		// simualation step. it's now necessary to check if this point is still on
		// the navMesh

	  currentPosition.copy( position );

		currentRegion = (world.navMesh as NavMesh).clampMovement(
			currentRegion,
			previousPosition,
			currentPosition,
			position // this is the result vector that gets clamped
		);

		// save this position for the next method invocation
		previousPosition.copy( position );

		// adjust height of the entity according to the ground
		final distance = currentRegion?.plane.distanceToPoint( position ) ?? 0;
		position.y -= distance * config['NAVMESH']['HEIGHT_CHANGE_FACTOR']; // smooth transition

		return this;
	}

	/// Adds the given health points to this entity.
	Player addHealth(int amount ) {
		health += amount;
		health = math.min( health, maxHealth ); // ensure that health does not exceed maxHealth
		world.uiManager.updateHealthStatus();

		//
		if ( world.debug ) {
			yukaConsole.info( 'DIVE.Player: Entity with ID $uuid receives $amount health points.');
		}

    world.updateUI();

		return this;
	}

	/// Adds the given weapon to the internal weapon system.
	Player addWeapon(ItemType type ) {
		weaponSystem.addWeapon( type );

		// if the entity already has the weapon, increase the ammo
	  world.uiManager.updateAmmoStatus();

		return this;
	}

  /// Sets the animations of this game entity by creating a
	/// series of animation actions.
	Player setAnimations(three.AnimationMixer? mixer, List<three.AnimationClip> clips ) {
		this.mixer = mixer;

		// actions
		for ( final clip in clips ) {
			final action = mixer?.clipAction( clip );
			action?.loop = three.LoopOnce;
			action?.name = clip.name;

			animations[action?.name ?? ''] = action;
		}

		return this;
	}

	/// Holds the implementation for the message handling of this game entity.
  @override
	bool handleMessage(Telegram telegram ) {
		switch ( telegram.message ) {
			case 'hit':
				// reduce health
				health = (health - telegram.data?['damage']).toInt();

				// update UI
				world.uiManager.updateHealthStatus();

				// logging
				if ( world.debug ) {
					yukaConsole.info( 'DIVE.Player: Player hit by Game Entity with ID ${telegram.sender.uuid} receiving ${telegram.data?['damage']} damage.' );
				}

				// check if the player is dead
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
					final angle = computeAngleToAttacker( telegram.data?['direction'] );
					world.uiManager.showDamageIndication( angle );
				}

				break;
		}

		return true;
	}

	/// Computes the angle between the current look direction and the attack direction in
	/// the range of [-π, π].
	double computeAngleToAttacker(Vector3 projectileDirection ) {
		attackDirection.copy( projectileDirection ).multiplyScalar( - 1 );
		attackDirection.y = 0; // project plane on (0,1,0) plane
		attackDirection.normalize();

		head.getWorldDirection( lookDirection );
		lookDirection.y = 0;
		lookDirection.normalize();

		// since both direction vectors lie in the same plane, use the following formula
		//
		// dot = a * b
		// det = n * (a x b)
		// angle = atan2(det, dot)
		//
		// Note: We can't use Vector3.angleTo() since the result is always in the range [0,π]

		final dot = attackDirection.dot( lookDirection );
		final det = up.dot( cross.crossVectors( attackDirection, lookDirection ) ); // triple product

		return math.atan2( det, dot );
	}
}
