import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringWander extends StatefulWidget {
  const SteeringWander({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringWander> {
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
          Text('This steering behavior produces a force that directs an agent toward a target position.'),
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
  final yuka.Vehicle vehicle = yuka.Vehicle();
  final yuka.Vehicle pursuer = yuka.Vehicle();
  final yuka.GameEntity target = yuka.GameEntity();

  Map<String,dynamic> pb = {'predictionFactor': 0.0};

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 20, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshNormalMaterial();

    for ( int i = 0; i < 50; i ++ ) {

      final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
      vehicleMesh.matrixAutoUpdate = false;
      threeJs.scene.add( vehicleMesh );

      final vehicle = yuka.Vehicle();
      vehicle.rotation.fromEuler( 0, 2 * math.pi * math.Random().nextDouble(), 0 );
      vehicle.position.x = 2.5 - math.Random().nextDouble() * 5;
      vehicle.position.z = 2.5 - math.Random().nextDouble() * 5;
      vehicle.setRenderComponent( vehicleMesh, sync );

      final wanderBehavior = yuka.WanderBehavior();
      vehicle.steering.add( wanderBehavior );

      entityManager.add( vehicle );

    }

    final grid = GridHelper( 20, 50 );
    threeJs.scene.add( grid );

    time.reset();

    threeJs.addAnimationEvent((dt){
			final deltaTime = time.update().delta;
			entityManager.update( deltaTime );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
