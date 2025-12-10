import 'package:examples/playground/shooter/yuka_first_person_controls.dart';
import 'package:examples/playground/shooter/player.dart';
import 'package:examples/playground/shooter/Ground.dart';
import 'package:examples/playground/shooter/asset_manager.dart';
import 'package:examples/playground/shooter/bullet.dart';
import 'package:examples/playground/shooter/target.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

final target = yuka.Vector3();
final intersection = {
	'point': yuka.Vector3(),
	'normal': yuka.Vector3()
};

class World {
  int maxBulletHoles = 20;

  final entityManager = yuka.EntityManager();
  final time = yuka.Time();
  final assetManager = AssetManager();

  Player? player;
  three.ThreeJS? threeJs;
  three.Scene? scene;
  three.Camera? camera;
  YukaFirstPersonControls? controls;
  three.AnimationMixer? mixer;
  
  List obstacles = [];
  List bulletHoles = [];

  late Map<String,dynamic> ui = {
    'intro': threeJs?.domElement,
    'crosshairs': threeJs?.domElement,
    'loadingScreen': threeJs?.domElement
  };

  Map<String,dynamic> animations = {};

	World([this.threeJs]) {
		camera = threeJs?.camera;
		scene = threeJs?.scene;
	}

	Future<void> init() async{
		await assetManager.init().then((e){
			_initScene();
			_initGround();
			_initPlayer();
			_initControls();
			_initTarget();
		} );
    time.reset();
	}

	void update() {
		final delta = time.update().delta;
		controls!.update( delta );

		entityManager.update( delta );
		mixer!.update( delta );
	}

	void add( entity ) {
		entityManager.add( entity );

		if ( entity.renderComponent != null ) {
			scene?.add( entity.renderComponent );
		}

		if ( entity?.geometry != null) {
			obstacles.add( entity );
		}
	}

	void remove( entity ) {
		entityManager.remove( entity );

		if ( entity.renderComponent != null ) {
			scene?.remove( entity.renderComponent );
		}

		if ( entity.geometry  != null) {
			final index = obstacles.indexOf( entity );
			if ( index != - 1 ) obstacles.removeAt( index );
		}
	}

	void addBullet( owner, yuka.Ray ray ) {
		final bulletLine = assetManager.models['bulletLine'].clone();
		final bullet = Bullet( owner, this, ray );
		bullet.setRenderComponent( bulletLine, sync );
		add( bullet );
	}

	void addBulletHole(yuka.Vector3 position, yuka.Vector3 normal ) {
		final bulletHole = assetManager.models['bulletHole'].clone();

		final s = 1 + ( math.Random().nextDouble() * 0.5 );
		bulletHole.scale.setValues( s, s, s );

		bulletHole.position.copyFromArray( position.storage );
		target.copy( position ).add( normal );
		bulletHole.updateMatrix();
		bulletHole.lookAt(three.Vector3( target.x, target.y, target.z ));
		bulletHole.updateMatrix();

		if ( bulletHoles.length >= maxBulletHoles ) {
			final toRemove = bulletHoles.removeAt(0);
			scene?.remove( toRemove );
		}

		bulletHoles.add( bulletHole );
		scene?.add( bulletHole );
	}

	intersectRay(yuka.Ray ray, yuka.Vector3 intersectionPoint, [yuka.Vector3? normal] ) {
		final obstacles = this.obstacles;
		double minDistance = double.infinity;
		dynamic closestObstacle;

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstacle = obstacles[ i ];

			if ( obstacle.geometry.intersectRay( ray, obstacle.worldMatrix(), false, intersection['point'], intersection['normal'] ) != null ) {
				final squaredDistance = intersection['point']!.squaredDistanceTo( ray.origin );

				if ( squaredDistance < minDistance ) {
					minDistance = squaredDistance;
					closestObstacle = obstacle;

					intersectionPoint.copy( intersection['point']! );
					if ( normal != null) normal.copy( intersection['normal']! );
				}
			}
		}

