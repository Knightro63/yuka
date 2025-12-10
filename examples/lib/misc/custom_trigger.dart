import 'package:yuka/yuka.dart';

class CustomTrigger extends Trigger {

	CustomTrigger( super.triggerRegion );

  @override
	execute(GameEntity entity ) {
		super.execute(entity);
		entity.renderComponent.material.color.setFromHex32( 0x00ff00 );
	}
}
