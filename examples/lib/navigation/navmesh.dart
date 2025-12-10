import 'dart:async';
import 'dart:math' as math;
import 'package:examples/navigation/player.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringArrive extends StatefulWidget {
  const SteeringArrive({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringArrive> {
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
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
          Text('A navigation mesh defines the walkable area of this level.'),
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

	final yuka.EntityManager entityManager = yuka.EntityManager();
  final yuka.Time time = yuka.Time();
  late final three.FirstPersonControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
		threeJs.scene.background = three.Color( 0xa0a0a0 );
		threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 40 );

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.camera.matrixAutoUpdate = false;

		final geometry = three.PlaneGeometry( 150, 150 );
		final material = three.MeshPhongMaterial.fromMap( { 'color': 0x999999, 'depthWrite': false } );

		final ground = three.Mesh( geometry, material );
		ground.rotation.x = - math.pi / 2;
		ground.matrixAutoUpdate = false;
		ground.updateMatrix();
		threeJs.scene.add( ground );

		//

		final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.6 );
		hemiLight.position.setValues( 0, 100, 0 );
		threeJs.scene.add( hemiLight );

		final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
		dirLight.position.setValues( 0, 20, 10 );
		threeJs.scene.add( dirLight );

		//

		final loadingManager = three.LoadingManager( (){

			// 3D assets are loaded, now load nav mesh

			final loader = yuka.NavMeshLoader();
			loader.load( './navmesh/navmesh.glb', { epsilonCoplanarTest: 0.25 } ).then( ( navMesh ) => {

				// visualize convex regions

				// const navMeshGroup = createConvexRegionHelper( navMesh );
				// scene.add( navMeshGroup );

				player.navMesh = navMesh;

				const loadingScreen = document.getElementById( 'loading-screen' );

				loadingScreen.classList.add( 'fade-out' );
				loadingScreen.addEventListener( 'transitionend', onTransitionEnd );

				animate();

			} );

		} );

		//
		final glTFLoader = three.GLTFLoader( );//loadingManager );
		glTFLoader.fromAsset( 'assets/models/house/house.glb').then( ( gltf ){
			// add object to scene
			threeJs.scene.add( gltf!.scene );
			gltf.scene.traverse( ( object ){
				object.matrixAutoUpdate = false;
				object.updateMatrix();
				if ( object is three.Mesh ) object.material?.alphaTest = 0.5;
			} );
		} );

		// game setup
		final player = Player();
		player.head.setRenderComponent( threeJs.camera, sync );
		player.position.set( - 13, - 0.75, - 9 );

		controls = three.FirstPersonControls( camera: threeJs.camera, listenableKey: threeJs.globalKey );
		controls.setRotation( - 2.2, 0.2 );

		// controls.addEventListener( 'lock', ( ){
		// 	intro.classList.add( 'hidden' );
		// } );

		// controls.addEventListener( 'unlock', () {
		// 	intro.classList.remove( 'hidden' );
		// } );

		entityManager.add( player );

    time.reset();

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			entityManager.update( delta );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
