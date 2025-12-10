import 'dart:async';
import 'dart:math' as math;
import 'package:examples/goals/collectible.dart';
import 'package:examples/goals/girl.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class Goals extends StatefulWidget {
  const Goals({super.key});
  @override
  createState() => _State();
}

class _State extends State<Goals> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true
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
          Text('The main goal of the game entity is to gather collectibles. After a while, the game entity takes a short rest.\nThe Goal-driven agent design enables a clean implementation of more advanced AI logic.'),
          threeJs.build(),
          if(threeJs.mounted)Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 350,
              height: 75,
              color: Colors.grey[900],
              alignment: Alignment.center,
              child:Text(
                'Current Goal: ${girl.ui['currentGoal']}\nCurrent Subgoal: ${girl.ui['currentSubgoal']?.replaceAll('_', ' ')}',
                style: TextStyle(fontSize: 20),
              ),
            ),
          )
        ],
      ) 
    );
  }

  final yuka.EntityManager entityManager = yuka.EntityManager();
  final yuka.Time time = yuka.Time();
  late final Girl girl;
  late three.AnimationMixer mixer;
  String currentSubUi = '';
  String currentUi = '';

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 40 );

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( 0, 5, 15 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final groundGeometry = three.PlaneGeometry( 150, 150 );
    final groundMaterial = three.MeshPhongMaterial.fromMap( { 'color': 0x999999 } );

    final groundMesh = three.Mesh( groundGeometry, groundMaterial );
    groundMesh.rotation.x = - math.pi / 2;
    groundMesh.matrixAutoUpdate = false;
    groundMesh.receiveShadow = true;
    groundMesh.updateMatrix();
    threeJs.scene.add( groundMesh );

    //
    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.6 );
    hemiLight.position.setValues( 0, 100, 0 );
    hemiLight.matrixAutoUpdate = false;
    hemiLight.updateMatrix();
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
    dirLight.position.setValues( 4, 5, 5 );
    dirLight.matrixAutoUpdate = false;
    dirLight.updateMatrix();
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 10;
    dirLight.shadow?.camera?.bottom = - 10;
    dirLight.shadow?.camera?.left = - 10;
    dirLight.shadow?.camera?.right = 10;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 20;
    dirLight.shadow?.mapSize.x = 2048;
    dirLight.shadow?.mapSize.y = 2048;
    threeJs.scene.add( dirLight );

    await three.GLTFLoader().fromAsset( 'assets/models/yuka.glb').then(( gltf ){
      // add object to scene
      final avatar = gltf!.scene;
      avatar.matrixAutoUpdate = false;
      final temp = gltf.animations;
      final aanimations = <three.AnimationClip>[];

      for(int i = 0; i < temp!.length; i++){
        aanimations.add(temp[i] as three.AnimationClip);
      }

      avatar.traverse( ( object ){
        if ( object is three.Mesh ) {
          object.material?.transparent = true;
          object.material?.opacity = 1;
          object.material?.alphaTest = 0.7;
          object.material?.side = three.DoubleSide;
          object.castShadow = true;
        }
      } );

      threeJs.scene.add( avatar );

      mixer = three.AnimationMixer( avatar );
      final animations = <String,three.AnimationAction>{};

      animations['IDLE'] =  createAnimationAction( mixer, aanimations, 'Character_Idle' );
      animations['WALK'] = createAnimationAction( mixer, aanimations, 'Character_Walk' );
      animations['GATHER'] = createAnimationAction( mixer, aanimations, 'Character_Gather' );
      animations['RIGHT_TURN'] = createAnimationAction( mixer, aanimations, 'Character_RightTurn' );
      animations['LEFT_TURN'] = createAnimationAction( mixer, aanimations, 'Character_LeftTurn' );

      girl = Girl( mixer, animations );
      girl.setRenderComponent( avatar, sync );

      threeJs.scene.add( avatar );
      entityManager.add( girl );

      //
      final collectibleGeometry = three.BoxGeometry( 0.2, 0.2, 0.2 );
      collectibleGeometry.translate( 0, 0.1, 0 );
      final collectibleMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x040404 } );

      for ( int i = 0; i < 5; i ++ ) {
        final collectibleMesh = three.Mesh( collectibleGeometry, collectibleMaterial );
        collectibleMesh.matrixAutoUpdate = false;
        collectibleMesh.castShadow = true;

        final collectible = Collectible();
        collectible.setRenderComponent( collectibleMesh, sync );
        collectible.spawn();

        threeJs.scene.add( collectibleMesh );
        entityManager.add( collectible );
      }
    });

    time.reset();

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			entityManager.update( delta );

      if(currentUi != girl.ui['currentGoal'] || currentSubUi != girl.ui['currentSubgoal']){
        currentUi = girl.ui['currentGoal']!;
        currentSubUi = girl.ui['currentSubgoal']!;
        setState(() {});
      }
    });
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }

  three.AnimationAction createAnimationAction(three.AnimationMixer mixer, List<three.AnimationClip> clip, String name ) {
    final action = mixer.clipAction( three.AnimationClip.findByName(clip, name));
    action?.play();
    action?.enabled = false;

    return action!;
  }

  void onTransitionEnd(three.Event event ) {
    event.target.remove();
  }
}
