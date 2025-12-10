import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringPursuit extends StatefulWidget {
  const SteeringPursuit({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringPursuit> {
  late Gui panel;
  Timer? timer;
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
          Text('"Pursuit" is useful when an agent is required to intercept a moving agent.'),
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
  final yuka.Vehicle evader = yuka.Vehicle();
  final yuka.Vehicle pursuer = yuka.Vehicle();
  final yuka.Vector3 target = yuka.Vector3();

  Map<String,dynamic> pb = {'predictionFactor': 0.0};

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 20, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final pursuerGeometry = three.ConeGeometry( 0.2, 1, 8 );
    pursuerGeometry.rotateX( math.pi * 0.5 );
    final pursuerMaterial = three.MeshNormalMaterial();

    final pursuerMesh = three.Mesh( pursuerGeometry, pursuerMaterial );
    pursuerMesh.matrixAutoUpdate = false;
    threeJs.scene.add( pursuerMesh );

    final evaderGeometry = three.BoxGeometry( 0.2, 0.2, 0.2 );
    final evaderMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    final evaderMesh = three.Mesh( evaderGeometry, evaderMaterial );
    evaderMesh.matrixAutoUpdate = false;
    threeJs.scene.add( evaderMesh );

    final grid = GridHelper( 10, 25 );
    threeJs.scene.add( grid );

    evader.maxSpeed = 3;
    evader.setRenderComponent( evaderMesh, sync );

    pursuer.maxSpeed = 3;
    pursuer.position.z = - 5;
    pursuer.setRenderComponent( pursuerMesh, sync );

    final pursuitBehavior = yuka.PursuitBehavior( evader, 2 );
    pursuer.steering.add( pursuitBehavior );

    final seekBehavior = yuka.SeekBehavior( target );
    evader.steering.add( seekBehavior );

    entityManager.add( evader );
    entityManager.add( pursuer );

    // dat.gui

    final gui = panel.addFolder('GUI')..open();
    pb['pursuitBehavior'] = pursuitBehavior.predictionFactor;

    gui.addSlider( pb, 'predictionFactor', 0, 5 )..name = 'factor'..onChange((v){
      pursuitBehavior.predictionFactor = v;
    });

    time.reset();

    threeJs.addAnimationEvent((dt){
			final deltaTime = time.update().delta;
			final elapsedTime = time.elapsed;

			target.z = math.cos( elapsedTime ) * math.sin( elapsedTime * 0.2 ) * 6;
			target.x = math.sin( elapsedTime * 0.8 ) * 6;

			entityManager.update( deltaTime );
    });    
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
