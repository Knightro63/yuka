import 'package:examples/common/graph_helper.dart';
import 'package:examples/common/nav_mesh_helper.dart';
import 'package:examples/common/path_planner.dart';
import 'package:examples/showcase/dive/controls/first_person_controls.dart';
import 'package:examples/showcase/dive/core/asset_manager.dart';
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:examples/showcase/dive/core/spawning_manager.dart';
import 'package:examples/showcase/dive/core/ui_manager.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:examples/showcase/dive/entities/item.dart';
import 'package:examples/showcase/dive/entities/level.dart';
import 'package:examples/showcase/dive/entities/player.dart';
import 'package:examples/showcase/dive/etc/scene_utils.dart';
import 'package:examples/showcase/dive/weapons/bullet.dart';
import 'package:examples/showcase/dive/weapons/projectile.dart';
import 'package:flutter/widgets.dart';
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_objects/three_js_objects.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;


/// Class for representing the game world. It's the key point where
/// the scene and all game entities are created and managed.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
class World { 
  final currentIntersectionPoint = Vector3();

	late final spawningManager = SpawningManager( this );
	late final uiManager = UIManager( this );
	final entityManager = EntityManager();
	final time = Time();
	int tick = 0;

	bool debug = true;

  final Map<String,dynamic> helpers = {
    'convexRegionHelper': null,
    'spatialIndexHelper': null,
    'axesHelper': null,
    'graphHelper': null,
    'pathHelpers': [],
    'spawnHelpers': [],
    'uuidHelpers': [],
    'skeletonHelpers': [],
    'itemHelpers': []
  };

  AssetManager? assetManager;
  NavMesh? navMesh;
  CostTable? costTable;
  PathPlanner? pathPlanner;
  final three.ThreeJS threeJs;

  late final three.Camera camera = threeJs.camera;
  late final three.Scene scene = threeJs.scene;
  late final three.WebGLRenderer? renderer = threeJs.renderer;

  FirstPersonControls? fpsControls;
  three.OrbitControls? orbitControls;
  bool useFPSControls = false;

  Player? player;
  int enemyCount = config['BOT']['COUNT'];
  List competitors = [];
	BuildContext buildContext;
	void Function()? startLoc;
	void Function()? removeLoc;

	World(this.threeJs,this.buildContext);

	/// Entry point for the game. It initializes the asset manager and then
	/// starts to build the game environment.
	Future<World> init() async{
		assetManager = AssetManager();

		await assetManager?.init();
    _initScene();
    _initLevel();
    await _initEnemies();
    _initPlayer();
    _initControls();
    _initUI();

    threeJs.postProcessor = animate;

		return this;
	}

	/// Adds the given game entity to the game world. This means it is
	/// added to the entity manager and to the scene if it has a render component.
	World add(GameEntity entity ) {
		entityManager.add( entity );

		if ( entity.renderComponent != null ) {
			scene.add( entity.renderComponent );
		}

		return this;
	}

	/// Removes the given game entity from the game world. This means it is
	/// removed from the entity manager and from the scene if it has a render component.
	World remove(GameEntity entity ) {
		entityManager.remove( entity );

		if ( entity.renderComponent != null ) {
			scene.remove( entity.renderComponent );
		}

		return this;
	}

	/// Adds a bullet to the game world. The bullet is defined by the given
	/// parameters and created by the method.
	World addBullet(GameEntity owner, Ray ray ) {
		final bulletLine = assetManager?.models['bulletLine'].clone();
		bulletLine.visible = false;

		final bullet = Bullet( owner, ray );
		bullet.setRenderComponent( bulletLine, sync );

		add( bullet );

		return this;
	}

	/// The method checks if compatible game entities intersect with a projectile.
	/// The closest hitted game entity is returned. If no intersection is detected,
	/// null is returned. A possible intersection point is stored into the second parameter.
	GameEntity? checkProjectileIntersection(Projectile projectile, Vector3 intersectionPoint ) {
		final entities = entityManager.entities;
		double minDistance = double.infinity;
		GameEntity? hittedEntity;

		final owner = projectile.owner;
		final ray = projectile.ray;

		for ( int i = 0, l = entities.length; i < l; i ++ ) {
			final dynamic entity = entities[ i ];

			// do not test with the owner entity and only process entities with the correct interface
			if ( entity != owner && entity.active && entity.checkProjectileIntersection != null) {
				if ( entity.checkProjectileIntersection( ray, currentIntersectionPoint ) != null ) {
					final squaredDistance = currentIntersectionPoint.squaredDistanceTo( ray.origin );

					if ( squaredDistance < minDistance ) {
						minDistance = squaredDistance;
						hittedEntity = entity;

						intersectionPoint.copy( currentIntersectionPoint );
					}
				}
			}
		}

		return hittedEntity;
	}

