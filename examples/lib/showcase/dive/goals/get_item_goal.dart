import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/entities/item.dart';
import 'package:examples/showcase/dive/goals/find_path_goal.dart';
import 'package:examples/showcase/dive/goals/follow_path_goal.dart';
import 'package:yuka/yuka.dart';

/// Goal to get an item of the given item type.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class GetItemGoal extends CompositeGoal {
  final Map<String,dynamic> result = { 'distance': double.infinity, 'item': null };
  Item? item;
  ItemType? itemType;
  final regulator = Regulator( config['BOT']['GOAL']['ITEM_VISIBILITY_UPDATE_FREQUENCY'] );

	GetItemGoal( super.owner, [this.itemType, this.item]);

  @override
	void activate() {
		final dynamic owner = this.owner;

		// if this goal is reactivated then there may be some existing subgoals that must be removed
		clearSubgoals();

		// get closest available item of the given type
		owner.world.getClosestItem( owner, itemType, result );
		item = result['item'];

		if ( item != null) {
			// if an item was found, try to pick it up
			final  from = Vector3().copy( owner!.position );
			final  to = Vector3().copy( item!.position );

			// setup subgoals
			addSubgoal( FindPathGoal( owner, from, to ) );
			addSubgoal( FollowPathGoal( owner ) );
		} 
    else {
			// if no item was returned, there is nothing to pick up.
			// mark the goal as failed
			status = GoalStatus.failed;

			// ensure the bot does not look for this type of item for a while
			owner.ignoreItem( itemType );
		}
	}

  @override
	void execute() {
		if ( active ) {
			// only check the availability of the item if it is visible for the enemy
			if ( regulator.ready() && owner!.vision!.visible( item!.position ) ) {
				// if it was picked up by somebody else, mark the goal as failed
				if ( item?.active == false ) {
					status = GoalStatus.failed;
				} 
        else {
					status = executeSubgoals();
				}
			} 
      else {
				status = executeSubgoals();
			}

			// replan the goal means the bot tries to find another item of the same type
			replanIfFailed();
		}
	}

  @override
	void terminate() {
		clearSubgoals();
	}
}
