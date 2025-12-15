
import 'package:yuka/yuka.dart';

class CustomObstacle extends GameEntity {
  MeshGeometry geometry;

	CustomObstacle(this.geometry ):super();

  @override
	bool handleMessage(Telegram telegram) {
		// do nothing
		return true;
	}
}
