import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/nav_mesh_helper.dart';
import 'package:examples/common/yuka_first_person_controls.dart';
import 'package:examples/navigation/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_lock/pointer_lock.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class FirstPersonNav extends StatefulWidget {
  const FirstPersonNav({super.key});
  @override
  createState() => _State();
}

class _State extends State<FirstPersonNav> {
  late three.ThreeJS threeJs;
  StreamSubscription<PointerLockMoveEvent>? _subscription;
  Offset lastPointerDelta = Offset.zero;
  bool isPlaying = false;

  @override
  void initState() {
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
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CallbackShortcuts(
      // Define the key combination to listen for
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _stopSession();
          },
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          child:Scaffold(
            body: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [
                threeJs.build(),
                if(!isPlaying)InkWell(
                  onTap: (){
                    if(threeJs.mounted){
                      setState(() {
                        isPlaying = true;
                        _startSession();
                        controls.connect();
                      });
                    }
                  },
                  child:Container(
                    padding: EdgeInsets.only(left: 20,right: 20),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withAlpha(128),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text(
                            'Click to Play',
                            style: TextStyle(fontSize: 48),
                          ),
                          SizedBox(height: 50),
                          Text(
                            'A navigation mesh defines the walkable area of this level.',
                            style: TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  )
                )
              ],
            ) 
          )
        )
      )
    );
  }

	final yuka.EntityManager entityManager = yuka.EntityManager();
  final yuka.Time time = yuka.Time();
  late final YukaFirstPersonControls controls;
  final player = Player();

  Future<void> setup() async {
    threeJs.scene = three.Scene();
		threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
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
		final glTFLoader = three.GLTFLoader();
		await glTFLoader.fromAsset( 'assets/models/house/house.glb').then( ( gltf ) async{
			// add object to scene
			threeJs.scene.add( gltf!.scene );
			gltf.scene.traverse( ( object ){
				object.matrixAutoUpdate = false;
				object.updateMatrix();
				if ( object is three.Mesh ) object.material?.alphaTest = 0.5;
			} );

			 await yuka.NavMeshLoader().fromAsset( 'assets/models/house/navmesh.glb', options: { 'epsilonCoplanarTest': 0.25 } ).then( ( navMesh ){
				// visualize convex regions
				final navMeshGroup = NavMeshHelper.createConvexRegionHelper( navMesh! );
				threeJs.scene.add( navMeshGroup );
				player.navMesh = navMesh;
			} );
		} );

		// game setup
		
		player.head.setRenderComponent( threeJs.camera, sync );
		player.position.set( - 13, - 0.75, - 9 );

		controls = YukaFirstPersonControls( player, threeJs , false );
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
      controls.update( delta );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    final three.Matrix4 m = three.Matrix4().copyFromArray( entity.worldMatrix().elements);
    renderComponent.position.setFromMatrixPosition(m);
    renderComponent.quaternion.setFromRotationMatrix(m);
    renderComponent.updateMatrix();  
  }

  void _startSession() {
    if (_subscription != null) {
      return;
    }
    final deltaStream = pointerLock.createSession(
      windowsMode: PointerLockWindowsMode.capture,
      cursor: PointerLockCursor.hidden,
    );
    final subscription = deltaStream.listen(
      (event) {
        _processMoveDelta(event.delta);
      },
      onDone: () {
        // Stream closed naturally
        _setSubscription(null);
      },
      onError: (error) {
        // Handle any errors
        debugPrint('Pointer lock error: $error');
        _setSubscription(null);
      },
    );
    _setSubscription(subscription);
  }

  void _stopSession() async {
    final subscription = _subscription;
    if (subscription == null) {
      return;
    }
    _setSubscription(null);
    await subscription.cancel();
  }

  void _setSubscription(StreamSubscription<PointerLockMoveEvent>? value) {
    _subscription = value;
  }

  void _processMoveDelta(Offset delta) {
    if (!mounted) {
      return;
    }
    lastPointerDelta = delta;
    threeJs.domElement.overrideEmit(three.PeripheralType.pointerHover,three.WebPointerEvent()..movementX = lastPointerDelta.dx ..movementY = lastPointerDelta.dy);
  }
}
