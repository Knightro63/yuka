import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/weapons/assault_rifle.dart';
import 'package:examples/showcase/dive/weapons/blaster.dart';
import 'package:examples/showcase/dive/weapons/shotgun.dart';
import 'package:examples/showcase/dive/weapons/weapon.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

/// Class to manage all operations specific to weapons and their deployment.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class WeaponSystem {
  final displacement = Vector3();
  final targetPosition = Vector3();
  final offset = Vector3();

  final GameEntity owner;
  List weapons = [];
  Map weaponsMap = {};

  double reactionTime = config['BOT']['WEAPON']['REACTION_TIME'];
  double aimAccuracy = config['BOT']['WEAPON']['AIM_ACCURACY'];

  final Map<String,dynamic> renderComponents = {
    'blaster': {
      'mesh': null,
      'muzzle': null
    },
    'shotgun': {
      'mesh': null,
      'muzzle': null
    },
    'assaultRifle': {
      'mesh': null,
      'muzzle': null
    }
  };

  final Map<String,FuzzyModule?> fuzzyModules = {
    'blaster': null,
    'shotGun': null,
    'assaultRifle': null
  };

  ItemType? nextItemType;
  Weapon? currentWeapon;

	WeaponSystem( this.owner ) {
	  weaponsMap[ItemType.blaster] = null;
		weaponsMap[ItemType.shotgun] = null;
		weaponsMap[ItemType.assaultRifle] = null;
	}

	/// Inits the weapon system. Should be called once during the creation
	/// or startup process of an entity.
	WeaponSystem init(){
		// init render components
		_initRenderComponents();

		// init fuzzy modules (only necessary for bots)
		if (owner is! Player) {
			_initFuzzyModules();
		}

		// reset the system to its initial state
		reset();

		return this;
	}

	/// Resets the internal data structures and sets an initial weapon.
	WeaponSystem reset() {
		// remove existing weapons if necessary
		for ( int i = (weapons.length - 1 ); i >= 0; i -- ) {
			final weapon = weapons[ i ];
			removeWeapon( weapon.type );
		}

		// add weapons to inventory
		addWeapon( ItemType.blaster );

		// change to initial weapon
		changeWeapon( ItemType.blaster );

		// reset next weapon
		nextItemType = null;

		// the initial weapon is always ready to use
		currentWeapon?.status = WeaponStatus.ready;

		return this;
	}

	/// Determines the most appropriate weapon to use given the current game state.
	WeaponSystem selectBestWeapon() {
		final dynamic owner = this.owner;
		final target = owner.targetSystem.getTarget();

		if ( target != null) {
			double highestDesirability = 0;
			ItemType bestItemType = ItemType.blaster;

			// calculate the distance to the target
			final distanceToTarget = this.owner.position.distanceTo( target.position );

			// for each weapon in the inventory calculate its desirability given the
			// current situation. The most desirable weapon is selected
			for ( int i = 0, l = weapons.length; i < l; i ++ ) {
				final Weapon weapon = weapons[ i ];

				double desirability = ( weapon.roundsLeft == 0 ) ? 0.0 : weapon.getDesirability( distanceToTarget ).toDouble();

				// if weapon is different than currentWeapon, decrease the desirability in order to respect the
				// cost of changing a weapon
				if ( currentWeapon != weapon ) desirability -= config['BOT']['WEAPON']['CHANGE_COST'];

				//
				if ( desirability > highestDesirability ) {
					highestDesirability = desirability;
					bestItemType = weapon.type!;
				}
			}

			// select the best weapon
			setNextWeapon( bestItemType );
		}

		return this;
	}

 /// Changes the current weapon to one of the specified type.
	WeaponSystem changeWeapon( ItemType type ) {
		final weapon = weaponsMap[type];

		if ( weapon != null ) {
			currentWeapon = weapon;

			// adjust render components. only a single weapon can be visible
			switch ( weapon.type ) {
				case ItemType.blaster:
					renderComponents['blaster']['mesh']?.visible = true;
					renderComponents['shotgun']['mesh']?.visible = false;
					renderComponents['assaultRifle']['mesh']?.visible = false;
					if ( owner is Player ) weapon.setRenderComponent( renderComponents['blaster']['mesh'], sync );
					break;

				case ItemType.shotgun:
					renderComponents['blaster']['mesh']?.visible = false;
					renderComponents['shotgun']['mesh']?.visible = true;
					renderComponents['assaultRifle']['mesh']?.visible = false;
					if ( owner is Player ) weapon.setRenderComponent( renderComponents['shotgun']['mesh'], sync );
					break;

				case ItemType.assaultRifle:
					renderComponents['blaster']['mesh']?.visible = false;
					renderComponents['shotgun']['mesh']?.visible = false;
					renderComponents['assaultRifle']['mesh']?.visible = true;
					if ( owner is Player ) weapon.setRenderComponent( renderComponents['assaultRifle']['mesh'], sync );
					break;

				default:
					yukaConsole.error( 'DIVE.WeaponSystem: Invalid weapon type: $type' );
					break;
			}
		}

		return this;
	}

	/// Adds a weapon of the specified type to the bot's inventory.
	/// If the bot already has a weapon of this type only the ammo is added.
	WeaponSystem addWeapon( ItemType type ) {
		final dynamic owner = this.owner;
		late Weapon weapon;

		switch ( type ) {
			case ItemType.blaster:
				weapon = Blaster( owner );
				weapon.fuzzyModule = fuzzyModules['blaster'];
				weapon.muzzle = renderComponents['blaster']['muzzle'];
				break;

			case ItemType.shotgun:
				weapon = Shotgun( owner );
				weapon.fuzzyModule = fuzzyModules['shotGun'];
				weapon.muzzle = renderComponents['shotgun']['muzzle'];
				break;

			case ItemType.assaultRifle:
				weapon = AssaultRifle( owner );
				weapon.fuzzyModule = fuzzyModules['assaultRifle'];
				weapon.muzzle = renderComponents['assaultRifle']['muzzle'];
				break;

			default:
				yukaConsole.error( 'DIVE.WeaponSystem: Invalid weapon type: $type' );
				break;
		}

		// check inventory
		final weaponInventory = weaponsMap['type'];

		if ( weaponInventory != null ) {
			// if the bot already holds a weapon of this type, just add its ammo
			weaponInventory.addRounds( weapon.getRemainingRounds() );
		} 
    else {
			// if not already present, add to inventory
			weaponsMap[type] = weapon;
			weapons.add( weapon );

			// also add it to owner entity so the weapon is correctly updated by
			// the entity manager
			owner.weaponContainer.add( weapon );

			if ( owner is Player ) {
				//weapon.scale[2] = 22;
				weapon.position.set(0.3, - 0.3, - 1 );
				weapon.rotation.fromEuler( 0,math.pi, 0 );
			} 
      else {
				weapon.position.set(-0.2, - 0.2, 0.5 );
			}
		}

		return this;
	}

	/// Removes the specified weapon type from the bot's inventory.
	WeaponSystem removeWeapon(ItemType type ) {
		final dynamic owner = this.owner;
		final weapon = weaponsMap[type];

		if ( weapon != null) {
			weaponsMap[type] = null;
			final index = weapons.indexOf( weapon );
			weapons.removeAt( index );
			owner.weaponContainer.remove( weapon );
		}

    return this;
	}

	/// Sets the next weapon type the owner should use.
	WeaponSystem setNextWeapon(ItemType type ) {
		// no need for action if the current weapon is already of the given type
		if ( currentWeapon?.type != type ) {
			nextItemType = type;
		}

		return this;
	}

	/// Returns the weapon of the given type. If no weapon is present, null is returned.
	Weapon? getWeapon( ItemType type ) {
		return weaponsMap[type];
	}

	/// Ensures that the current equiped weapon is rendered.
	WeaponSystem showCurrentWeapon() {
		final type = currentWeapon?.type;

		switch ( type ) {
			case ItemType.blaster:
				renderComponents['blaster']['mesh'].visible = true;
				break;
			case ItemType.shotgun:
				renderComponents['shotgun']['mesh'].visible = true;
				break;
			case ItemType.assaultRifle:
				renderComponents['assaultRifle']['mesh'].visible = true;
				break;
			default:
				yukaConsole.error( 'DIVE.WeaponSystem: Invalid weapon type: $type' );
				break;
		}

		return this;
	}

	/// Ensures that the current equipped weapon is not rendered.
	WeaponSystem hideCurrentWeapon() {
		final type = currentWeapon?.type;

		switch ( type ) {
			case ItemType.blaster:
				renderComponents['blaster']['mesh'].visible = false;
				break;
			case ItemType.shotgun:
				renderComponents['shotgun']['mesh'].visible = false;
				break;
			case ItemType.assaultRifle:
				renderComponents['assaultRifle']['mesh'].visible = false;
				break;
			default:
				yukaConsole.error( 'DIVE.WeaponSystem: Invalid weapon type: $type' );
				break;
		}

		return this;
	}

	/// Returns the amount of ammo remaining for the specified weapon.
	int getRemainingAmmoForWeapon(ItemType type ) {
		final Weapon? weapon = weaponsMap[type ];
		return weapon?.getRemainingRounds() ?? 0;
	}

	/// Updates method of the weapon system. Called each simulation step if the owner is alive.
	WeaponSystem update(double delta ) {
		updateWeaponChange();
		updateAimAndShot( delta );

		return this;
	}

	/// Updates weapon changing logic.
	WeaponSystem updateWeaponChange() {
		if ( nextItemType != null ) {

			// if the current weapon is in certain states, hide it in order to start the weapon change
			if ( currentWeapon?.status == WeaponStatus.ready ||
					currentWeapon?.status == WeaponStatus.empty ||
					currentWeapon?.status == WeaponStatus.outOfAmmo ) {

				currentWeapon?.hide();
			}

			// as soon as the current weapon becomes unready, change to the defined next weapon type

			if ( currentWeapon?.status == WeaponStatus.unready ) {
				changeWeapon( nextItemType! );
				currentWeapon?.equip();
				nextItemType = null;
			}
		}

		return this;
	}

	/// Updates the aiming and shooting of the enemy.
	WeaponSystem updateAimAndShot(double delta ) {
		final dynamic owner = this.owner;
		final targetSystem = owner.targetSystem;
		final target = targetSystem.getTarget();

		if ( target != null) {
			// if the target is visible, directly rotate towards it and then
			// fire a round

			if ( targetSystem.isTargetShootable() ) {
				// stop search for the attacker if the target is shootable

				owner.resetSearch();

				// the bot can fire a round if it is headed towards its target
				// and after a certain reaction time
				final targeted = owner.rotateTo( target.position, delta, 0.05 ); // "targeted" is true if the enemy is faced to the target
				final timeBecameVisible = targetSystem.getTimeBecameVisible();
				final elapsedTime = (owner.world.time as Time).elapsed;

				if ( targeted == true && ( elapsedTime - timeBecameVisible ) >= reactionTime ) {
					target.bounds.getCenter( targetPosition );
					addNoiseToAim( targetPosition );
					shoot( targetPosition );
				}
			} 
			else {
				// the target might not be shootable but the enemy is still attacked.
				// in this case, search for the attacker
				if ( owner.searchAttacker ) {
					targetPosition.copy( owner.position ).add( owner.attackDirection );
					owner.rotateTo( targetPosition, delta );
				} else {
					// otherwise rotate to the latest recorded position
					owner.rotateTo( targetSystem.getLastSensedPosition(), delta );
				}
			}
		} 
		else {
			// if the enemy has no target, look for an attacker if necessary
			if ( owner.searchAttacker ) {
				targetPosition.copy( owner.position ).add( owner.attackDirection );
				owner.rotateTo( targetPosition, delta );
			} 
			else {
				// if the enemy has no target and is not being attacked, just look along
				// the movement direction
				displacement.copy( owner.velocity ).normalize();
				targetPosition.copy( owner.position ).add( displacement );
				owner.rotateTo( targetPosition, delta );

			}
		}

		return this;
	}

	/// Ensures the enemy does not perfectly aim at the given target position. It
	/// alters the target position by a certain offset. The offset proportionally
	// increases with the distance between the owner of the weapon and its target.
	Vector3 addNoiseToAim( Vector3 targetPosition ) {
		final distance = owner.position.distanceTo( targetPosition );

		offset.x = MathUtils.randFloat( - aimAccuracy, aimAccuracy );
		offset.y = MathUtils.randFloat( - aimAccuracy, aimAccuracy );
		offset.z = MathUtils.randFloat( - aimAccuracy, aimAccuracy );

		final maxDistance = config['BOT']['WEAPON']['NOISE_MAX_DISTANCE']; // this distance produces the maximum amount of offse/noise
		final f = math.min( distance, maxDistance ) / maxDistance;

		targetPosition.add( offset.multiplyScalar( f ) );

		return targetPosition;
	}

	/// Shoots at the given position with the current weapon.
	WeaponSystem shoot( Vector3 targetPosition ) {
		final currentWeapon = this.currentWeapon;
		final status = currentWeapon?.status;

		switch ( status ) {
			case WeaponStatus.empty:
				currentWeapon?.reload();
				break;
			case WeaponStatus.ready:
				currentWeapon?.shoot( targetPosition );
				break;
			default:
				break;
		}

		return this;
	}

	/// Reloads the current weapon.
	WeaponSystem reload() {
		final currentWeapon = this.currentWeapon;
		if ( currentWeapon?.status == WeaponStatus.ready || currentWeapon?.status == WeaponStatus.empty ) {
			currentWeapon?.reload();
		}

    if(owner is Player) (owner as Player).world.updateUI();

		return this;
	}

	/// Inits the render components of all weapons. Each enemy and the player
	/// need a set of individual render components.
	WeaponSystem _initRenderComponents() {
		_initBlasterRenderComponent();
		_initShotgunRenderComponent();
		_initAssaultRifleRenderComponent();

		return this;
	}

	/// Inits the render components for the blaster.
	WeaponSystem _initBlasterRenderComponent() {
		final dynamic owner = this.owner;
		final assetManager = owner.world.assetManager;

		// setup copy of blaster mesh
		three.Object3D? blasterMesh;

		if (owner is! Player ) {
			// pick the low resolution model for the enemies
			blasterMesh = assetManager.models['blaster_low']?.clone();
			blasterMesh?.scale.setValues(100,100,100 );
			blasterMesh?.rotation.set(math.pi * 0.5,math.pi, 0 );
			blasterMesh?.position.setValues(0.1, 5, 5);
			blasterMesh?.updateMatrix();

			// add the mesh to the right hand of the enemy

			final rightHand = (owner.renderComponent as three.Object3D?)?.getObjectByName( 'Armature_mixamorigRightHand' );
			rightHand?.add( blasterMesh );
		} 
		else {
			blasterMesh = assetManager.models['blaster_high'];
			owner.world.scene.add( blasterMesh );
		}

		// add muzzle sprite to the blaster mesh

		final three.Object3D? muzzleSprite = assetManager.models['muzzle']?.clone();
		muzzleSprite?.material = muzzleSprite.material?.clone(); // this is necessary since Mesh.clone() is not deep and SpriteMaterial.rotation is going to be changed
		muzzleSprite?.position.setValues(0.05, 0.2 );
		muzzleSprite?.scale.setValues(0.3, 0.3, 0.3 );
		muzzleSprite?.updateMatrix();
		blasterMesh?.add( muzzleSprite );

		// store this configuration		
    renderComponents['blaster'] = {
      'mesh' : blasterMesh,
		  'muzzle': muzzleSprite
    };

		return this;
	}

	/// Inits the render components for the shotgun.
	WeaponSystem _initShotgunRenderComponent() {
		final dynamic owner = this.owner;
		final assetManager = owner.world.assetManager;

		// setup copy of shotgun mesh
		three.Object3D? shotgunMesh;

		if (owner is Player == false ) {
			// pick the low resolution model for the enemies
			shotgunMesh = assetManager.models['shotgun_low']?.clone();

			shotgunMesh?.scale.setValues(100,100,100 );
			shotgunMesh?.rotation.set(math.pi * 0.5,math.pi * 1.05, 0 );
			shotgunMesh?.position.setValues(-5, 30, 2 );
			shotgunMesh?.updateMatrix();

			// add the mesh to the right hand of the enemy
			final rightHand = (owner.renderComponent as three.Object3D?)?.getObjectByName( 'Armature_mixamorigRightHand' );
			rightHand?.add( shotgunMesh );
		} 
		else {
			shotgunMesh = assetManager.models['shotgun_high'];
			owner.world.scene.add( shotgunMesh );
		}

		// add muzzle sprite
		final three.Object3D? muzzleSprite = assetManager.models['muzzle']?.clone();
		muzzleSprite?.material = muzzleSprite.material?.clone();
		muzzleSprite?.position.setValues(0.05, 0.3 );
		muzzleSprite?.scale.setValues(0.4, 0.4, 0.4 );
		muzzleSprite?.updateMatrix();
		shotgunMesh?.add( muzzleSprite );

		// store this configuration
		renderComponents['shotgun']= {
      'mesh' : shotgunMesh,
		  'muzzle': muzzleSprite
    };

		return this;
	}

	/// Inits the render components for the assault rifle.
	WeaponSystem _initAssaultRifleRenderComponent() {
		final dynamic owner = this.owner;
		final assetManager = owner.world.assetManager;

		// setup copy of assault rifle mesh
		three.Object3D? assaultRifleMesh;

		if (owner is! Player ) {
			// pick the low resolution model for the enemies
			assaultRifleMesh = assetManager.models['assaultRifle_low']?.clone();

			assaultRifleMesh?.scale.setValues(100, 100, 100 );
			assaultRifleMesh?.rotation.set(math.pi * 0.5,math.pi * 1, 0 );
			assaultRifleMesh?.position.setValues(-5, 20, 7 );
			assaultRifleMesh?.updateMatrix();

			// add the mesh to the right hand of the enemy
			final rightHand = (owner.renderComponent as three.Object3D?)?.getObjectByName( 'Armature_mixamorigRightHand' );
			rightHand?.add( assaultRifleMesh );
		} 
		else {
			assaultRifleMesh = assetManager.models['assaultRifle_high'];
			owner.world.scene.add( assaultRifleMesh );
		}

		// add muzzle sprite
		final three.Object3D? muzzleSprite = assetManager.models['muzzle']?.clone();
		muzzleSprite?.material = muzzleSprite.material?.clone();
		muzzleSprite?.position.setValues(0,0,0.5 );
		muzzleSprite?.scale.setValues(0.4, 0.4, 0.4 );
		muzzleSprite?.updateMatrix();
		assaultRifleMesh?.add( muzzleSprite );

		// store this configuration
		renderComponents['assaultRifle'] = {
      'mesh' : assaultRifleMesh,
		  'muzzle': muzzleSprite
    };

		return this;
	}

	/// Inits the fuzzy modules for all weapons.
	WeaponSystem _initFuzzyModules() {
		fuzzyModules['assaultRifle'] = FuzzyModule();
		fuzzyModules['blaster'] = FuzzyModule();
		fuzzyModules['shotGun'] = FuzzyModule();

		final fuzzyModuleAssaultRifle = fuzzyModules['assaultRifle'];
		final fuzzyModuleBlaster = fuzzyModules['blaster'];
		final fuzzyModuleShotGun = fuzzyModules['shotGun'];

		// the following FLVs are equal for all modules
		// FLV distance to target
		final distanceToTarget = FuzzyVariable();

		final targetClose = LeftShoulderFuzzySet( 0, 10, 20 );
		final targetMedium = TriangularFuzzySet( 10, 20, 40 );
		final targetFar = RightShoulderFuzzySet( 20, 40, 1000 );

		distanceToTarget.add( targetClose );
		distanceToTarget.add( targetMedium );
		distanceToTarget.add( targetFar );

		// FLV desirability
		final desirability = FuzzyVariable();
		final undesirable = LeftShoulderFuzzySet( 0, 25, 50 );
		final desirable = TriangularFuzzySet( 25, 50, 75 );
		final veryDesirable = RightShoulderFuzzySet( 50, 75, 100 );

		desirability.add( undesirable );
		desirability.add( desirable );
		desirability.add( veryDesirable );

		//
		fuzzyModuleAssaultRifle?.addFLV( 'desirability', desirability );
		fuzzyModuleAssaultRifle?.addFLV( 'distanceToTarget', distanceToTarget );

		fuzzyModuleBlaster?.addFLV( 'desirability', desirability );
		fuzzyModuleBlaster?.addFLV( 'distanceToTarget', distanceToTarget );

		fuzzyModuleShotGun?.addFLV( 'desirability', desirability );
		fuzzyModuleShotGun?.addFLV( 'distanceToTarget', distanceToTarget );

		//
		final Map<String,FuzzySet> fuzzySets = {
			'targetClose': targetClose,
			'targetMedium': targetMedium,
			'targetFar': targetFar,
			'undesirable': undesirable,
			'desirable': desirable,
			'veryDesirable': veryDesirable
		};

		_initAssaultRifleFuzzyModule( fuzzySets );
		_initBlasterFuzzyModule( fuzzySets );
		_initShotgunFuzzyModule( fuzzySets );

		return this;
	}

	/// Inits the fuzzy module for the blaster.
	WeaponSystem _initBlasterFuzzyModule( Map<String,FuzzySet> fuzzySets ) {
		// FLV ammo status
		final fuzzyModuleBlaster = fuzzyModules['blaster'];
		final ammoStatusBlaster = FuzzyVariable();

		final lowBlaster = LeftShoulderFuzzySet( 0, 8, 15 );
		final okayBlaster = TriangularFuzzySet( 8, 20, 30 );
		final loadsBlaster = RightShoulderFuzzySet( 20, 30, 48 );

		ammoStatusBlaster.add( lowBlaster );
		ammoStatusBlaster.add( okayBlaster );
		ammoStatusBlaster.add( loadsBlaster );

		fuzzyModuleBlaster?.addFLV( 'ammoStatus', ammoStatusBlaster );

		// rules

		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, lowBlaster ]), fuzzySets['undesirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, okayBlaster] ), fuzzySets['desirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, loadsBlaster] ), fuzzySets['desirable'] ) );

		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, lowBlaster] ), fuzzySets['desirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, okayBlaster] ), fuzzySets['desirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, loadsBlaster] ), fuzzySets['desirable'] ) );

		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, lowBlaster ]), fuzzySets['desirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, okayBlaster] ), fuzzySets['desirable'] ) );
		fuzzyModuleBlaster?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, loadsBlaster] ), fuzzySets['desirable'] ) );

		return this;

	}

	/// Inits the fuzzy module for the shotgun.
	WeaponSystem _initShotgunFuzzyModule( Map<String,FuzzySet> fuzzySets ) {
		// FLV ammo status
		final fuzzyModuleShotGun = fuzzyModules['shotGun'];
		final ammoStatusShotgun = FuzzyVariable();

		final lowShot = LeftShoulderFuzzySet( 0, 2, 4 );
		final okayShot = TriangularFuzzySet( 2, 7, 10 );
		final loadsShot = RightShoulderFuzzySet( 7, 10, 12 );

		ammoStatusShotgun.add( lowShot );
		ammoStatusShotgun.add( okayShot );
		ammoStatusShotgun.add( loadsShot );

		fuzzyModuleShotGun?.addFLV( 'ammoStatus', ammoStatusShotgun );

		// rules

		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, lowShot] ), fuzzySets['desirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, okayShot] ), fuzzySets['veryDesirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, loadsShot] ), fuzzySets['veryDesirable'] ) );

		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, lowShot ]), fuzzySets['undesirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, okayShot] ), fuzzySets['undesirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, loadsShot] ), fuzzySets['desirable'] ) );

		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, lowShot] ), fuzzySets['undesirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, okayShot] ), fuzzySets['undesirable'] ) );
		fuzzyModuleShotGun?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, loadsShot] ), fuzzySets['undesirable'] ) );

		return this;

	}

	/// Inits the fuzzy module for the assault rifle.
	WeaponSystem _initAssaultRifleFuzzyModule(Map<String,FuzzySet> fuzzySets ) {
		// FLV ammo status
		final fuzzyModuleAssaultRifle = fuzzyModules['assaultRifle'];
		final ammoStatusAssaultRifle = FuzzyVariable();

		final lowAssault = LeftShoulderFuzzySet( 0, 2, 8 );
		final okayAssault = TriangularFuzzySet( 2, 10, 20 );
		final loadsAssault = RightShoulderFuzzySet( 10, 20, 30 );

		ammoStatusAssaultRifle.add( lowAssault );
		ammoStatusAssaultRifle.add( okayAssault );
		ammoStatusAssaultRifle.add( loadsAssault );

		fuzzyModuleAssaultRifle?.addFLV( 'ammoStatus', ammoStatusAssaultRifle );

		// rules
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, lowAssault] ), fuzzySets['undesirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, okayAssault] ), fuzzySets['desirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetClose']!, loadsAssault] ), fuzzySets['desirable'] ) );

		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, lowAssault] ), fuzzySets['desirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, okayAssault] ), fuzzySets['veryDesirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, loadsAssault] ), fuzzySets['veryDesirable'] ) );

		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetMedium']!, lowAssault ]), fuzzySets['desirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, okayAssault] ), fuzzySets['veryDesirable'] ) );
		fuzzyModuleAssaultRifle?.addRule( FuzzyRule( FuzzyAND( [fuzzySets['targetFar']!, loadsAssault] ), fuzzySets['veryDesirable'] ) );

		return this;
	}

  void sync(GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}


