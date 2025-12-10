import 'package:yuka/yuka.dart';

class Target extends GameEntity {
  MeshGeometry geometry;

  double endTime = double.infinity;
  double currentTime = 0;
  double duration = 1; // 1 second

  String uiElement = 'hit';

	Target(this.geometry ):super();

  @override
	Target update(double delta ) {
		currentTime += delta;

		if ( currentTime >= endTime ) {
			uiElement = 'hidden';
			endTime = double.infinity;
		}

		return this;
	}

  @override
	bool handleMessage(Telegram telegram) {
		uiElement = 'hidden';
		endTime = currentTime + duration;
		return true;
	}
}
