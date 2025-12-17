import 'package:examples/showcase/dive/entities/item.dart';
import 'package:yuka/yuka.dart';

/// A game entity which represents a collectable weapon item.
///
/// @author {@link https://github.com/robp94|robp94}
class WeaponItem extends Item {
  int ammo;

	WeaponItem(super.type, super.respawnTime,this.ammo );

	/// Adds the weapon to the given entity.
  @override
	WeaponItem addItemToEntity(GameEntity entity ) {
		entity.addWeapon( type );
		return this;
	}
}
