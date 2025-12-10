import 'dart:async';
import 'dart:math' as math;
import 'package:examples/fsm/girl.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class FSM extends StatefulWidget {
  const FSM({super.key});
  @override
  createState() => _State();
}

class _State extends State<FSM> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true,
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
          Text('			The game entity continuously changes its status between "IDLE" and "WALK".\nThe State-driven agent design enables a clean implementation of basic AI logic.'),
          if(threeJs.mounted)Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 350,
              height: 75,
              color: Colors.grey[900],
              alignment: Alignment.center,
              child: Text(
                'Current State: ${girl.ui['currentState']}',
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
  late final Girl girl;
  String currentUI = 'IDLE';

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 40 );

    threeJs.camera = three.PerspectiveCamera( 45,threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( 0, 2, - 4 );

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
    dirLight.position.setValues( - 4, 5, - 5 );
    dirLight.matrixAutoUpdate = false;
    dirLight.updateMatrix();
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 2;
    dirLight.shadow?.camera?.bottom = - 2;
    dirLight.shadow?.camera?.left = - 2;
    dirLight.shadow?.camera?.right = 2;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 20;
    threeJs.scene.add( dirLight );

    //
    final glTFLoader = three.GLTFLoader();
    final gltf = await glTFLoader.fromAsset( 'assets/models/yuka.glb');
    // add object to scene
    final avatar = gltf!.scene;
      final temp = gltf.animations;
      final aanimations = <three.AnimationClip>[];

      for(int i = 0; i < temp!.length; i++){
        aanimations.add(temp[i] as three.AnimationClip);
      }

    avatar.traverse( ( object ) {
      if ( object is three.Mesh ) {
        object.material?.transparent = true;
        object.material?.opacity = 1;
        object.material?.alphaTest = 0.7;
        object.material?.side = three.DoubleSide;
        object.castShadow = true;
      }
    });

    avatar.add( threeJs.camera );

    target.setFrom( avatar.position );
    target.y += 1;
    threeJs.camera.lookAt( target );

    threeJs.scene.add( avatar );

    mixer = three.AnimationMixer( avatar );
    final animations = <String,three.AnimationAction>{};

    final idleAction = mixer.clipAction(three.AnimationClip.findByName(aanimations, 'Character_Idle'))?.play();//'Character_Idle' );
    idleAction?.enabled = false;

    final walkAction = mixer.clipAction(three.AnimationClip.findByName(aanimations, 'Character_Walk'))?.play();// 'Character_Walk' );
    walkAction?.enabled = false;

    animations['IDLE'] = idleAction!;
    animations['WALK'] = walkAction!;

    girl = Girl( mixer, animations );
    entityManager.add( girl );

    threeJs.addAnimationEvent((dt){
      final delta = time.update().delta;
      entityManager.update( delta );

      if(currentUI != girl.ui['currentState']){
        currentUI = girl.ui['currentState']!;
        setState(() {});
      }
    });
  }
}
