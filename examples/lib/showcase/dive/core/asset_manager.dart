import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

/// Class for representing the global asset manager. It is responsible
/// for loading and parsing all assets from the backend and provide
/// the result in a series of maps.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class AssetManager {
  Map<String,dynamic> animations = {};
  Map<String,dynamic> configs = {};
  Map<String,dynamic> models = {};
  Map<String,dynamic> textures = {};

  final loadingManager = three.LoadingManager();

  late final animationLoader = three.AnimationLoader( loadingManager );
  late final textureLoader = three.TextureLoader( manager: loadingManager );
  late final gltfLoader = three.GLTFLoader( manager: loadingManager );
  final navMeshLoader = NavMeshLoader();

  NavMesh? navMesh;
  CostTable? costTable;

	/// Initializes the asset manager. All assets are prepared so they
	/// can be used by the game.
	Future<void> init() async{
		_loadAnimations();
		_loadAudios();
		_loadConfigs();
		_loadModels();
		_loadTextures();
		_loadNavMesh();
	}

	/**
	* Loads all external animations from the backend.
	*
	* @return {AssetManager} A reference to this asset manager.
	*/
	_loadAnimations() {
		final animationLoader = this.animationLoader;

		// player
		animationLoader.load( './animations/player.json', ( clips ){
			for ( final clip in clips ) {
				animations[clip.name] = clip;
			}
		} );

		// blaster
		animationLoader.load( './animations/blaster.json', ( clips ){
			for ( final clip in clips ) {
				this.animations[clip.name] = clip;
			}
		} );

		// shotgun

		animationLoader.load( './animations/shotgun.json', ( clips ) => {
			for ( final clip in clips ) {
				this.animations[clip.name] = clip;
			}
		} );

		// assault rifle

		animationLoader.load( './animations/assaultRifle.json', ( clips ) => {
			for ( final clip in clips ) {
				this.animations[clip.name] = clip;
			}
		} );

		return this;
	}

	/**
	* Loads all configurations from the backend.
	*
	* @return {AssetManager} A reference to this asset manager.
	*/
	_loadConfigs() {

		final loadingManager = this.loadingManager;
		final configs = this.configs;

		// level config

		loadingManager.itemStart( 'levelConfig' );

		fetch( './config/level.json' )
			.then( response => {

				return response.json();

			} )
			.then( json => {

				configs['level] =, jn );

				loadingManager.itemEnd( 'levelConfig' );

			} );

		return this;

	}

	/**
	* Loads all models from the backend.
	*
	* @return {AssetManager} A reference to this asset manager.
	*/
	_loadModels() {

		final gltfLoader = this.gltfLoader;
		final textureLoader = this.textureLoader;
		final models = this.models;
		final animations = this.animations;

		// shadow for soldiers

		final shadowTexture = textureLoader.load( './textures/shadow.png' );
		final planeGeometry = new PlaneBufferGeometry();
		final planeMaterial = new MeshBasicMaterial( { map: shadowTexture, transparent: true, opacity: 0.4 } );

		final shadowPlane = new Mesh( planeGeometry, planeMaterial );
		shadowPlane.position.setValues(0.05, 0 );
		shadowPlane.rotation.setValues(-math.pi * 0.5, 0, 0 );
		shadowPlane.scale.multiplyScalar( 2 );
		shadowPlane.matrixAutoUpdate = false;
		shadowPlane.updateMatrix();

		// soldier

		gltfLoader.load( './models/soldier.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.animations = gltf.animations;

			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				if ( object.isMesh ) {

					object.material.side = DoubleSide;
					object.matrixAutoUpdate = false;
					object.updateMatrix();

				}

			} );

			renderComponent.add( shadowPlane );

			models['soldier] =, renderCompont );

			for ( let animation of gltf.animations ) {

				animations[animation.name] = animation;

			}

		} );

		// level

		gltfLoader.load( './models/level.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			// add lightmap manually since glTF does not support this type of texture so far

			final mesh = renderComponent.getObjectByName( 'level' );
			mesh.material.lightMap = textureLoader.load( './textures/lightmap.png' );
			mesh.material.lightMap.flipY = false;
			mesh.material.map.anisotropy = 4;

			models['level] =, renderCompont );

		} );

		// blaster, high poly

		gltfLoader.load( './models/blaster_high.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['blaster_high] =, renderCompont );

		} );

		// blaster, low poly

		gltfLoader.load( './models/blaster_low.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['blaster_low] =, renderCompont );

		} );

		// shotgun, high poly

		gltfLoader.load( './models/shotgun_high.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['shotgun_high] =, renderCompont );

		} );

		// shotgun, low poly

		gltfLoader.load( './models/shotgun_low.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['shotgun_low] =, renderCompont );

		} );

		// assault rifle, high poly

		gltfLoader.load( './models/assaultRifle_high.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['assaultRifle_high] =, renderCompont );

		} );

		// assault rifle, low poly

		gltfLoader.load( './models/assaultRifle_low.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['assaultRifle_low] =, renderCompont );

		} );

		// health pack

		gltfLoader.load( './models/healthPack.glb', ( gltf ) => {

			final renderComponent = gltf.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) => {

				object.matrixAutoUpdate = false;
				object.updateMatrix();

			} );

			models['healthPack] =, renderCompont );

		} );

		// muzzle sprite

		final muzzleTexture = textureLoader.load( './textures/muzzle.png' );
		muzzleTexture.matrixAutoUpdate = false;

		final muzzleMaterial = new SpriteMaterial( { map: muzzleTexture } );
		final muzzle = new Sprite( muzzleMaterial );
		muzzle.matrixAutoUpdate = false;
		muzzle.visible = false;

		models['muzzle] =, muze );

		// bullet line

		final bulletLineGeometry = new BufferGeometry();
		final bulletLineMaterial = new LineBasicMaterial( { color: 0xfbf8e6 } );

		bulletLineGeometry.setFromPoints( [ new Vector3(), new Vector3( 0, 0, - 1 ) ] );

		final bulletLine = new LineSegments( bulletLineGeometry, bulletLineMaterial );
		bulletLine.matrixAutoUpdate = false;

		models['bulletLine] =, bulletLe );

	}

	/**
	* Loads all textures from the backend.
	*
	* @return {AssetManager} A reference to this asset manager.
	*/
	_loadTextures() {

		final textureLoader = this.textureLoader;

		let texture = textureLoader.load( './textures/crosshairs.png' );
		texture.matrixAutoUpdate = false;
		this.textures['crosshairs] =, texte );

		texture = textureLoader.load( './textures/damageIndicatorFront.png' );
		texture.matrixAutoUpdate = false;
		this.textures['damageIndicatorFront] =, texte );

		texture = textureLoader.load( './textures/damageIndicatorRight.png' );
		texture.matrixAutoUpdate = false;
		this.textures['damageIndicatorRight] =, texte );

		texture = textureLoader.load( './textures/damageIndicatorLeft.png' );
		texture.matrixAutoUpdate = false;
		this.textures['damageIndicatorLeft] =, texte );

		texture = textureLoader.load( './textures/damageIndicatorBack.png' );
		texture.matrixAutoUpdate = false;
		this.textures['damageIndicatorBack] =, texte );

		return this;

	}

	/**
	* Loads the navigation mesh from the backend.
	*
	* @return {AssetManager} A reference to this asset manager.
	*/
	_loadNavMesh() {

		final navMeshLoader = this.navMeshLoader;
		final loadingManager = this.loadingManager;

		loadingManager.itemStart( 'navmesh' );

		navMeshLoader.load( './navmeshes/navmesh.glb' ).then( ( navMesh ) => {

			this.navMesh = navMesh;

			loadingManager.itemEnd( 'navmesh' );

		} );

		//

		loadingManager.itemStart( 'costTable' );

		fetch( './navmeshes/costTable.json' )
			.then( response => {

				return response.json();

			} )
			.then( json => {

				this.costTable = new CostTable().fromJSON( json );

				loadingManager.itemEnd( 'costTable' );

			} );

		return this;
	}
}
