import 'package:examples/playground/common/world.dart';
import 'package:examples/common/yuka_first_person_controls.dart';
import 'package:examples/playground/common/player.dart';
import 'package:examples/playground/hideseek/asset_manager.dart';
import 'package:examples/playground/hideseek/custom_obstacle.dart';
import 'package:examples/playground/hideseek/enemy.dart';
import 'package:examples/playground/common/ground.dart';
import 'package:examples/playground/common/bullet.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

final target = yuka.Vector3();
final intersection = {
	'point': yuka.Vector3(),
	'normal': yuka.Vector3()
};

class HideSeekWorld extends World{
  YukaFirstPersonControls? controls;
  three.AnimationMixer? mixer;

  int maxBulletHoles = 48;
  int enemyCount = 3;
  double minSpawningDistance = 10;

  final List<Enemy> enemies = [];
  final List<yuka.Vector3> spawningPoints = [];
  final List<yuka.Vector3> usedSpawningPoints = [];

  int hits = 0;
  double playingTime = 60; // 60s
  int currentTime = 60;

	bool started = false;
	bool gameOver = false;
	bool debug = false;

  late Map<String,dynamic> ui = {
    'playingTime': playingTime,
		'hits': hits,
  };

	HideSeekWorld.create(super.threeJs,super.assetManager);

  factory HideSeekWorld(three.ThreeJS threeJs){
    return HideSeekWorld.create(threeJs, HSAssetManager());
  }

  @override
	Future<void> init() async{
		await assetManager.init().then((e){
			_initScene();
			_initPlayer();
			_initControls();
			_initGround();
			_initObstacles();
			_initSpawningPoints();
		} );
	}

  @override
	void update() {
		// add enemies if necessary
		final enemies = this.enemies;

		if ( enemies.length < enemyCount ) {
			for ( int i = enemies.length, l = enemyCount; i < l; i ++ ) {
				addEnemy(i);
			}
		}

    if(!started) return;
		final delta = time.update().delta;

		// update UI
		if ( started == true && gameOver == false ) {
			playingTime -= delta;

			if ( playingTime < 0 ) {
				gameOver = true;
				//controls.exit();
			}
      else if(playingTime.ceil() < currentTime){
        currentTime = playingTime.ceil();
        updateUI();
      }
		}

		controls!.update( delta );
		entityManager.update( delta );
		mixer!.update( delta );
	}

  @override
	void add( entity ) {
		entityManager.add( entity );

		if ( entity.renderComponent != null ) {
			scene.add( entity.renderComponent );
		}

		if ( entity?.geometry != null ) {
			obstacles.add( entity );
		}

		if ( entity is Enemy ) {
			enemies.add( entity );
		}
	}

  @override
	void remove( entity ) {
		entityManager.remove( entity );

		if ( entity.renderComponent != null ) {
			scene.remove( entity.renderComponent );
		}

		if ( entity?.geometry != null ) {
			final index = obstacles.indexOf( entity );
			if ( index != - 1 ) obstacles.removeAt( index );
		}

		if ( entity is Enemy ) {
			final index = enemies.indexOf( entity );
			if ( index != - 1 ) enemies.removeAt( index );
			usedSpawningPoints.remove( entity.spawningPoint );
		}
	}

  @override
	void addBullet( owner, yuka.Ray ray ) {
		final bulletLine = assetManager.models['bulletLine'].clone();
		final bullet = Bullet( owner, this, ray );
		bullet.setRenderComponent( bulletLine, sync );
		add( bullet );
	}

  @override
	void addBulletHole(yuka.Vector3 position, yuka.Vector3 normal ) {
		final bulletHole = assetManager.models['bulletHole'].clone();

		final s = 1 + ( math.Random().nextDouble() * 0.5 );
		bulletHole.scale.setValues( s, s, s );

		bulletHole.position.copyFromArray( position.storage );
		target.copy( position ).add( normal );
		bulletHole.updateMatrix();
		bulletHole.lookAt( three.Vector3(target.x, target.y, target.z) );
		bulletHole.updateMatrix();

		if ( bulletHoles.length >= maxBulletHoles ) {
			final toRemove = bulletHoles.removeAt(0);
			scene.remove( toRemove );
		}

		bulletHoles.add( bulletHole );
		scene.add( bulletHole );

	}