		return ( closestObstacle == null ) ? null : closestObstacle;
	}

	void _initScene() {
		// camera
		camera?.matrixAutoUpdate = false;
		//camera?.add( assetManager.listener );

		// scene
		scene?.background = three.Color.fromHex32( 0xa0a0a0 );
		scene?.fog = three.Fog( 0xa0a0a0, 10, 50 );

		// lights
		final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.8 );
		hemiLight.position.setValues( 0, 100, 0 );
		scene?.add( hemiLight );

		final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
		dirLight.castShadow = true;
		dirLight.shadow?.camera?.top = 5;
		dirLight.shadow?.camera?.bottom = - 5;
		dirLight.shadow?.camera?.left = - 5;
		dirLight.shadow?.camera?.right = 5;
		dirLight.shadow?.camera?.near = 0.1;
		dirLight.shadow?.camera?.far = 25;
		dirLight.position.setValues( 5, 7.5, - 10 );
		dirLight.target?.position.setValues( 0, 0, - 25 );
		dirLight.target?.updateMatrixWorld();
		scene?.add( dirLight );

		// this.scene.add( three.CameraHelper( dirLight.shadow.camera ) );
	}

	void _initGround() {
		final groundMesh = assetManager.models['ground'];

		final vertices = groundMesh.geometry.attributes['position'].array.toDartList();
		final indices = groundMesh.geometry.index.array.toDartList();

		final geometry = yuka.MeshGeometry( vertices, indices );
		final ground = Ground( geometry );
		ground.setRenderComponent( groundMesh, sync );

		add( ground );
	}

	void _initPlayer() {
		final player = Player(this);
		player.head.setRenderComponent( camera, syncCamera );

		add( player );
		this.player = player;

		// weapon
		final weapon = player.weapon;
		final weaponMesh = assetManager.models['weapon'];
		weapon.setRenderComponent( weaponMesh, sync );
		scene?.add( weaponMesh );

		// animations
		mixer = three.AnimationMixer( weaponMesh );

		final shotClip = assetManager.animations['shot'];
		final shotAction = mixer?.clipAction( shotClip );
		shotAction?.loop = three.LoopOnce;

		animations['shot']= shotAction;

		final reloadClip = assetManager.animations['reload'];
		final reloadAction = mixer?.clipAction( reloadClip );
		reloadAction?.loop = three.LoopOnce;

		animations['reload'] = reloadAction;
	}

	void _initControls() {
		final player = this.player;

		controls = YukaFirstPersonControls( player!, this );

		final intro = ui['intro'];
		final crosshairs = ui['crosshairs'];

		controls?.addEventListener( 'lock', (){
			intro.classList.add( 'hidden' );
			crosshairs.classList.remove( 'hidden' );
		} );

		controls?.addEventListener( 'unlock', (){
			intro.classList.remove( 'hidden' );
			crosshairs.classList.add( 'hidden' );
		} );

    controls!.connect();
	}

	void _initTarget() {
		final targetMesh = assetManager.models['target'];

		final vertices = targetMesh.geometry.attributes['position'].array.toDartList();
		final indices = targetMesh.geometry.index.array.toDartList();

		final geometry = yuka.MeshGeometry( vertices, indices );
		final target = Target( geometry );
		target.position.set( 0, 5, - 20 );
		target.setRenderComponent( targetMesh, sync );

		add( target );
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }

  void syncCamera( yuka.GameEntity entity, three.Object3D renderComponent ) {
    final three.Matrix4 m = three.Matrix4().copyFromArray( entity.worldMatrix().elements);
    renderComponent.position.setFromMatrixPosition(m);
    renderComponent.quaternion.setFromRotationMatrix(m);
    renderComponent.updateMatrix();
  }

  void onTransitionEnd( event ) {
    event.target.remove();
  }

  void animate() {
    update();
  }
}