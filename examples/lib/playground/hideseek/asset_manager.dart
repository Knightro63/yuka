import 'package:examples/playground/common/asset_manager.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;

class HSAssetManager extends AssetManager{
  @override
	Future<void> init() async{
		await _loadModels();
		_loadAnimations();
	}

	Future<void> _loadModels() async{
		final textureLoader = this.textureLoader;
		final models = this.models;

		// weapon
		await three.GLTFLoader(manager: loadingManager ).fromAsset( 'assets/models/shotgun.glb').then(( gltf ) async{
			final weaponMesh = gltf?.scene.getObjectByName( 'UntitledObjcleanergles' )?.children[ 0 ];
			weaponMesh?.geometry?.scale( 0.00045, 0.00045, 0.00045 );
			weaponMesh?.geometry?.rotateX( math.pi * - 0.5 );
			weaponMesh?.geometry?.rotateY( math.pi * - 0.5 );
      weaponMesh?.geometry?.translate(0.25, -0.3, -1);

			models['weapon'] = weaponMesh;

			//
			final texture = await textureLoader.fromAsset( 'assets/textures/muzzle.png' );
			final material = three.SpriteMaterial.fromMap( {'map': texture} );
			final sprite = three.Sprite( material );

			sprite.position.setValues( 0.55, -0.2, - 2 );
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

		models['ground'] = groundMesh;

		// enemy
		three.BufferGeometry enemyGeometry = three.ConeGeometry( 0.2, 1, 8, 4 );
		enemyGeometry = enemyGeometry.toNonIndexed();
		enemyGeometry.rotateX( math.pi * 0.5 );
		enemyGeometry.translate( 0, 0.5, 0 );
		enemyGeometry.computeBoundingSphere();

		final position = enemyGeometry.attributes['position'].array.toDartList();

		final scatter = <double>[];
		final scatterFactor = 0.5;

		for ( int i = 0; i < position.length; i += 3 ) {
			final x = ( 1 - math.Random().nextDouble() * 2 ) * scatterFactor;
			final y = ( 1 - math.Random().nextDouble() * 2 ) * scatterFactor;
			final z = ( 1 - math.Random().nextDouble() * 2 ) * scatterFactor;

			scatter.addAll( [x, y, z] );
			scatter.addAll( [x, y, z] );
			scatter.addAll( [x, y, z] );
		}

		enemyGeometry.setAttributeFromString( 'scatter', three.Float32BufferAttribute.fromList( scatter, 3 ) );

		final extent = <double>[];

		for ( int i = 0; i < position.length; i += 3 ) {
			final x = 5 + math.Random().nextDouble() * 5;

			extent.add( x );
			extent.add( x );
			extent.add( x );
		}

		enemyGeometry.setAttributeFromString( 'extent', three.Float32BufferAttribute.fromList( extent, 1 ) );

		final enemyMesh = three.Mesh( enemyGeometry );
		enemyMesh.castShadow = true;
		enemyMesh.matrixAutoUpdate = false;

		models['enemy'] = enemyMesh;

		// obstacle
		final obstacleGeometry = three.BoxGeometry( 4, 8, 4 );
		obstacleGeometry.translate( 0, 4, 0 );
		obstacleGeometry.computeBoundingSphere();
		final obstacleMaterial = three.MeshStandardMaterial.fromMap( { 'color': 0x040404, 'dithering': true } );

		final obstacleMesh = three.Mesh( obstacleGeometry, obstacleMaterial );
		obstacleMesh.castShadow = true;
		obstacleMesh.matrixAutoUpdate = false;

		models['obstacle'] = obstacleMesh;
	}

	void _loadAnimations() {
		final animations = this.animations;

		// shot
		three.VectorKeyframeTrack positionKeyframes = three.VectorKeyframeTrack( '.position', [ 0, 0.05, 0.15, 0.3 ],
    [
			0, 0, 0,
			0, -0.1, 0.3,
			0, -0.005, 0,
		 	0, 0, 0 
    ]
		);

		final q0 = three.Quaternion();
		three.Quaternion q1 = three.Quaternion().setFromAxisAngle( three.Vector3( 0.2, 0, 0 ), 0.2 );
		final q2 = three.Quaternion().setFromAxisAngle( three.Vector3( 0.2, 0, 0 ),  -0.02 );

		three.QuaternionKeyframeTrack rotationKeyframes = three.QuaternionKeyframeTrack( '.quaternion', [ 0, 0.05, 0.15, 0.3 ], [
			q0.x, q0.y, q0.z, q0.w,
			q1.x, q1.y, q1.z, q1.w,
			q2.x, q2.y, q2.z, q2.w,
			q0.x, q0.y, q0.z, q0.w ]
		);

		final shotClip = three.AnimationClip( 'Shot', 0.3, [ positionKeyframes, rotationKeyframes ] );
		animations['shot'] = shotClip;

		// reload
		positionKeyframes = three.VectorKeyframeTrack( '.position', [ 0, 0.2, 1.3, 1.5 ], [
			0, 0, 0,
			0, 0, 0,
			0, 0, 0,
			0, 0, 0 ]
		);

		q1 = three.Quaternion().setFromAxisAngle( three.Vector3( 0.5, 0, 0 ), - 0.4 );

		rotationKeyframes = three.QuaternionKeyframeTrack( '.quaternion', [ 0, 0.2, 1.3, 1.5 ], [
			q0.x, q0.y, q0.z, q0.w,
			q1.x, q1.y, q1.z, q1.w,
			q1.x, q1.y, q1.z, q1.w,
			q0.x, q0.y, q0.z, q0.w ]
		);

		final reloadClip = three.AnimationClip( 'Reload', 1.5, [ positionKeyframes, rotationKeyframes ] );
		animations['reload'] = reloadClip;
	}
}
