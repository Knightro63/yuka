import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringFlocking extends StatefulWidget {
  const SteeringFlocking({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringFlocking> {
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
          Text('A group steering behavior defined by a combination of "Alignment", "Cohesion" and "Separation".'),
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

  final Map<String,dynamic> params = {
    'alignment': 1.0,
    'cohesion': 0.9,
    'separation': 0.3
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 500 );
    threeJs.camera.position.setValues( 0, 75, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshNormalMaterial();

    final grid = GridHelper( 100, 50 );
    threeJs.scene.add( grid );

    // game setup
    final alignmentBehavior = yuka.AlignmentBehavior();
    final cohesionBehavior = yuka.CohesionBehavior();
    final separationBehavior = yuka.SeparationBehavior();

    alignmentBehavior.weight = params['alignment'];
    cohesionBehavior.weight = params['cohesion'];
    separationBehavior.weight = params['separation'];

    for ( int i = 0; i < 50; i ++ ) {
      final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
      vehicleMesh.matrixAutoUpdate = false;
      threeJs.scene.add( vehicleMesh );

      final vehicle = yuka.Vehicle();
      vehicle.maxSpeed = 1.5;
      vehicle.updateNeighborhood = true;
      vehicle.neighborhoodRadius = 10;
      vehicle.rotation.fromEuler( 0, math.pi * math.Random().nextDouble(), 0 );
      vehicle.position.x = 10 - math.Random().nextDouble() * 20;
      vehicle.position.z = 10 - math.Random().nextDouble() * 20;

      vehicle.setRenderComponent( vehicleMesh, sync );

      vehicle.steering.add( alignmentBehavior );
      vehicle.steering.add( cohesionBehavior );
      vehicle.steering.add( separationBehavior );

      final wanderBehavior = yuka.WanderBehavior();
      wanderBehavior.weight = 0.5;
      vehicle.steering.add( wanderBehavior );

      entityManager.add( vehicle );
    }

    // dat.gui

    final gui = panel.addFolder('GUI')..open();

    gui.addSlider( params, 'alignment', 0.1, 2, 0.1 )..name = 'alignment'..onChange( ( value ){alignmentBehavior.weight = value;} );
    gui.addSlider( params, 'cohesion', 0.1, 2, 0.1 )..name = 'cohesion'..onChange( ( value ){cohesionBehavior.weight = value;} );
    gui.addSlider( params, 'separation', 0.1, 2, 0.1 )..name = 'separation'..onChange( ( value ){separationBehavior.weight = value;} );

    //
    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.mouseButtons['LEFT'] = three.Mouse.pan;//THREE.MOUSE.PAN;

    threeJs.addAnimationEvent((dt){
			entityManager.update( dt );
      controls.update();
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