	/// Finds the nearest item of the given item type for the given entity.
	Map<String,dynamic> getClosestItem( entity, ItemType itemType, Map<String,dynamic> result ) {
		// pick correct item list
		List<Item>? itemList = spawningManager.getItemList( itemType );

		// determine closest item
		Item? closestItem;
		double minDistance = double.infinity;

		for ( int i = 0, l = (itemList?.length ?? 0); i < l; i ++ ) {
			final item = itemList?[ i ];

			// consider only active items
			if ( item?.active == true) {
				final fromRegion = entity.currentRegion;
				final toRegion = item!.currentRegion!;

				final from = navMesh?.getNodeIndex( fromRegion );
				final to = navMesh?.getNodeIndex( toRegion );

				// use lookup table to find the distance between two nodes

				final distance = costTable?.get( from!, to! )[1];

				if ( (distance ?? 0) < minDistance ) {
					minDistance = distance?.toDouble() ?? 0.0;
					closestItem = item;
				}
			}
		}

		//
		result['item'] = closestItem;
		result['distance'] = minDistance;

		return result;
	}

	/// Inits all basic objects of the scene like the scene graph itself, the camera, lights
	/// or the renderer.
	World _initScene() {
		// scene
		scene.background = three.Color.fromHex32( 0xffffff );

		// camera
		//camera = PerspectiveCamera( 40, window.innerWidth / window.innerHeight, 0.1, 1000 );
		camera.position.setValues( 0, 75, 100 );

		// helpers
		if ( debug ) {
			helpers['axesHelper'] = AxesHelper( 5 );
			helpers['axesHelper'].visible = false;
			scene.add( helpers['axesHelper'] );
		}

		// lights
		final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.2 );
		hemiLight.position.setValues( 0, 100, 0 );
		scene.add( hemiLight );

		final dirLight = three.DirectionalLight( 0xffffff, 0.4 );
		dirLight.position.setValues( - 700, 1000, - 750 );
		scene.add( dirLight );

		// sky
		final sky = Sky.create();
		sky.scale.setScalar( 1000 );

		sky.material?.uniforms['turbidity']['value'] = 5;
		sky.material?.uniforms['rayleigh']['value'] = 1.5;
		sky.material?.uniforms['sunPosition']['value'].setValues( - 700.0, 1000.0, - 750.0 );

		scene.add( sky );

