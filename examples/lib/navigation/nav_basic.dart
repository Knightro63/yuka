import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/graph_helper.dart';
import 'package:examples/common/nav_mesh_helper.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class NavBaisc extends StatefulWidget {
  const NavBaisc({super.key});
  @override
  createState() => _State();
}

class _State extends State<NavBaisc> {
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
          Text('A navigation mesh defines the walkable area of this level.'),
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
  final three.Vector2 mouseCoordinates = three.Vector2();
  final raycaster = three.Raycaster();
  final vehicle = yuka.Vehicle();
  late final yuka.NavMesh navMesh;
  late final three.Mesh navMeshGroup;
  three.Group? graphHelper;
  late final three.Line pathHelper;

  final Map<String,dynamic> params = {'showNavigationGraph': true};

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 25, 25, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    final pathMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xff0000 } );
    pathHelper = three.Line( three.BufferGeometry(), pathMaterial );
    pathHelper.visible = false;
    threeJs.scene.add( pathHelper );

    //
    final vehicleGeometry = three.ConeGeometry( 0.25, 1, 16 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    vehicleGeometry.translate( 0, 0.25, 0 );
    final vehicleMaterial = three.MeshNormalMaterial();

    final vehicleMesh = three.Mesh( vehicleGeometry, vehicleMaterial );
    vehicleMesh.matrixAutoUpdate = false;
    threeJs.scene.add( vehicleMesh );

    threeJs.domElement.addEventListener( three.PeripheralType.pointerdown, onMouseDown, false );

    // dat.gui

    final gui = panel.addFolder("GUI")..open();

    gui.addCheckBox( params, 'showNavigationGraph').onChange( ( value ){
      graphHelper?.visible = value;
    } );

    // load navigation mesh

    final loader = yuka.NavMeshLoader();

    await loader.fromAsset( 'assets/models/navmesh.gltf',options: {'path': 'assets/models/'} ).then( ( navigationMesh ){
      // visualize convex regions
      navMesh = navigationMesh!;
      navMeshGroup = NavMeshHelper.createConvexRegionHelper( navMesh );

      threeJs.scene.add( navMeshGroup );

      // visualize graph
      final graph = navMesh.graph;

      graphHelper = GraphHelper.createGraphHelper( graph, 0.2 );
      threeJs.scene.add( graphHelper );
      
      vehicle.maxSpeed = 1.5;
      vehicle.maxForce = 10;
      vehicle.setRenderComponent( vehicleMesh, sync );

      final followPathBehavior = yuka.FollowPathBehavior();
      followPathBehavior.active = false;
      vehicle.steering.add( followPathBehavior );

      entityManager.add( vehicle );
    } );

    time.reset();
    threeJs.addAnimationEvent((dt){
			final delta = time.update().delta;
			entityManager.update( delta );
    });
	}

  void onMouseDown( event ) {
    mouseCoordinates.x = ( event.clientX / threeJs.width ) * 2 - 1;
    mouseCoordinates.y = - ( event.clientY / threeJs.height ) * 2 + 1;

    raycaster.setFromCamera( mouseCoordinates, threeJs.camera );

    final intersects = raycaster.intersectObject( navMeshGroup, true );

    if ( intersects.isNotEmpty ) {
      findPathTo( yuka.Vector3().fromArray( intersects[ 0 ].point!.storage ) );
    }
  }

  void findPathTo(yuka.Vector3 target ) {

    final from = vehicle.position;
    final to = target;

    final path = navMesh.findPath( from, to );

    pathHelper.visible = true;
    pathHelper.geometry?.dispose();
    pathHelper.geometry = three.BufferGeometry().setFromPoints( path );

    final followPathBehavior = vehicle.steering.behaviors[ 0 ];
    followPathBehavior.active = true;
    followPathBehavior.path.clear();

    for ( final point in path ) {
      followPathBehavior.path.add( point );
    }
  }

  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
