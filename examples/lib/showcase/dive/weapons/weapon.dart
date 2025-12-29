import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

/// Base class for all weapons.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
abstract class Weapon extends GameEntity {
  GameEntity owner;
  ItemType? type;

  int roundsLeft = 0;
  int roundsPerClip = 0;
  int ammo = 0;
  int maxAmmo = 0;

  double currentTime = 0;

  double shotTime = double.infinity;
  double reloadTime = double.infinity;
  double equipTime = double.infinity;
  double hideTime = double.infinity;

  double endTimeShot = double.infinity;
  double endTimeReload = double.infinity;
  double endTimeEquip = double.infinity;
  double endTimeHide = double.infinity;
  double endTimeMuzzleFire = double.infinity;

  three.AnimationMixer? mixer;
  Map<String,three.AnimationAction?>? animations;

	WeaponStatus status = WeaponStatus.unready;
	WeaponStatus previousState = WeaponStatus.ready;

  FuzzyModule? fuzzyModule;
  three.Object3D? muzzle;

	Weapon(this.owner ):super() {
		canActivateTrigger = false;
	}

	/// Adds the given amount of rounds to the ammo.
	Weapon addRounds(int rounds ) {
		ammo = MathUtils.clampInt( ammo + rounds, 0, maxAmmo );
		return this;
	}

	/// Returns the remaining rounds/ammo of this weapon.
	int getRemainingRounds() {
		return ammo;
	}

	/// Returns a value representing the desirability of using the weapon.
	int getDesirability(double distance) {
		return 0;
	}

	/// Equips the weapon.
	Weapon equip() {
		status = WeaponStatus.equip;
		endTimeEquip = currentTime + equipTime;

		if ( mixer != null) {
			three.AnimationAction? animation = animations?['hide'];
			animation?.stop();

			animation = animations?['equip'];
			animation?.stop();
			animation?.play();
		}

		if ( owner is Player ) {
			(owner as Player).world.uiManager.updateAmmoStatus();
		}

		return this;
	}

	/// Hides the weapon.
	Weapon hide() {
		previousState = status;
		status = WeaponStatus.hide;
		endTimeHide = currentTime + hideTime;

		if ( mixer != null) {
			final animation = animations?['hide'];
			animation?.stop();
			animation?.play();
		}

		return this;
	}

	/// Reloads the weapon.
	Weapon reload();

	/// Shoots at the given position.
	Weapon shoot(Vector3 targetPosition);

	/// Update method of this weapon.
  @override
	Weapon update(double delta ) {
		currentTime += delta;

		if ( currentTime >= endTimeEquip ) {
			status = previousState; // restore previous state
			endTimeEquip = double.infinity;
		}

		if ( currentTime >= endTimeHide ) {
			status = WeaponStatus.unready;
			endTimeHide = double.infinity;
		}

		// update animations
		mixer?.update( delta );

		return this;
	}
}
