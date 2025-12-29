import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "package:three_js/three_js.dart";

///
/// Class for loading animation clips in the JSON format. The files are internally
/// loaded via {@link FileLoader}.
///
/// ```dart
/// final loader = new three.AnimationLoader();
/// const animations = await loader.fromAsset( 'assets/animations/animation.json' );
/// ```
///
class AnimationLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Constructs a new animation loader.
  AnimationLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<List<AnimationClip>?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<AnimationClip>> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<List<AnimationClip>?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<AnimationClip>> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<List<AnimationClip>?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<List<AnimationClip>> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

	/// Parses the given JSON object and returns an array of animation clips.
	///
	/// return The parsed animation clips.
	///
	List<AnimationClip> _parse(Uint8List data) {
    dynamic json = jsonDecode(String.fromCharCodes(data));
		final List<AnimationClip> animations = [];

		for ( int i = 0; i < json.length; i ++ ) {
			final clip = AnimationClip.parse( json[ i ] );
			animations.add( clip );
		}

		return animations;
	}
}
