import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringInterpose extends StatefulWidget {
  const SteeringInterpose({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringInterpose> {
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
  final pursuer = yuka.Vehicle();
  final yuka.Vector3 target1 = yuka.Vector3();
  final yuka.Vector3 target2 = yuka.Vector3();
  final vehicle = yuka.Vehicle();
  late final three.Line line;

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

    final targetGeometry = three.BoxGeometry( 0.2, 0.2, 0.2 );
    final targetMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    final entityMesh1 = three.Mesh( targetGeometry, targetMaterial );
    entityMesh1.matrixAutoUpdate = false;
    threeJs.scene.add( entityMesh1 );

    final entityMesh2 = three.Mesh( targetGeometry, targetMaterial );
    entityMesh2.matrixAutoUpdate = false;
    threeJs.scene.add( entityMesh2 );

    // helper

    final grid = GridHelper( 10, 25 );
    threeJs.scene.add( grid );

    final lineGeometry = three.BufferGeometry().setFromPoints( [ three.Vector3(), three.Vector3() ] );
    final lineMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xff0000 } );
    line = three.Line( lineGeometry, lineMaterial );
    threeJs.scene.add( line );

    // game setup
    entity1.maxSpeed = 2;
    entity1.setRenderComponent( entityMesh1, sync );

    final seekBehavior1 = yuka.SeekBehavior( target1 );
    entity1.steering.add( seekBehavior1 );

    entity2.maxSpeed = 2;
    entity2.setRenderComponent( entityMesh2, sync );

    final seekBehavior2 = yuka.SeekBehavior( target2 );
    entity2.steering.add( seekBehavior2 );

    pursuer.maxSpeed = 3;
    pursuer.setRenderComponent( pursuerMesh, sync );

    final interposeBehavior = yuka.InterposeBehavior( entity1, entity2, 1 );
    pursuer.steering.add( interposeBehavior );

    entityManager.add( entity1 );
    entityManager.add( entity2 );
    entityManager.add( pursuer );

    time.reset();

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			final elapsedTime = time.elapsed;

			target1.x = math.cos( elapsedTime * 0.1 ) * math.sin( elapsedTime * 0.1 ) * 6;
			target1.z = math.sin( elapsedTime * 0.3 ) * 6;

			target2.x = 1 + math.cos( elapsedTime * 0.5 ) * math.sin( elapsedTime * 0.3 ) * 4;
			target2.z = 1 + math.sin( elapsedTime * 0.3 ) * 6;

			entityManager.update( delta );

			// update line helper

			final positionAttribute = line.geometry?.attributes['position'];

			yuka.Vector3 position = entity1.position;
			positionAttribute.setXYZ( 0, position.x, position.y, position.z );

			position = entity2.position;
			positionAttribute.setXYZ( 1, position.x, position.y, position.z );

			positionAttribute.needsUpdate = true;
    });    
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
