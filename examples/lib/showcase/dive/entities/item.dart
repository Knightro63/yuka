import 'package:yuka/yuka.dart';

/// A game entity which represents a collectable item.
///
/// @author {@link https://github.com/robp94|robp94}
abstract class Item extends GameEntity {
  double respawnTime;
  double nextSpawnTime = double.infinity;
  double currentTime = 0;
  int type;
  List<Polygon>? currentRegion;

	Item( this.type, this.respawnTime ):super() {
    canActivateTrigger = false;
	}

	/// Prepares the respawn of this item.
	Item prepareRespawn( ) {
		active = false;
		renderComponent.visible = false;
		nextSpawnTime = currentTime + respawnTime;
		return this;
	}

	/// Finishes the respawn of this item.
	Item finishRespawn() {
		active = true;
		renderComponent.visible = true;
		nextSpawnTime = double.infinity;
		return this;
	}

	/// Abstract method that has to be implemented by all concrete item types. It is
	/// typically executed by a trigger.
	Item addItemToEntity(GameEntity entity);
}