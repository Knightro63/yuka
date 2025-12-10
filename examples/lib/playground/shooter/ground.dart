import 'package:yuka/yuka.dart';

class Ground extends GameEntity {
  MeshGeometry geometry;

	Ground(this.geometry ):super();

  @override
	bool handleMessage(Telegram telegram) {
		// do nothing
		return true;
	}
}
