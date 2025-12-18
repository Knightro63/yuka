import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/weapons/weapon.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

/// Class for representing a assault rifle.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AssaultRifle extends Weapon {
  final _spread = Vector3();
  double muzzleFireTime = config['ASSAULT_RIFLE']['MUZZLE_TIME'];

	AssaultRifle( super.owner ) {
    type = WEAPON_TYPES_ASSAULT_RIFLE;
    roundsLeft = config['ASSAULT_RIFLE']['ROUNDS_LEFT'];
    roundsPerClip = config['ASSAULT_RIFLE']['ROUNDS_PER_CLIP'];
    ammo = config['ASSAULT_RIFLE']['AMMO'];
    maxAmmo = config['ASSAULT_RIFLE']['MAX_AMMO'];

    shotTime = config['ASSAULT_RIFLE']['SHOT_TIME'];
    reloadTime = config['ASSAULT_RIFLE']['RELOAD_TIME'];
    equipTime = config['ASSAULT_RIFLE']['EQUIP_TIME'];
    hideTime = config['ASSAULT_RIFLE']['HIDE_TIME'];
	}

	/// Update method of this weapon.
  @override
	AssaultRifle update(double delta ) {
		super.update( delta );

		// check reload
		if ( currentTime >= endTimeReload ) {
			final toReload = roundsPerClip - roundsLeft;

			if ( ammo >= toReload ) {
				roundsLeft = roundsPerClip;
				ammo -= toReload;
			} 
      else {
				roundsLeft += ammo;
				ammo = 0;
			}

			// update UI

			if ( owner is Player ) {
				(owner as Player).world.uiManager.updateAmmoStatus();
			}

			status = WEAPON_STATUS_READY;
			endTimeReload = double.infinity;
		}

		// check muzzle fire
		if ( currentTime >= endTimeMuzzleFire ) {
			muzzle?.visible = false;
			endTimeMuzzleFire = double.infinity;
		}

		// check shoot

		if ( currentTime >= endTimeShot ) {
			if ( roundsLeft == 0 ) {
				if ( ammo == 0 ) {
					status = WEAPON_STATUS_OUT_OF_AMMO;
				} 
        else {
					status = WEAPON_STATUS_EMPTY;
				}
			} 
      else {
				status = WEAPON_STATUS_READY;
			}

			endTimeShot = double.infinity;
		}

		return this;
	}

	/// Reloads the weapon.
  @override
	AssaultRifle reload() {
		status = WEAPON_STATUS_RELOAD;

		// animation
		if ( mixer != null) {
			final animation = animations?['reload'];
			animation?.stop();
			animation?.play();
		}

		endTimeReload = currentTime + reloadTime;
		return this;
	}

	/// Shoots at the given position.
  @override
	AssaultRifle shoot(Vector3 targetPosition ) {
		status = WEAPON_STATUS_SHOT;

		// animation
		if ( mixer != null) {
			final animation = animations?['shot'];
			animation?.stop();
			animation?.play();
		}

		// muzzle fire
		muzzle?.visible = true;
		muzzle?.material?.rotation = math.Random().nextDouble() *math.pi;

		endTimeMuzzleFire = currentTime + muzzleFireTime;

		// create bullet
		final ray = Ray();

		getWorldPosition( ray.origin );
		ray.direction.subVectors( targetPosition, ray.origin ).normalize();

		// add spread
		_spread.x = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;
		_spread.y = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;
		_spread.z = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;

		ray.direction.add( _spread ).normalize();

		// add bullet to world
    if(owner is Player) {
      (owner as Player).world.addBullet( owner, ray );
    }
    else if(owner is Enemy){
      (owner as Enemy).world.addBullet( owner, ray );
    }

		// adjust ammo
		roundsLeft --;
		endTimeShot = currentTime + shotTime;

		return this;
	}

	/// Returns a value representing the desirability of using the weapon.
  @override
	int getDesirability(double distance ) {
		fuzzyModule?.fuzzify( 'distanceToTarget', distance );
		fuzzyModule?.fuzzify( 'ammoStatus', roundsLeft.toDouble() );

		return fuzzyModule!.defuzzify( 'desirability' ) ~/ 100;
	}

	/// Inits animations for this weapon. Only used for the player.
	AssaultRifle initAnimations() {
		late final dynamic assetManager;
    if(owner is Player) {
      assetManager = (owner as Player).world.assetManager;
    }
    else if(owner is Enemy){
      assetManager = (owner as Enemy).world.assetManager;
    }

		final mixer = three.AnimationMixer( renderComponent );
		final animations = <String,three.AnimationAction?>{};

		final shotClip = assetManager.animations.get( 'assaultRifle_shot' );
		final reloadClip = assetManager.animations.get( 'assaultRifle_reload' );
		final hideClip = assetManager.animations.get( 'assaultRifle_hide' );
		final equipClip = assetManager.animations.get( 'assaultRifle_equip' );

		final shotAction = mixer.clipAction( shotClip );
		shotAction?.loop = three.LoopOnce;

		final reloadAction = mixer.clipAction( reloadClip );
		reloadAction?.loop = three.LoopOnce;

		final hideAction = mixer.clipAction( hideClip );
		hideAction?.loop = three.LoopOnce;
		hideAction?.clampWhenFinished = true;

		final equipAction = mixer.clipAction( equipClip );
		equipAction?.loop = three.LoopOnce;

		animations['shot'] = shotAction;
		animations['reload'] = reloadAction;
		animations['hide'] = hideAction;
		animations['equip'] = equipAction;

		this.animations = animations;
		this.mixer = mixer;

		return this;
	}
}
