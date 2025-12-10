import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/obstacle.dart';
import 'package:examples/common/vision_helper.dart';
import 'package:examples/memory_system/custom_entity.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class MemorySystem extends StatefulWidget {
  const MemorySystem({super.key});
  @override
  createState() => _State();
}

class _State extends State<MemorySystem> {
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
          Text('The game entity uses a memory system to remember the last sensed position of the target.\nIf the target is outside the game entity\'s visual range for a certain amout of time, \nthe game entity forgets the target.'),
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
  final yuka.GameEntity entity = CustomEntity();
  final yuka.GameEntity target = yuka.GameEntity();
  final targetMaterial = three.MeshBasicMaterial();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 0, 10, 10 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final entityGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    entityGeometry.rotateX( math.pi * 0.5 );
    final entityMaterial = three.MeshNormalMaterial();

    final entityMesh = three.Mesh( entityGeometry, entityMaterial );
    entityMesh.matrixAutoUpdate = false;
    threeJs.scene.add( entityMesh );

    final obstacleGeometry = three.PlaneGeometry( 2, 2, 5, 5 );
    final obstacleMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x777777, 'side': three.DoubleSide } );

    final obstacleMesh = three.Mesh( obstacleGeometry, obstacleMaterial );
    obstacleMesh.matrixAutoUpdate = false;
    obstacleMesh.position.setValues( 0,0,3 ); 
    threeJs.scene.add( obstacleMesh );

    final targetGeometry = three.SphereGeometry( 0.05 );

    final targetMesh = three.Mesh( targetGeometry, targetMaterial );
    targetMesh.matrixAutoUpdate = false;
    threeJs.scene.add( targetMesh );

    //
    final grid = GridHelper( 10, 25 );
    threeJs.scene.add( grid );

    final vertices = obstacleGeometry.attributes['position'].array as three.Float32Array;
    final indices = obstacleGeometry.index?.array;
    final geometry = yuka.MeshGeometry( vertices.toDartList(), indices?.toList().map((e) => e.toInt()).toList() );

    final obstacle = Obstacle( geometry );
    obstacle.name = 'obstacle';
    obstacle.rotation.fromEuler(math.pi,0,0);
    obstacle.position.fromArray( obstacleMesh.position.storage );
    obstacle.setRenderComponent( obstacleMesh, sync );

    target.setRenderComponent( targetMesh, sync );
    target.name = 'target';
    entity.setRenderComponent( entityMesh, sync );

    final helper = YukaVisionHelper( entity.vision!,16, 4 );
    threeJs.scene.add( helper );
    entityMesh.add( helper );

    entityManager.add( entity );
    entityManager.add( obstacle );
    entityManager.add( target );

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			final elapsed = time.elapsed;

			// change color of target if visible
			target.position.set( math.sin( elapsed * 0.3 ) * 4, 0, 4 );
			entityManager.update( delta );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
