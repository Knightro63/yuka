import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class SteeringFollow extends StatefulWidget {
  const SteeringFollow({super.key});
  @override
  createState() => _State();
}

class _State extends State<SteeringFollow> {
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
  final vehicle = yuka.Vehicle();
  late final yuka.OnPathBehavior onPathBehavior;

  final Map<String,dynamic> params = {
    'onPathActive': true,
    'radius': 0.1
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 20, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 8 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    final vehicleMaterial = three.MeshNormalMaterial();

    final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    vehicleMesh.matrixAutoUpdate = false;
    threeJs.scene.add( vehicleMesh );

    final gui = panel.addFolder('GUI')..open();
    gui.addCheckBox( params, 'onPathActive' )..name = 'activate onPath'..onChange( ( value ) => onPathBehavior.active = value );
    gui.addSlider( params, 'radius', 0.01, 1, 0.01 )..name = 'radius'..onChange( ( value ) => onPathBehavior.radius = value );

    //
    vehicle.setRenderComponent( vehicleMesh, sync );

    final path = yuka.Path();
    path.loop = true;
    path.add( yuka.Vector3( - 4, 0, 4 ) );
    path.add( yuka.Vector3( - 6, 0, 0 ) );
    path.add( yuka.Vector3( - 4, 0, - 4 ) );
    path.add( yuka.Vector3( 0, 0, 0 ) );
    path.add( yuka.Vector3( 4, 0, - 4 ) );
    path.add( yuka.Vector3( 6, 0, 0 ) );
    path.add( yuka.Vector3( 4, 0, 4 ) );
    path.add( yuka.Vector3( 0, 0, 6 ) );

    vehicle.position.copy( path.current() );

    // use "FollowPathBehavior" for basic path following
    final followPathBehavior = yuka.FollowPathBehavior( path, 0.5 );
    vehicle.steering.add( followPathBehavior );

    // use "OnPathBehavior" to realize a more strict path following.
    // it's a separate steering behavior to provide more flexibility.
    onPathBehavior = yuka.OnPathBehavior( path );
    vehicle.steering.add( onPathBehavior );
    entityManager.add( vehicle );

    //
    final position = <double>[];

    for ( int i = 0; i < path.waypoints.length; i ++ ) {
      final waypoint = path.waypoints[ i ];
      position.addAll([ waypoint.x, waypoint.y, waypoint.z ]);
    }

    final lineGeometry = three.BufferGeometry();
    lineGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( position, 3 ) );

    final lineMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xffffff } );
    final lines = three.LineLoop( lineGeometry, lineMaterial );
    threeJs.scene.add( lines );

    threeJs.addAnimationEvent((dt){
			//final delta = time.update().delta;
			entityManager.update( dt );
    });
	}

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
