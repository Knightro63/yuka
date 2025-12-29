import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/core/weapon_system.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:yuka/yuka.dart';

final result = <String,dynamic>{ 'distance': double.infinity, 'item': null };

/// Class for calculating influencing factors in context of inference logic.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class Feature {
	/// Computes the total weapon score.
	static double totalWeaponStrength(Enemy enemy ) {
		final WeaponSystem weaponSystem = enemy.weaponSystem;

		final ammoBlaster = weaponSystem.getRemainingAmmoForWeapon( ItemType.blaster );
		final ammoShotgun = weaponSystem.getRemainingAmmoForWeapon( ItemType.shotgun );
		final ammoAssaultRifle = weaponSystem.getRemainingAmmoForWeapon( ItemType.assaultRifle );

		final f1 = ammoBlaster / config['BLASTER']['MAX_AMMO'];
		final f2 = ammoShotgun / config['SHOTGUN']['MAX_AMMO'];
		final f3 = ammoAssaultRifle / config['ASSAULT_RIFLE']['MAX_AMMO'];

		return ( f1 + f2 + f3 ) / 3;
	}

	/// Computes the individual weapon score.
	static double individualWeaponStrength(Enemy enemy, ItemType ItemType ) {
		final weapon = enemy.weaponSystem.getWeapon( ItemType );
		return ( weapon != null) ? ( weapon.ammo / weapon.maxAmmo ) : 0;
	}

	/// Computes the health score.
	static double health(Enemy enemy ) {
		return enemy.health / enemy.maxHealth;
	}

	/// Computes a score between 0 and 1 based on the bot's closeness to the given item.
	/// The further the item, the higher the rating. If there is no item of the given type
	/// present in the game world at the time this method is called the value returned is 1.
	static double distanceToItem(Enemy enemy, ItemType itemType ) {
		double score = 1;
		enemy.world.getClosestItem( enemy, itemType, result );

		if ( result['item'] != null) {
			double distance = result['distance']!;
			distance = MathUtils.clamp( distance, config['BOT']['MIN_ITEM_RANGE'], config['BOT']['MAX_ITEM_RANGE'] );
			score = distance / config['BOT']['MAX_ITEM_RANGE'];
		}

		return score;
	}
}
