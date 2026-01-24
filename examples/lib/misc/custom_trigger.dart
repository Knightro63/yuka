import 'package:yuka/yuka.dart';

class CustomTrigger extends TriggerEntity {

	CustomTrigger( super.triggerRegion );

  @override
	void execute(GameEntity entity ) {
		super.execute(entity);
		entity.renderComponent.material.color.setFromHex32( 0x00ff00 );
	}
}