		return this;
	}

	/// Creates a specific amount of enemies.
	Future<World> _initEnemies() async{
		final enemyCount = this.enemyCount;
		final navMesh = assetManager!.navMesh;
    if(navMesh == null) return this;

		pathPlanner = PathPlanner( navMesh );

		for ( int i = 0; i < enemyCount; i ++ ) {

			final three.Object3D? renderComponent = SkeletonUtils.clone(assetManager!.models['soldier']);

			final enemy = Enemy( this );
			enemy.name = 'Bot$i';
			enemy.setRenderComponent( renderComponent, sync );

			// set animations
			final mixer = renderComponent == null?null:three.AnimationMixer( renderComponent );

			final idleClip = assetManager?.animations['soldier_idle'];
			final runForwardClip = assetManager?.animations['soldier_forward'] ;
			final runBackwardClip = assetManager?.animations['soldier_backward'] ;
			final strafeLeftClip = assetManager?.animations['soldier_left'] ;
			final strafeRightClip = assetManager?.animations['soldier_right'] ;
			final death1Clip = assetManager?.animations['soldier_death1'] ;
			final death2Clip = assetManager?.animations['soldier_death2'] ;

			final List<three.AnimationClip>? clips = mixer == null?null:[ idleClip, runForwardClip, runBackwardClip, strafeLeftClip, strafeRightClip, death1Clip, death2Clip ];

			if(mixer != null) enemy.setAnimations( mixer, clips! );

			//
			add( enemy );
			competitors.add( enemy );
			spawningManager.respawnCompetitor( enemy );

			//
			if (debug ) {
				final pathHelper = GraphHelper.createPathHelperBasic();
				enemy.pathHelper = pathHelper;

				scene.add( pathHelper );
				helpers['pathHelpers'].add( pathHelper );

				//
				final uuidHelper = await SceneUtils.createUUIDLabel( enemy.uuid!,buildContext );
				uuidHelper.position.y = 2;
				uuidHelper.visible = false;

				renderComponent?.add( uuidHelper );
				helpers['uuidHelpers'].add( uuidHelper );

				//
				final skeletonHelper = renderComponent == null?null: SkeletonHelper( renderComponent );
				skeletonHelper?.visible = false;

				scene.add( skeletonHelper );
				helpers['skeletonHelpers'].add( skeletonHelper );
			}
		}

		return this;
	}

	/// Creates the actual level.
	World _initLevel() {
		// level entity
		final renderComponent = assetManager?.models['level'];
		final three.Object3D? mesh = renderComponent?.getObjectByName( 'level' );

		final vertices = mesh?.geometry?.attributes['position'].array.toDartList();
		final indices = mesh == null?null:List<int>.from(mesh.geometry!.index!.array.toDartList());
     if(mesh != null){
      final geometry = MeshGeometry( vertices, indices );
      final level = Level( geometry );
      level.name = 'level';
      level.setRenderComponent( renderComponent, sync );

      add( level );
     }
		// navigation mesh
		navMesh = assetManager!.navMesh;
		costTable = assetManager!.costTable;

		// spatial index

		final levelConfig = assetManager?.configs['level'];
		final width = levelConfig['spatialIndex']['width'] * 1.0;
		final height = levelConfig['spatialIndex']['height'] * 1.0;
		final depth = levelConfig['spatialIndex']['depth'] * 1.0;
		final cellsX = levelConfig['spatialIndex']['cellsX'];
		final cellsY = levelConfig['spatialIndex']['cellsY'];
		final cellsZ = levelConfig['spatialIndex']['cellsZ'];

		navMesh?.spatialIndex = CellSpacePartitioning( width, height, depth, cellsX, cellsY, cellsZ );
		navMesh?.updateSpatialIndex();

		helpers['spatialIndexHelper'] = navMesh == null?null:NavMeshHelper.createCellSpaceHelper( navMesh!.spatialIndex );
		scene.add( helpers['spatialIndexHelper']..visible = false );

		// init spawning points and items
		spawningManager.init();

		// debugging

		if ( debug ) {
			helpers['convexRegionHelper'] = navMesh == null?null:NavMeshHelper.createConvexRegionHelper( navMesh! );
			scene.add( helpers['convexRegionHelper']..visible = false );

			//
			helpers['graphHelper'] = navMesh == null?null:GraphHelper.createGraphHelper( navMesh!.graph, 0.2 );
			scene.add( helpers['graphHelper']..visible = false );

			//
			helpers['spawnHelpers'] = SceneUtils.createSpawnPointHelper( spawningManager.spawningPoints );
			scene.add( helpers['spawnHelpers']..visible = false );
		}

		return this;
	}

	/// Creates the player instance.
	World _initPlayer() {
		final player = Player( this );

		// // render component
		// final body = three.Object3D(); // dummy 3D object for adding spatial audios
		// body.matrixAutoUpdate = false;
		// player.setRenderComponent( body, sync );

  	//player.position.set( 6, 0, 35 );
		player.head.setRenderComponent( camera, syncCamera );
    //scene.add( camera );

		// animation
		final mixer = three.AnimationMixer( player.head.renderComponent );
		final deathClip = assetManager?.animations['player_death'];
		final List<three.AnimationClip>? clips = deathClip == null?null:[ deathClip ];

		if(clips != null) player.setAnimations( mixer, clips );

		// add the player to the world
		add( player );
		competitors.add( player );
		spawningManager.respawnCompetitor( player );

		// in dev mode we start with orbit controls
		if ( debug ) {
			player.deactivate();
		}

		//
		this.player = player;

		return this;
	}

  void updateUI(){
    threeJs.onSetupComplete();
  }

	void lockControls(){
		startLoc?.call();
		fpsControls?.connect();
		useFPSControls = true;

		orbitControls?.enabled = false;
		camera.matrixAutoUpdate = false;

		player?.activate();
		player?.head.setRenderComponent( camera, syncCamera );

		uiManager.showFPSInterface();

		if ( debug ) {
			uiManager.closeDebugUI();
		}

    threeJs.onSetupComplete();
	}

	void unlockControls(){
		removeLoc?.call();
		useFPSControls = false;
		orbitControls?.enabled = true;
		camera.matrixAutoUpdate = true;

		player?.deactivate();
		player?.head.setRenderComponent( null, null );

		uiManager.hideFPSInterface();

		if ( debug ) {
			uiManager.openDebugUI();
		}

    threeJs.onSetupComplete();
	}

	/// Inits the controls used by the player.
	World _initControls() {
		fpsControls = FirstPersonControls( player!,threeJs );
		fpsControls?.sync();

		//
		if ( debug ) {
			orbitControls = three.OrbitControls( camera, threeJs.globalKey );
			orbitControls?.maxDistance = 500;
		}

		return this;
	}

	/// Inits the user interface.
	World _initUI() {
		uiManager.init();
		return this;
	}

  // used to sync Yuka Game Entities with three.js objects
  void sync(GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }

  void syncCamera( GameEntity entity, three.Object3D renderComponent ) {
    final three.Matrix4 m = three.Matrix4().copyFromArray( entity.worldMatrix().elements);
    renderComponent.position.setFromMatrixPosition(m);
    renderComponent.quaternion.setFromRotationMatrix(m);
    renderComponent.updateMatrix();
  }

  // game loop
  void animate([double? dt]) {
    time.update();
    tick ++;

    final delta = time.delta;

    if ( debug ) {
      if ( useFPSControls ) {
        fpsControls?.update( delta );
      }
    } 
    else {
      fpsControls?.update( delta );
    }

    spawningManager.update( delta );
    entityManager.update( delta );
    pathPlanner?.update();

    renderer!.setViewport(0,0,threeJs.width,threeJs.height);
    renderer!.clear();
    renderer!.render( threeJs.scene, threeJs.camera );
    
    uiManager.update( delta );
  }
}