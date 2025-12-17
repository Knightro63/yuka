import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/item.dart';
import 'package:yuka/yuka.dart';

/// A game entity which represents a collectable health pack.
///
/// @author {@link https://github.com/robp94|robp94}
class HealthPack extends Item {
  int health = config['HEALTH_PACK']['HEALTH'];
  
	HealthPack():super( HEALTH_PACK, config['HEALTH_PACK']['RESPAWN_TIME'] );

	/// Adds the health to the given entity.
  @override
	HealthPack addItemToEntity(GameEntity entity ) {
		entity.addHealth( health ); // we assume .addHealth() is implemented by the game entity
		return this;
	}
}
