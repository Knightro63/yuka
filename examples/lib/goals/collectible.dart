import 'package:yuka/yuka.dart';
import 'dart:math' as math;

class Collectible extends GameEntity {
	void spawn() {
		position.x = math.Random().nextDouble() * 15 - 7.5;
	  position.z = math.Random().nextDouble() * 15 - 7.5;

		if ( position.x < 1 && position.x > - 1 ) position.x += 1;
		if ( position.z < 1 && position.y > - 1 ) position.z += 1;
	}

  @override
	bool handleMessage(Telegram telegram ) {
		final message = telegram.message;

		switch ( message ) {
			case 'PickedUp':
				spawn();
				return true;
			default:
				yukaConsole.warning( 'Collectible: Unknown message.' );
		}

		return false;
	}
}
