import 'package:examples/showcase/dive/core/asset_manager.dart';
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/weapons/weapon.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;

/// Class for representing a blaster.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Blaster extends Weapon {
  final spread = Vector3();
  double muzzleFireTime = 0;

	Blaster( super.owner ) {
		type = ItemType.blaster;

		// common weapon properties
		roundsLeft = config['BLASTER']['ROUNDS_LEFT'];
		roundsPerClip = config['BLASTER']['ROUNDS_PER_CLIP'];
		ammo = config['BLASTER']['AMMO'];
		maxAmmo = config['BLASTER']['MAX_AMMO'];

		shotTime = config['BLASTER']['SHOT_TIME'];
		reloadTime = config['BLASTER']['RELOAD_TIME'];
		equipTime = config['BLASTER']['EQUIP_TIME'];
		hideTime = config['BLASTER']['HIDE_TIME'];
		muzzleFireTime = config['BLASTER']['MUZZLE_TIME'];

    initAnimations();
	}

	/// Update method of this weapon./
  @override
	Blaster update(double delta ) {
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

			status = WeaponStatus.ready;
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
					status = WeaponStatus.outOfAmmo;
				} 
        else {
					status = WeaponStatus.empty;
				}
			} 
      else {
				status = WeaponStatus.ready;
			}

			endTimeShot = double.infinity;
		}

		return this;
	}

	/// Reloads the weapon.
  @override
	Blaster reload() {
		status = WeaponStatus.reload;

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
	Blaster shoot( Vector3 targetPosition ) {
		status = WeaponStatus.shot;

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

		spread.x = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;
		spread.y = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;
		spread.z = ( 1 - math.Random().nextDouble() * 2 ) * 0.01;

		ray.direction.add( spread ).normalize();

		// add bullet to world
    if(owner is Player) {
      (owner as Player).world.addBullet( owner, ray );
      (owner as Player).world.updateUI();
    }
    else if(owner is Enemy){
      (owner as Enemy).world.addBullet( owner, ray );
    }

		// adjust amm
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
	Blaster initAnimations() {
		late final AssetManager assetManager;
    if(owner is Player) {
      assetManager = (owner as Player).world.assetManager!;
    }
    else if(owner is Enemy){
      assetManager = (owner as Enemy).world.assetManager!;
    }
    
		final mixer = three.AnimationMixer( assetManager.models['blaster_high'] );
		final animations = <String,three.AnimationAction?>{};

		final shotClip = assetManager.animations['blaster_shot'];
		final reloadClip = assetManager.animations['blaster_reload'];
		final hideClip = assetManager.animations['blaster_hide'];
		final equipClip = assetManager.animations['blaster_equip'];

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