	void addEnemy(int i) {
		final renderComponent = assetManager.models['enemy'].clone();

		final enemyMaterial = three.MeshStandardMaterial.fromMap( { 'color': 0xee0808, 'side': three.DoubleSide, 'transparent': true } );
		enemyMaterial.onBeforeCompile = ( shader,t ) {
			shader.uniforms['alpha'] = { 'value': 0.0 };
			shader.uniforms['direction'] = { 'value': three.Vector3() };
			shader.vertexShader = 'uniform float alpha;\n${shader.vertexShader}';
			shader.vertexShader = 'attribute vec3 scatter;\n${shader.vertexShader}';
			shader.vertexShader = 'attribute float extent;\n${shader.vertexShader}';
			shader.vertexShader = shader.vertexShader.replaceAll(
				'#include <begin_vertex>',
				[
					'vec3 transformed = vec3( position );',
					'transformed += normalize( scatter ) * alpha * extent;',
				].join( '\n' )
			);

			enemyMaterial.userData['shader'] = shader;
		};

		renderComponent.material = enemyMaterial;

		final vertices = renderComponent.geometry.attributes['position'].array.toDartList();
		final geometry = yuka.MeshGeometry( vertices );

		final enemy = Enemy( geometry, this );
    enemy.name = 'Enemy';
		enemy.boundingRadius = renderComponent.geometry.boundingSphere.radius;
    //enemy.rotation.fromEuler(math.pi/2,0,0);
		enemy.setRenderComponent( renderComponent, sync );

		// compute spawning point
		yuka.Vector3? spawningPoint;
		final minSqDistance = minSpawningDistance * minSpawningDistance;

		while ( usedSpawningPoints.contains( spawningPoint ) == true || (spawningPoint?.squaredDistanceTo( player!.position ) ?? 0) < minSqDistance ) {
			final spawningPointIndex = ( math.Random().nextDouble() * spawningPoints.length - 1 ).ceil();
			spawningPoint = spawningPoints[ spawningPointIndex ];
		}

		usedSpawningPoints.add( spawningPoint! );

		enemy.position.copy( spawningPoint );
		enemy.spawningPoint = spawningPoint;

		add( enemy );
	}

  @override
	intersectRay(yuka.Ray ray, yuka.Vector3 intersectionPoint, [yuka.Vector3? normal] ) {
		final obstacles = this.obstacles;
		double minDistance = double.infinity;
		dynamic closestObstacle;

		for ( int i = 0, l = obstacles.length; i < l; i ++ ) {
			final obstalce = obstacles[ i ];

			if ( obstalce.geometry.intersectRay( ray, obstalce.worldMatrix(), false, intersection['point'], intersection['normal'] ) != null ) {
				final squaredDistance = intersection['point']!.squaredDistanceTo( ray.origin );
        
				if ( squaredDistance < minDistance ) {
					minDistance = squaredDistance;
					closestObstacle = obstalce;

					intersectionPoint.copy( intersection['point']! );
					if ( normal != null) normal.copy( intersection['normal']! );
				}
			}
		}
		return closestObstacle;
	}

	_initScene() {
		// camera
		camera.matrixAutoUpdate = false;

		// scene
		scene.background = three.Color.fromHex32( 0xa0a0a0 );
		scene.fog = three.Fog( 0xa0a0a0, 20, 150 );

		// lights
		final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.8 );
		hemiLight.position.setValues( 0, 100, 0 );
		hemiLight.matrixAutoUpdate = false;
		hemiLight.updateMatrix();
		scene.add( hemiLight );

		final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
		dirLight.position.setValues( 20, 25, 25 );
		dirLight.matrixAutoUpdate = false;
		dirLight.updateMatrix();
		dirLight.castShadow = true;
		dirLight.shadow?.camera?.top = 25;
		dirLight.shadow?.camera?.bottom = - 25;
		dirLight.shadow?.camera?.left = - 30;
		dirLight.shadow?.camera?.right = 30;
		dirLight.shadow?.camera?.near = 0.1;
		dirLight.shadow?.camera?.far = 100;
		dirLight.shadow?.mapSize.x = 2048;
		dirLight.shadow?.mapSize.y = 2048;
		scene.add( dirLight );

