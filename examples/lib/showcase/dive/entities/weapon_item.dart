import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:examples/showcase/dive/entities/item.dart';
import 'package:examples/showcase/dive/entities/player.dart';
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
		if(entity is Player) entity.addWeapon( type );
    if(entity is Enemy) entity.addWeapon( type );
		return this;
	}
}
