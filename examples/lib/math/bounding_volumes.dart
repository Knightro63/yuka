import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/bv_helper.dart';
import 'package:examples/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class BoundingVolumes extends StatefulWidget {
  const BoundingVolumes({super.key});
  @override
  createState() => _State();
}

class _State extends State<BoundingVolumes> {
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true,
        shadowMapType: three.PCFSoftShadowMap
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          threeJs.build(),
          Text('			Demonstrates different types of auto-generated bounding volumes.'),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render()
            )
          ),
        ],
      ) 
    );
  }

	final Map<String,dynamic> params = {
		'boundingVolume': 'None'
	};
  final List<yuka.Vector3> points = [];
  three.Object3D? helper;

  Future<void> setup() async {
		threeJs.scene = three.Scene();
		threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
		threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 200 );

		threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 0.1, 250 );
		threeJs.camera.position.setValues( 10, 10, 30 );

		//

		final geometry = three.PlaneGeometry( 500, 500 );
		final material = three.MeshPhongMaterial.fromMap( { 'color': 0x999999, 'depthWrite': false } );

		final ground = three.Mesh( geometry, material );
		ground.rotation.x = - math.pi / 2;
		ground.matrixAutoUpdate = false;
		ground.receiveShadow = true;
		ground.updateMatrix();
		threeJs.scene.add( ground );

		//
		final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.6 );
		hemiLight.position.setValues( 0, 100, 0 );
		hemiLight.matrixAutoUpdate = false;
		hemiLight.updateMatrix();
		threeJs.scene.add( hemiLight );

		final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
		dirLight.position.setValues( - 40, 50, 50 );
		dirLight.matrixAutoUpdate = false;
		dirLight.updateMatrix();
		dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 25;
    dirLight.shadow?.camera?.bottom = - 25;
    dirLight.shadow?.camera?.left = - 25;
    dirLight.shadow?.camera?.right = 25;
    dirLight.shadow?.camera?.near = 1;
    dirLight.shadow?.camera?.far = 200;
    dirLight.shadow?.mapSize.x = 2048;
    dirLight.shadow?.mapSize.y = 2048;

		threeJs.scene.add( dirLight );

		// scene.add( three.CameraHelper( dirLight.shadow.camera ) );

		await three.GLTFLoader().fromAsset( 'assets/models/robot.glb').then( ( gltf ){
			// add object to scene
			late three.Object3D avatar;

			gltf?.scene.traverse( ( object ){
				if ( object is three.Mesh ) avatar = object;
			} );

			avatar.castShadow = true;

			//
			final geometry = avatar.geometry?.toNonIndexed();
			geometry?.applyMatrix4( avatar.matrixWorld ); // bake model transformation
			final position = geometry?.getAttributeFromString( 'position' );

			for ( int i = 0; i < position.count; i ++ ) {
				final x = position.getX( i );
				final y = position.getY( i );
				final z = position.getZ( i );

				points.add( yuka.Vector3( x, y, z ) );
			}

			threeJs.scene.add( avatar );
		} );

		// points
		final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
		controls.enablePan = false;
		controls.minDistance = 10;
		controls.maxDistance = 50;
		controls.target.setValues( 0.5, 8, 2.5 );
		controls.update();

		// dat.gui

		final gui = panel.addFolder('GUI')..open();
		final List<String> selection = [ 'None', 'BoundingSphere', 'AABB', 'OBB', 'ConvexHull' ];

		gui.addDropDown( params, 'boundingVolume', selection )..name = 'Volume'..onChange( ( value ) {
			if ( helper != null ) {
				helper!.material?.dispose();
				helper!.geometry?.dispose();

				threeJs.scene.remove( helper! );
			}

			switch ( value ) {
				case 'BoundingSphere':
					final boundingSphere = yuka.BoundingSphere().fromPoints( points );
					helper = BVHelper.createSphereHelper( boundingSphere );
					threeJs.scene.add( helper );
					break;
				case 'AABB':
					final aabb = yuka.AABB().fromPoints( points );
					helper = BVHelper.createAABBHelper( aabb );
					threeJs.scene.add( helper );
					break;
				case 'OBB':
					final obb = yuka.OBB().fromPoints( points );
					helper = BVHelper.createOBBHelper( obb );
					threeJs.scene.add( helper );
					break;
				case 'ConvexHull':
					final convexHull = yuka.ConvexHull().fromPoints( points );
					helper = BVHelper.createConvexHullHelper( convexHull );
					threeJs.scene.add( helper );
					break;
				default:
			}
		} );

		gui.open();
  }

	void onTransitionEnd(three.Event event ) {
		event.target.remove();
	}
}
