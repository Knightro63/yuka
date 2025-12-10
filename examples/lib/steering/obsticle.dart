import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringObsticle extends StatefulWidget {
  const SteeringObsticle({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringObsticle> {
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
  final vehicle = yuka.Vehicle();
  final obstacles = <yuka.GameEntity>[];

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 30, 25, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final vehicleGeometry = three.ConeGeometry( 0.5, 2, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    vehicleGeometry.computeBoundingSphere();
    final vehicleMaterial = three.MeshNormalMaterial();

    final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    vehicleMesh.matrixAutoUpdate = false;
    threeJs.scene.add( vehicleMesh );

    final ambientLight = three.AmbientLight( 0xcccccc, 0.4 );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.8 );
    directionalLight.position.setValues( 1, 1, 0 ).normalize();
    threeJs.scene.add( directionalLight );

    final gridHelper = GridHelper( 25, 25 );
    threeJs.scene.add( gridHelper );


    final path = yuka.Path();
    path.loop = true;
    path.add( yuka.Vector3( 10, 0, 10 ) );
    path.add( yuka.Vector3( 10, 0, - 10 ) );
    path.add( yuka.Vector3( - 10, 0, - 10 ) );
    path.add( yuka.Vector3( - 10, 0, 10 ) );

    vehicle.maxSpeed = 3;
    vehicle.setRenderComponent( vehicleMesh, sync );

    vehicle.boundingRadius = vehicleGeometry.boundingSphere!.radius;
    vehicle.smoother = yuka.Smoother( 20 );

    entityManager.add( vehicle );

    final obstacleAvoidanceBehavior = yuka.ObstacleAvoidanceBehavior( obstacles );
    vehicle.steering.add( obstacleAvoidanceBehavior );

    final followPathBehavior = yuka.FollowPathBehavior( path );
    vehicle.steering.add( followPathBehavior );

    // obstacles

    setupObstacles();

    time.reset();

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			entityManager.update( delta );
    });
	}

  setupObstacles() {
    final geometry = three.BoxGeometry( 2, 2, 2 );
    geometry.computeBoundingSphere();
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xff0000 } );

    final mesh1 = three.Mesh( geometry, material );
    final mesh2 = three.Mesh( geometry, material );
    final mesh3 = three.Mesh( geometry, material );

    mesh1.position.setValues( - 10, 0, 0 );
    mesh2.position.setValues( 12, 0, 0 );
    mesh3.position.setValues( 4, 0, - 10 );

    threeJs.scene.add( mesh1 );
    threeJs.scene.add( mesh2 );
    threeJs.scene.add( mesh3 );

    final obstacle1 = yuka.GameEntity();
    obstacle1.position.fromArray( mesh1.position.storage );
    obstacle1.boundingRadius = geometry.boundingSphere!.radius;
    entityManager.add( obstacle1 );
    obstacles.add( obstacle1 );

    final obstacle2 = yuka.GameEntity();
    obstacle2.position.fromArray( mesh2.position.storage );
    obstacle2.boundingRadius = geometry.boundingSphere!.radius;
    entityManager.add( obstacle2 );
    obstacles.add( obstacle2 );

    final obstacle3 = yuka.GameEntity();
    obstacle3.position.fromArray( mesh3.position.storage );
    obstacle3.boundingRadius = geometry.boundingSphere!.radius;
    entityManager.add( obstacle3 );
    obstacles.add( obstacle3 );
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
