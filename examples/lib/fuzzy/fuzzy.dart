import 'dart:async';
import 'dart:math' as math;
import 'package:examples/fuzzy/solider.dart';
import 'package:examples/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;

class Fuzzy extends StatefulWidget {
  const Fuzzy({super.key});
  @override
  createState() => _State();
}

class _State extends State<Fuzzy> {
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
          Text('The soldier uses fuzzy inference to determine the best weapon\nbased on the distance to the enemy and the available ammo.'),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render()
            )
          ),
          if(threeJs.mounted)Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 350,
              height: 75,
              color: Colors.grey[900],
              alignment: Alignment.center,
              child:Text(
                'Current Weapon: ${( assaultRifle.visible ) ? 'Assault Rifle' : 'Shotgun'}',
                style: TextStyle(fontSize: 20),
              ),
            ),
          )
        ],
      ) 
    );
  }

  final target = three.Vector3();
  final yuka.EntityManager entityManager = yuka.EntityManager();
  final yuka.Time time = yuka.Time();
  late three.AnimationMixer mixer;

  final List<three.AnimationMixer> mixers = [];
  late final Soldier soldier;
  late final yuka.GameEntity zombie;
  late final three.Object3D shotgun;
  late final three.Object3D assaultRifle;

  final Map<String,dynamic> params = {
    'distance': 8.0,
    'ammoShotgun': 12.0,
    'ammoAssaultRifle': 30.0
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 40 );

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( - 0.5, 2, - 2.5 );
    threeJs.camera.lookAt(three.Vector3( 0, 0, 15 ));

    //
    final geometry = three.PlaneGeometry( 150, 150 );
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
    dirLight.position.setValues( - 10, 10, 10 );
    dirLight.matrixAutoUpdate = false;
    dirLight.updateMatrix();
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 2;
    dirLight.shadow?.camera?.bottom = - 2;
    dirLight.shadow?.camera?.left = - 10;
    dirLight.shadow?.camera?.right = 10;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 20;
    dirLight.shadow?.mapSize.x = 2048;
    dirLight.shadow?.mapSize.y = 2048;
    dirLight.target?.position.setValues( 0, 0, 10 );
    threeJs.scene.addAll([ dirLight, dirLight.target! ]);

    threeJs.scene.add( PolarGridHelper( 20, 20 ) );

    // load soldier
    await three.GLTFLoader( ).fromAsset( 'assets/models/soldier.glb').then(( gltf ) {
      // add object to scene
      final renderComponent = gltf!.scene;
      final animations = gltf.animations;
      renderComponent.matrixAutoUpdate = false;

      renderComponent.traverse( ( object ){
        if ( object is three.Mesh ) {
          object.material?.side = three.DoubleSide;
          object.castShadow = true;
          object.matrixAutoUpdate = false;
        }
      } );

      final mixer = three.AnimationMixer( renderComponent );
      mixers.add( mixer );

      final idleAction = mixer.clipAction( animations![0] );
      idleAction?.play();

      //
      soldier = Soldier();
      soldier.rotation.fromEuler( 0, math.pi * - 0.05, 0 );
      soldier.setRenderComponent( renderComponent, sync );

      entityManager.add( soldier );
      threeJs.scene.add( renderComponent );
    } );

    // load zombie

    await three.GLTFLoader( ).fromAsset( 'assets/models/zombie.glb').then(( gltf ){
      final renderComponent = gltf!.scene;
      final animations = gltf.animations;
      renderComponent.matrixAutoUpdate = false;

      renderComponent.traverse( ( object ){
        if ( object is three.Mesh ) {
          object.material?.side = three.DoubleSide;
          object.castShadow = true;
          object.matrixAutoUpdate = false;
        }
      } );

      final mixer = three.AnimationMixer( renderComponent );
      mixers.add( mixer );

      final idleAction = mixer.clipAction( animations![0] );
      idleAction?.play();

      //
      zombie = yuka.GameEntity();
      zombie.name = 'zombie';
      zombie.position.set( 0, 0, params['distance'] );
      zombie.setRenderComponent( renderComponent, sync );

      entityManager.add( zombie );
      threeJs.scene.add( renderComponent );
    } );

    // load shotgun
    await three.GLTFLoader( ).fromAsset( 'assets/models/shotgun.glb').then(( gltf ){
      shotgun = gltf!.scene;
      shotgun.traverse( ( object ){
        if ( object is three.Mesh ) object.castShadow = true;
      } );
      shotgun.scale.setValues( 0.35, 0.35, 0.35 );
      shotgun.rotation.set( math.pi * 0.5, math.pi * - 0.45, 0.1 );
      shotgun.position.setValues( - 50, 300, 0 );
    } );

    // load assault rifle
    await three.GLTFLoader( ).fromAsset( 'assets/models/assaultRifle.glb').then(( gltf ){
      assaultRifle = gltf!.scene;
      assaultRifle.traverse( ( object ){
        if ( object is three.Mesh ) object.castShadow = true;
      } );
      assaultRifle.scale.scale( 150 );
      assaultRifle.rotation.set( math.pi * 0.45, math.pi * 0.55, 0 );
      assaultRifle.position.setValues( - 30, 200, 70 );
    } );

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;

			if ( mixers.isNotEmpty ) {
				for ( int i = 0, l = mixers.length; i < l; i ++ ) {
					mixers[ i ].update( delta );
				}
			}

			entityManager.update( delta );
    });

    final rightHand = (soldier.renderComponent as three.Object3D).getObjectByName( 'Armature_mixamorigRightHand' );
    rightHand?.add( assaultRifle );
    rightHand?.add( shotgun );

    soldier.assaultRifle = assaultRifle;
    soldier.shotgun = shotgun;

    zombie.lookAt( soldier.position );

    //
    initUI();
  }

  void initUI() {
    final gui = panel.addFolder('GUI')..open();

    gui.addSlider( params, 'distance', 5, 20 )..name = 'Distance'..onChange( ( value ){
      zombie.position.z = value;
    } );

    gui.addSlider( params, 'ammoShotgun', 0, 12 )..name = 'Shells'..onChange( ( value ){
      soldier.ammoShotgun = value;
    } );

    gui.addSlider( params, 'ammoAssaultRifle', 0, 30 )..name = 'Bullets'..onChange( ( value ){
      soldier.ammoAssaultRifle = value;
    } );
  }

  void onTransitionEnd(three.Event event ) {
    event.target.remove();
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
