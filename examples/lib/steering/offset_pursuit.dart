import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringOffsetPursuit extends StatefulWidget {
  const SteeringOffsetPursuit({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringOffsetPursuit> {
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
          Text('"Interpose" produces a force that moves a vehicle to the midpoint of the imaginary line connecting two other agents.'),
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
  final yuka.Vehicle entity1 = yuka.Vehicle();
  final yuka.Vehicle entity2 = yuka.Vehicle();
  final yuka.Vector3 target = yuka.Vector3();
  final yuka.Vector3 target1 = yuka.Vector3();
  final yuka.Vector3 target2 = yuka.Vector3();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 20, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final vehicleGeometry = three.ConeGeometry( 0.2, 1, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshBasicMaterial();

    final leaderMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    leaderMesh.matrixAutoUpdate = false;
    threeJs.scene.add( leaderMesh );

    final followerMeshTemplate = three.Mesh( vehicleGeometry, vehicleMaterial );
    followerMeshTemplate.matrixAutoUpdate = false;

    final grid = GridHelper( 10, 25 );
    threeJs.scene.add( grid );

    // leader
    final leader = yuka.Vehicle();
    leader.setRenderComponent( leaderMesh, sync );

    final seekBehavior = yuka.SeekBehavior( target );
    leader.steering.add( seekBehavior );

    entityManager.add( leader );

    // follower

    final offsets = [
      yuka.Vector3( 0.5, 0, - 0.5 ),
      yuka.Vector3( - 0.5, 0, - 0.5 ),
      yuka.Vector3( 1.5, 0, - 1.5 ),
      yuka.Vector3( - 1.5, 0, - 1.5 )
    ];

    for ( int i = 0; i < 4; i ++ ) {
      final followerMesh = followerMeshTemplate.clone();
      threeJs.scene.add( followerMesh );

      final follower = yuka.Vehicle();
      follower.maxSpeed = 2;
      follower.position.copy( offsets[ i ] ); // initial position
      follower.scale.set( 0.5, 0.5, 0.5 ); // make the followers a bit smaller
      follower.setRenderComponent( followerMesh, sync );

      final offsetPursuitBehavior = yuka.OffsetPursuitBehavior( leader, offsets[ i ] );
      follower.steering.add( offsetPursuitBehavior );

      entityManager.add( follower );
    }

    time.reset();

    threeJs.addAnimationEvent((dt){
			time.update();

			final deltaTime = time.delta;
			final elapsedTime = time.elapsed;

			target.z = math.cos( elapsedTime * 0.2 ) * 5;
			target.x = math.sin( elapsedTime * 0.2 ) * 5;

			entityManager.update( deltaTime );
    });    
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
