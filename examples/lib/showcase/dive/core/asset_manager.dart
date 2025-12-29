import 'dart:convert';
import 'package:examples/showcase/dive/etc/animation_loader.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/navigation/navmesh/file_loader.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;

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

  late final animationLoader = AnimationLoader();
  late final textureLoader = three.TextureLoader();
  late final gltfLoader = three.GLTFLoader()..setPath('assets/showcase/models/');
  final navMeshLoader = NavMeshLoader();

  NavMesh? navMesh;
  CostTable? costTable;

	/// Initializes the asset manager. All assets are prepared so they
	/// can be used by the game.
	Future<void> init() async{
		await _loadAnimations();
		await _loadConfigs();
		await _loadModels();
		await _loadNavMesh();
	}

	/// Loads all external animations from the backend.
	Future<AssetManager> _loadAnimations() async{
		final animationLoader = this.animationLoader;

		// player
		await animationLoader.fromAsset( 'assets/showcase/animations/player.json').then(( clips ){
			for ( final clip in clips! ) {
				animations[clip.name] = clip;
			}
		} );

		// blaster
		await animationLoader.fromAsset( 'assets/showcase/animations/blaster.json').then(( clips ){
			for ( final clip in clips! ) {
				animations[clip.name] = clip;
			}
		} );

		// shotgun
		await animationLoader.fromAsset( 'assets/showcase/animations/shotgun.json').then(( clips ){
			for ( final clip in clips! ) {
			  animations[clip.name] = clip;
			}
		} );

		// assaultRifle
		await animationLoader.fromAsset( 'assets/showcase/animations/assaultRifle.json').then(( clips ){
			for ( final clip in clips! ) {
				animations[clip.name] = clip;
			}
		} );

		return this;
	}

	/// Loads all configurations from the backend.
	Future<AssetManager> _loadConfigs() async{
		final configs = this.configs;
    await YukaFileLoader().fromAsset('assets/showcase/config/level.json').then((json){
			configs['level'] = jsonDecode(String.fromCharCodes(json!.data));
    });
		return this;
	}

	/// Loads all models from the backend.
	Future<AssetManager> _loadModels() async{
		final gltfLoader = this.gltfLoader;
		final textureLoader = this.textureLoader;
		final models = this.models;
		final animations = this.animations;

		// shadow for soldiers
		final shadowTexture = await textureLoader.fromAsset( 'assets/showcase/textures/shadow.png' );
		final planeGeometry = three.PlaneGeometry();
		final planeMaterial = three.MeshBasicMaterial.fromMap( { 'map': shadowTexture, 'transparent': true, 'opacity': 0.4 } );

		final shadowPlane = three.Mesh( planeGeometry, planeMaterial );
		shadowPlane.position.setValues(0.05, 0 );
		shadowPlane.rotation.set(-math.pi * 0.5, 0, 0 );
		shadowPlane.scale.scale( 2 );
		shadowPlane.matrixAutoUpdate = false;
		shadowPlane.updateMatrix();

		// soldier
		await  gltfLoader.fromAsset( 'soldier.glb').then(( gltf ){
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ){

				if ( object is three.Mesh ) {
					object.material?.side = three.DoubleSide;
					object.matrixAutoUpdate = false;
					object.updateMatrix();
				}
			} );

			renderComponent.add( shadowPlane );

			models['soldier'] = renderComponent;

			for ( final animation in gltf.animations! ) {
				animations[animation.name] = animation;
			}
		} );

		// level
		await gltfLoader.fromAsset( 'level.glb').then (( gltf ) async{
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			// add lightmap manually since glTF does not support this type of texture so far
			final mesh = renderComponent.getObjectByName( 'level' );
      mesh?.material?.map = await textureLoader.fromAsset( 'assets/showcase/textures/levelTexture.png' );
			// mesh?.material?.lightMap = await textureLoader.fromAsset( 'assets/showcase/textures/lightmap.png' );
			// mesh?.material?.lightMap?.flipY = false;
			mesh?.material?.map?.anisotropy = 4;
      three.ColorManagement.legacyMode = false;

			models['level'] = renderComponent;
		} );

		// blaster, high poly
		await gltfLoader.fromAsset( 'blaster_high.glb').then(( gltf ) {
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['blaster_high'] = renderComponent;
		} );

		// await three.GLTFLoader().fromAsset( 'assets/models/gun.glb').then(( gltf ) async{
		// 	final weaponMesh = gltf?.scene.getObjectByName( 'BaseMesh' )?.children[ 0 ];
		// 	weaponMesh?.geometry?.scale( 0.1, 0.1, 0.1 );
		// 	weaponMesh?.geometry?.rotateX( math.pi * - 0.5 );
		// 	weaponMesh?.geometry?.rotateY( math.pi * 0.5 );
    //   weaponMesh?.geometry?.translate(0.3, -0.3, -1);
    //   weaponMesh?.matrixAutoUpdate = false;

		// 	models['blaster_high'] = weaponMesh;
		// } );

		// blaster, low poly
		await gltfLoader.fromAsset( 'blaster_low.glb').then(( gltf ){
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['blaster_low'] = renderComponent;
		} );

		// shotgun, high poly
		await gltfLoader.fromAsset( 'shotgun_high.glb').then(( gltf ) {
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ){
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['shotgun_high'] = renderComponent;
		} );

		// shotgun, low poly
		await gltfLoader.fromAsset( 'shotgun_low.glb').then(( gltf ) {
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['shotgun_low'] = renderComponent;
		} );

		// assault rifle, high poly
		await gltfLoader.fromAsset( 'assaultRifle_high.glb').then(( gltf ) {
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['assaultRifle_high'] = renderComponent;
		} );

		// assault rifle, low poly
		await gltfLoader.fromAsset( 'assaultRifle_low.glb').then(( gltf ){
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['assaultRifle_low'] = renderComponent;
		} );

		// health pack
		await gltfLoader.fromAsset( 'healthPack.glb').then(( gltf ){
			final renderComponent = gltf!.scene;
			renderComponent.matrixAutoUpdate = false;
			renderComponent.updateMatrix();

			renderComponent.traverse( ( object ) {
				object.matrixAutoUpdate = false;
				object.updateMatrix();
			} );

			models['healthPack'] = renderComponent;
		} );

		// muzzle sprite

		final muzzleTexture = await textureLoader.fromAsset( 'assets/showcase/textures/muzzle.png' );
		muzzleTexture?.matrixAutoUpdate = false;

		final muzzleMaterial = three.SpriteMaterial.fromMap( { 'map': muzzleTexture } );
		final muzzle = three.Sprite( muzzleMaterial );
		muzzle.matrixAutoUpdate = false;
		muzzle.visible = false;

		models['muzzle'] = muzzle;

		// bullet line

		final bulletLineGeometry = three.BufferGeometry();
		final bulletLineMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xfbf8e6 } );

		bulletLineGeometry.setFromPoints( [ Vector3(), Vector3( 0, 0, - 1 ) ] );

		final bulletLine = three.LineSegments( bulletLineGeometry, bulletLineMaterial );
		bulletLine.matrixAutoUpdate = false;

		models['bulletLine'] = bulletLine;

    return this;
	}

	/// Loads the navigation mesh from the backend.
	Future<AssetManager> _loadNavMesh() async{
		final navMeshLoader = this.navMeshLoader;

		await navMeshLoader.fromAsset( 'assets/showcase/nav/navmesh.glb' ).then( ( navMesh ) {
			this.navMesh = navMesh;
		} );

		//
    await YukaFileLoader().fromAsset('assets/showcase/nav/costTable.json').then((json){
			costTable = CostTable().fromJSON( jsonDecode(String.fromCharCodes(json!.data)));
    });

		return this;
	}
}
