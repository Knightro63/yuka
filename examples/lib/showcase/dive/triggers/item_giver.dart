import 'package:examples/showcase/dive/entities/item.dart';
import 'package:yuka/yuka.dart';

/// Gives an entity an item if it touches the trigger region.
///
/// @author {@link https://github.com/robp94|robp94}
class ItemGiver extends Trigger {
  final Item item;
	ItemGiver( super.region, this.item );

	/// This method is called when the trigger should execute its action.
  @override
	Trigger execute(GameEntity entity ) {
		final item = this.item;

		// deactivate trigger since it's only executed once
		active = false;

		// add item to entity
		item.addItemToEntity( entity );

		// prepare respawn
		item.prepareRespawn();

		return this;
	}
}
