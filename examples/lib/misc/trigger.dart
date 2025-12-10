import 'dart:async';
import 'dart:math' as math;
import 'package:examples/misc/custom_trigger.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class Trigger extends StatefulWidget {
  const Trigger({super.key});
  @override
  createState() => _State();
}

class _State extends State<Trigger> {
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
  final yuka.GameEntity entity = yuka.GameEntity();
  final yuka.GameEntity target = yuka.GameEntity();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 0, 10, 15 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
		final entityGeometry = three.BoxGeometry( 0.5, 0.5, 0.5 );
		final entityMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

		final entityMesh = three.Mesh( entityGeometry, entityMaterial );
		entityMesh.matrixAutoUpdate = false;
		threeJs.scene.add( entityMesh );

		final grid = GridHelper( 10, 25 );
		threeJs.scene.add( grid );

		entity.boundingRadius = 0.25;
		entity.setRenderComponent( entityMesh, sync );

		entityManager.add( entity );

		final radius = 2.0;
		final size = yuka.Vector3( 3, 3, 3 );

		final sphericalTriggerRegion = yuka.SphericalTriggerRegion( radius );
		final rectangularTriggerRegion = yuka.RectangularTriggerRegion( size );

		final trigger1 = CustomTrigger( sphericalTriggerRegion );
		trigger1.position.set( 3, 0, 0 );

		final trigger2 = CustomTrigger( rectangularTriggerRegion );
		trigger2.position.set( - 3, 0, 0 );

		entityManager.add( trigger1 );
		entityManager.add( trigger2 );

		// visualize triggers

		final sphereGeometry = three.SphereGeometry( radius, 16, 16 );
		final sphereMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x6083c2, 'wireframe': true } );
		final triggerMesh1 = three.Mesh( sphereGeometry, sphereMaterial );
		triggerMesh1.matrixAutoUpdate = false;
		threeJs.scene.add( triggerMesh1 );

		trigger1.setRenderComponent( triggerMesh1, sync );

		final boxGeometry = three.BoxGeometry( size.x, size.y, size.z );
		final boxMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x6083c2, 'wireframe': true } );
		final triggerMesh2 = three.Mesh( boxGeometry, boxMaterial );
		triggerMesh2.matrixAutoUpdate = false;
		threeJs.scene.add( triggerMesh2 );

		trigger2.setRenderComponent( triggerMesh2, sync );


    time.reset();

    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
      final elapsedTime = time.elapsed;
      entity.position.x = math.sin( elapsedTime ) * 2;
      entity.renderComponent.material.color.setFromHex32( 0xff0000 ); // reset color
			entityManager.update( delta );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
