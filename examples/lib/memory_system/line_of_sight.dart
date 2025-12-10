import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/obstacle.dart';
import 'package:examples/common/vision_helper.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class LineOfSight extends StatefulWidget {
  const LineOfSight({super.key});
  @override
  createState() => _State();
}

class _State extends State<LineOfSight> {
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
          Text('The white fan represents the visibility range of the game entity.\nWhen the target is visible for the game entity, the target\'s color changes to green.'),
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
    final indices = obstacleGeometry.index?.array.toList();
    final geometry = yuka.MeshGeometry( vertices.toDartList(), indices?.map((e) => e.toInt()).toList() );

    final obstacle = Obstacle( geometry );
    obstacle.rotation.fromEuler(math.pi,0,0);
    obstacle.position.fromArray( obstacleMesh.position.storage );
    
    obstacle.setRenderComponent( obstacleMesh, sync );

    target.setRenderComponent( targetMesh, sync );
    entity.setRenderComponent( entityMesh, sync );

    final vision = yuka.Vision( entity );
    vision.range = 5;
    vision.fieldOfView = math.pi * 0.5;
    vision.addObstacle( obstacle );
    entity.vision = vision;

    final helper = YukaVisionHelper( vision,16,4 );
    threeJs.scene.add( helper );
    entityMesh.add( helper );

    entityManager.add( entity );
    entityManager.add( obstacle );
    entityManager.add( target );

    three.OrbitControls(threeJs.camera, threeJs.globalKey);
    time.reset();
    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			final elapsed = time.elapsed;

			// change color of target if visible
			target.position.set( math.sin( elapsed * 0.5 ) * 4, 0, 4 );

			if ( entity.vision?.visible( target.position ) == true ) {
				targetMaterial.color.setFromHex32( 0x00ff00 );
			} 
      else {
				targetMaterial.color.setFromHex32( 0xff0000 );
			}

			entityManager.update( delta );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
