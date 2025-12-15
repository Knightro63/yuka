import 'package:three_js/three_js.dart' as three;

abstract class AssetManager {

  final loadingManager = three.LoadingManager();
	late final textureLoader = three.TextureLoader(manager: loadingManager );

	final Map<String,dynamic> animations = {};
	final Map<String,dynamic> models = {};

	Future<void> init();
}
