import 'package:examples/playground/hideseek/enemy.dart';
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/weapons/weapon.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;

/// Class for representing a shotgun.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Shotgun extends Weapon {
  final _spread = Vector3();
  int bulletsPerShot = 0;
  double muzzleFireTime = 0;
  double spread = 0;
  double shotReloadTime = 0;
  double endTimeShotReload = 0;

	Shotgun( super.owner ) {
		type = ItemType.shotgun;

		// common weapon properties
		roundsLeft = config['SHOTGUN']['ROUNDS_LEFT'];
		roundsPerClip = config['SHOTGUN']['ROUNDS_PER_CLIP'];
		ammo = config['SHOTGUN']['AMMO'];
		maxAmmo = config['SHOTGUN']['MAX_AMMO'];

		shotTime = config['SHOTGUN']['SHOT_TIME'];
		reloadTime = config['SHOTGUN']['RELOAD_TIME'];
		equipTime = config['SHOTGUN']['EQUIP_TIME'];
		hideTime = config['SHOTGUN']['HIDE_TIME'];
		muzzleFireTime = config['SHOTGUN']['MUZZLE_TIME'];

		// shotgun specific properties
		bulletsPerShot = config['SHOTGUN']['BULLETS_PER_SHOT'];
		spread = config['SHOTGUN']['SPREAD'];

		shotReloadTime = config['SHOTGUN']['SHOT_RELOAD_TIME'];
		endTimeShotReload = double.infinity;
	}

	/// Update method of this weapon.
  @override
	Shotgun update(double delta ) {
		super.update( delta );

		// check reload after each shot
		if ( currentTime >= endTimeShotReload ) {
			endTimeShotReload = double.infinity;
		}

		// check reload of clip
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
	Shotgun reload() {
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
	Shotgun shoot(Vector3 targetPosition ) {
		status = WeaponStatus.shot;

		// animation
		if ( mixer != null ) {
			final animation = animations?['shot'];
			animation?.stop();
			animation?.play();
		}

		// muzzle fire
		muzzle?.visible = true;
		muzzle?.material?.rotation = math.Random().nextDouble() *math.pi;

		endTimeMuzzleFire = currentTime + muzzleFireTime;

		// create bullets
		final ray = Ray();

		getWorldPosition( ray.origin );
		ray.direction.subVectors( targetPosition, ray.origin ).normalize();

		for ( int i = 0; i < bulletsPerShot; i ++ ) {
			final r = ray.clone();

			_spread.x = ( 1 - math.Random().nextDouble() * 2 ) * spread;
			_spread.y = ( 1 - math.Random().nextDouble() * 2 ) * spread;
			_spread.z = ( 1 - math.Random().nextDouble() * 2 ) * spread;

			r.direction.add( _spread ).normalize();
      if(owner is Player) {
        (owner as Player).world.addBullet( owner, r );
      }
      else if(owner is Enemy){
        (owner as Enemy).world.addBullet( owner, r );
      }
		}

		// adjust ammo
		roundsLeft --;

		endTimeShotReload = currentTime + shotReloadTime;
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
	Shotgun initAnimations() {
		late final dynamic assetManager;
    if(owner is Player) {
      assetManager = (owner as Player).world.assetManager;
    }
    else if(owner is Enemy){
      assetManager = (owner as Enemy).world.assetManager;
    }

		final mixer = three.AnimationMixer( renderComponent );
		final animations = <String,three.AnimationAction?>{};

		final shotClip = assetManager.animations['shotgun_shot'];
		final reloadClip = assetManager.animations['shotgun_reload'];
		final hideClip = assetManager.animations['shotgun_hide'];
		final equipClip = assetManager.animations['shotgun_equip'];

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
