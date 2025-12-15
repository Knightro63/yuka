import 'package:examples/playground/common/player.dart';
import 'package:examples/playground/common/asset_manager.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;

abstract class World{
  final AssetManager assetManager;
  final entityManager = EntityManager();
  final time = Time();

  Player? player;

  final three.ThreeJS threeJs;
  late final three.Scene scene;
  late final three.Camera camera;

  List obstacles = [];
  List bulletHoles = [];
  Map<String,three.AnimationAction?> animations = {};

  World(this.threeJs, this.assetManager){
    camera = threeJs.camera;
		scene = threeJs.scene;
  }

  Future<void> init();
  void update();
  void add(entity);
  void remove(entity);
  void addBullet(owner, Ray ray);
  void addBulletHole(Vector3 position, Vector3 normal );
  intersectRay(Ray ray, Vector3 intersectionPoint, [Vector3? normal] );
  void sync(GameEntity entity, three.Object3D renderComponent );
  void syncCamera( GameEntity entity, three.Object3D renderComponent );
  void animate();
}