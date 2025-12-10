import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;

class AssetManager {
  final loadingManager = three.LoadingManager();
	late final textureLoader = three.TextureLoader(manager: loadingManager );

	final Map<String,dynamic> animations = {};
	final Map<String,dynamic> models = {};


	Future<void> init() async{
		await _loadModels();
		_loadAnimations();
	}

	Future<void> _loadModels() async{
		final textureLoader = this.textureLoader;
		final models = this.models;

		// target
		await three.GLTFLoader(manager: loadingManager ).fromAsset( 'assets/models/target.glb').then(( gltf ){
			final targetMesh = gltf?.scene.getObjectByName( 'LowPoly003__0' );
			targetMesh?.geometry?.scale( 0.5, 0.5, 0.5 );
			targetMesh?.geometry?.rotateX( math.pi * 0.5 );
			targetMesh?.geometry?.rotateY( math.pi );
			targetMesh?.geometry?.rotateZ( math.pi );
			targetMesh?.matrixAutoUpdate = false;
			targetMesh?.castShadow = true;

			models['target'] = targetMesh;
		});

		// weapon
		await three.GLTFLoader(manager: loadingManager ).fromAsset( 'assets/models/gun.glb').then(( gltf ) async{
			final weaponMesh = gltf?.scene.getObjectByName( 'BaseMesh' )?.children[ 0 ];
			weaponMesh?.geometry?.scale( 0.1, 0.1, 0.1 );
			weaponMesh?.geometry?.rotateX( math.pi * - 0.5 );
			weaponMesh?.geometry?.rotateY( math.pi * 0.5 );
			weaponMesh?.matrixAutoUpdate = false;

			models['weapon'] = weaponMesh;

			//
			final texture = await textureLoader.fromAsset( 'assets/textures/muzzle.png' );

			final material = three.SpriteMaterial.fromMap( {'map': texture} );
      final sprite = three.Sprite( material );

			sprite.position.setValues( 0, 0.13, - 0.4 );
			sprite.scale.setValues( 0.3, 0.3, 0.3 );
			sprite.visible = false;

			models['muzzle'] = sprite;
			weaponMesh?.add( sprite );
		} );

		// bullet hole

		final texture = await textureLoader.fromAsset( 'assets/textures/bulletHole.png' );
		texture?.minFilter = three.LinearFilter;
		final bulletHoleGeometry = three.PlaneGeometry( 0.1, 0.1 );
		final bulletHoleMaterial = three.MeshLambertMaterial.fromMap( { 'map': texture, 'transparent': true, 'depthWrite': false, 'polygonOffset': true, 'polygonOffsetFactor': - 4 } );

		final bulletHole = three.Mesh( bulletHoleGeometry, bulletHoleMaterial );
		bulletHole.matrixAutoUpdate = false;

		models['bulletHole'] = bulletHole;

		// bullet line

		final bulletLineGeometry = three.BufferGeometry();
		final bulletLineMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xfbf8e6 } );

		bulletLineGeometry.setFromPoints( [ three.Vector3(), three.Vector3( 0, 0, - 1 ) ] );

		final bulletLine = three.LineSegments( bulletLineGeometry, bulletLineMaterial );
		bulletLine.matrixAutoUpdate = false;

		models['bulletLine'] = bulletLine;

		// ground

		final groundGeometry = three.PlaneGeometry( 200, 200 );
		groundGeometry.rotateX( - math.pi / 2 );
		final groundMaterial = three.MeshPhongMaterial.fromMap( { 'color': 0x999999 } );

		final groundMesh = three.Mesh( groundGeometry, groundMaterial );
		groundMesh.matrixAutoUpdate = false;
		groundMesh.receiveShadow = true;

		models['ground'] = groundMesh ;
	}

	void _loadAnimations() {
		final animations = this.animations;

		// manually create some keyframes for testing
		three.KeyframeTrack positionKeyframes, rotationKeyframes;
		three.Quaternion q0, q1, q2;

		// shot
		positionKeyframes = three.VectorKeyframeTrack( '.position', [ 0, 0.05, 0.15, 0.3 ], [
			0.3, - 0.3, - 1,
			0.3, - 0.2, - 0.7,
			0.3, - 0.305, - 1,
		 	0.3, - 0.3, - 1 ]
		);

		q0 = three.Quaternion();
		q1 = three.Quaternion().setFromAxisAngle( three.Vector3( 1, 0, 0 ), 0.2 );
		q2 = three.Quaternion().setFromAxisAngle( three.Vector3( 1, 0, 0 ), - 0.02 );

		rotationKeyframes = three.QuaternionKeyframeTrack( '.rotation', [ 0, 0.05, 0.15, 0.3 ], [
			q0.x, q0.y, q0.z, q0.w,
			q1.x, q1.y, q1.z, q1.w,
			q2.x, q2.y, q2.z, q2.w,
			q0.x, q0.y, q0.z, q0.w ]
		);

		final shotClip = three.AnimationClip( 'Shot', 0.3, [ positionKeyframes, rotationKeyframes ] );
		animations['shot'] =  shotClip;

		// reload
		positionKeyframes = three.VectorKeyframeTrack( '.position', [ 0, 0.2, 1.3, 1.5 ], [
			0.3, - 0.3, - 1,
			0.3, - 0.6, - 1,
			0.3, - 0.6, - 1,
			0.3, - 0.3, - 1 ]
		);

		q1 = three.Quaternion().setFromAxisAngle( three.Vector3( 1, 0, 0 ), - 0.4 );

		rotationKeyframes = three.QuaternionKeyframeTrack( '.rotation', [ 0, 0.2, 1.3, 1.5 ], [
			q0.x, q0.y, q0.z, q0.w,
			q1.x, q1.y, q1.z, q1.w,
			q1.x, q1.y, q1.z, q1.w,
			q0.x, q0.y, q0.z, q0.w ]
		);

		final reloadClip = three.AnimationClip( 'Reload', 1.5, [ positionKeyframes, rotationKeyframes ] );
		animations['reload'] = reloadClip;
	}
}
