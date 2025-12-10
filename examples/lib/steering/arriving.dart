import 'dart:async';
import 'dart:math' as math;
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
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          threeJs.build(),
          Text('This steering behavior produces a force that directs an agent toward a target position. \nUnlike "Seek", it decelerates so the agent comes to a gentle halt at the target position.'),
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
  final yuka.GameEntity entity = yuka.GameEntity();
  final yuka.GameEntity target = yuka.GameEntity();
  final vehicle = yuka.Vehicle();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 0, 0, 10 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshNormalMaterial();

    final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    vehicleMesh.matrixAutoUpdate = false;
    threeJs.scene.add( vehicleMesh );

    final targetGeometry = three.SphereGeometry( 0.05 );
    final targetMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    final targetMesh = three.Mesh( targetGeometry, targetMaterial );
    targetMesh.matrixAutoUpdate = false;
    threeJs.scene.add( targetMesh );

    //
    final sphereGeometry = three.SphereGeometry( 2, 32, 32 );
    final sphereMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xcccccc, 'wireframe': true, 'transparent': true, 'opacity': 0.2 } );
    final sphere = three.Mesh( sphereGeometry, sphereMaterial );
    threeJs.scene.add( sphere );

    // game setup
    target.setRenderComponent( targetMesh, sync );
    vehicle.setRenderComponent( vehicleMesh, sync );

    final arriveBehavior = yuka.ArriveBehavior( target.position, 2.5, 0.1 );
    vehicle.steering.add( arriveBehavior );

    entityManager.add( target );
    entityManager.add( vehicle );

    time.reset();
    generateTarget(null);

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			entityManager.update( delta );
    });
    
    timer = Timer.periodic(Duration(milliseconds: 10000),generateTarget);
	}

  void generateTarget(e) {
    // generate a random point on a sphere
    final radius = 2.0;
    final phi = math.acos( ( 2 * math.Random().nextDouble() ) - 1 );
    final theta = math.Random().nextDouble() * math.pi * 2;

    target.position.fromSpherical( radius, phi, theta );
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
