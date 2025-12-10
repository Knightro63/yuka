import 'dart:async';
import 'dart:math' as math;
import 'package:examples/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class OrientationExample extends StatefulWidget {
  const OrientationExample({super.key});
  @override
  createState() => _State();
}

class _State extends State<OrientationExample> {
  late Gui panel;
  late three.ThreeJS threeJs;
  Timer? timer;

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
          Text('The entity is rotated by a defined angular step per second in order to face a specific target.'),
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
  final List<yuka.Vector3> points = [];
  three.Object3D? helper;
  late final yuka.MeshGeometry meshGeometry;

  Future<void> setup() async {
		threeJs.scene = three.Scene();

		threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
		threeJs.camera.position.setValues( 0, 0, 10 );
		threeJs.camera.lookAt( threeJs.scene.position );

		//
		final entityGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
		entityGeometry.rotateX( math.pi * 0.5 );
		final entityMaterial = three.MeshNormalMaterial();

		final entityMesh = three.Mesh( entityGeometry, entityMaterial );
		entityMesh.matrixAutoUpdate = false;
		threeJs.scene.add( entityMesh );

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

		// game entity setup
		target.setRenderComponent( targetMesh, sync );
		entity.maxTurnRate = math.pi * 0.5;
		entity.setRenderComponent( entityMesh, sync );

		entityManager.add( entity );
		entityManager.add( target );

		//
    timer = Timer.periodic(Duration(milliseconds: 2000),generateTarget);

    threeJs.addAnimationEvent((dt){
      final delta = time.update().delta;
      entity.rotateTo( target.position, delta );
      entityManager.update(delta);
    });
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }

  void generateTarget(dt) {
    // generate a random point on a sphere
    final radius = 2.0;
    final phi = math.acos( ( 2 * math.Random().nextDouble() ) - 1 );
    final theta = math.Random().nextDouble() * math.pi * 2;

    target.position.fromSpherical( radius, phi, theta );
  }
}
