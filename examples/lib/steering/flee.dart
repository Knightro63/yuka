import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;

class SteeringFlee extends StatefulWidget {
  const SteeringFlee({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringFlee> {
  late three.ThreeJS threeJs;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          threeJs.build(),
          Text('This steering behavior produces a force that steers an agent away from a target position. \nThe target position is defined by the mouse cursor.'),
        ],
      ) 
    );
  }

	final yuka.EntityManager entityManager = yuka.EntityManager();
  final yuka.Time time = yuka.Time();
  final yuka.GameEntity entity = yuka.GameEntity();
  final vehicle = yuka.Vehicle();
  final target = yuka.Vector3();

  final three.Raycaster raycaster = three.Raycaster();
  final plane = three.Plane();
  final pointer = three.Vector2( 1, 1 );
  final three.Vector3 loc = three.Vector3();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 10, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );
    threeJs.camera.updateMatrixWorld();

    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshNormalMaterial();

    final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    vehicleMesh.matrixAutoUpdate = false;
    threeJs.scene.add( vehicleMesh );

    final grid = GridHelper( 10, 25 );
    threeJs.scene.add( grid );

    //
    plane.normal.setValues( 0, 1, 0 );

    //
    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, ( event ) {
      onPointerMove(event);
    });

    // game setup
    vehicle.setRenderComponent( vehicleMesh, sync );

    final fleeBehavior = yuka.FleeBehavior( target, 5 );
    vehicle.steering.add( fleeBehavior );

    entityManager.add( vehicle );

    threeJs.addAnimationEvent((dt){
			raycaster.setFromCamera( pointer, threeJs.camera );
			raycaster.ray.intersectPlane( plane, loc );

      target.fromArray(loc.storage);

			final delta = time.update().delta;
			entityManager.update( delta );
    });
  }

  void onPointerMove( event ) {
    final clientX = event.clientX ?? event.touches[ 0 ].clientX;
    final clientY = event.clientY ?? event.touches[ 0 ].clientY;

    pointer.x = ( clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( clientY / threeJs.height ) * 2 + 1;
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