		if (debug ) scene.add( CameraHelper( dirLight.shadow!.camera! ) );
	}

	void _initSpawningPoints() {
		final spawningPoints = this.spawningPoints;

		for ( int i = 0; i < 9; i ++ ) {
			final spawningPoint = yuka.Vector3();

			spawningPoint.x = 18 - ( ( i % 3 ) * 12 );
			spawningPoint.z = 18 - ( ( i / 3 ).floor() * 12 );

			spawningPoints.add( spawningPoint );
		}

		if ( debug ) {
			final spawningPoints = this.spawningPoints;
			final spawningPointGeometry = three.SphereGeometry( 0.2 );
			final spawningPointMaterial = three.MeshPhongMaterial.fromMap( { 'color': 0x00ffff, 'depthWrite': false, 'depthTest': false, 'transparent': true } );

			for ( int i = 0, l = spawningPoints.length; i < l; i ++ ) {
				final mesh = three.Mesh( spawningPointGeometry, spawningPointMaterial );
				mesh.position.copyFromArray( spawningPoints[ i ].storage );
				scene.add( mesh );
			}
		}
	}

	void _initPlayer() {
		final player = Player(this, PlayerSettings(allowUpdate: true, maxSpeed: 8, weaponPosition: 0.25, isShotgun: true));
    player.name = 'player';
		player.position.set( 6, 0, 35 );
		player.head.setRenderComponent( camera, syncCamera );

		add( player );
		this.player = player;

		// weapon
		final weaponMesh = assetManager.models['weapon'];
    camera.add(weaponMesh);
		scene.add( camera );

		// animations
		mixer = three.AnimationMixer( weaponMesh );

		final shotClip = assetManager.animations['shot'];
		final shotAction = mixer?.clipAction( shotClip );
		shotAction?.loop = three.LoopOnce;

		animations['shot'] = shotAction;

		final reloadClip = assetManager.animations['reload'];
		final reloadAction = mixer?.clipAction( reloadClip );
		reloadAction?.loop = three.LoopOnce;

		animations['reload'] = reloadAction;
	}

	void _initControls() {
		final player = this.player;
		controls = YukaFirstPersonControls( player!, threeJs );
    controls!.connect();
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

	void _initObstacles() {
		final obstacleMesh = assetManager.models['obstacle'];

		final vertices = obstacleMesh.geometry.attributes['position'].array.toDartList();
		final indices = obstacleMesh.geometry.index.array.toDartList();

		final geometry = yuka.MeshGeometry( vertices, indices );

		for ( int i = 0; i < 16; i ++ ) {
			final mesh = obstacleMesh.clone();
			final obstacle = CustomObstacle( geometry );

			final x = 24 - ( ( i % 4 ) * 12.0 );
			final z = 24 - ( ( i / 4 ).floor() * 12.0 );

			obstacle.position.set( x, 0, z );
			obstacle.boundingRadius = 4;
			obstacle.setRenderComponent( mesh, sync );
			add( obstacle );

			if ( debug ) {
				final helperGeometry = three.SphereGeometry( obstacle.boundingRadius, 16, 16 );
				final helperMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xffffff, 'wireframe': true } );

				final helper = three.Mesh( helperGeometry, helperMaterial );
				mesh.add( helper );
			}
		}
	}

	void updateUI() {
		ui['playingTime'] = playingTime;
		ui['hits'] = hits;
    threeJs.onSetupComplete();
	}

  @override
  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }

  @override
  void syncCamera( yuka.GameEntity entity, three.Object3D renderComponent ) {
    final three.Matrix4 m = three.Matrix4().copyFromArray( entity.worldMatrix().elements);
    renderComponent.position.setFromMatrixPosition(m);
    renderComponent.quaternion.setFromRotationMatrix(m);
    renderComponent.updateMatrix();
  }

  @override
  void animate() {
    update();
  }
}


