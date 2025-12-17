import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/nav_mesh_helper.dart';
import 'package:examples/navigation/custom_vehicle.dart';
import 'package:examples/common/path_planner.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class NavAdvanced extends StatefulWidget {
  const NavAdvanced({super.key});
  @override
  createState() => _State();
}

class _State extends State<NavAdvanced> {
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
          Text('Navigation Mesh with Spatial Index and Tasks'),
          Text('Active Game Entities: $vehicleCount'),
          if(threeJs.mounted)Text('Convex Regions of NavMesh: $regionsCount'),
          if(threeJs.mounted)Text('Partitions of Spatial Index: $spatialIndex'),
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
  final raycaster = three.Raycaster();
  final List<CustomVehicle> vehicles = [];
  final List<three.Line> pathHelpers = [];

  final vehicleCount = 100;
  int regionsCount = 0;
  int spatialIndex = 0;

  final Map<String,dynamic> params = {
    'showNavigationPaths': false,
    'showRegions': false,
    'showSpatialIndex': false,
  };

  three.LineSegments? spatialIndexHelper;
  late final three.InstancedMesh vehicleMesh;
  late final PathPlanner pathPlanner;
  three.Mesh? regionHelper;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.camera.position.setValues( 60, 40, 60 );
    threeJs.camera.lookAt( threeJs.scene.position );

    //
    final pathMaterial = three.LineBasicMaterial.fromMap( { 'color': 0xff0000 } );

    //
    final vehicleGeometry = three.ConeGeometry( 0.1, 0.5, 16 );
    vehicleGeometry.rotateX( math.pi * 0.5 );
    vehicleGeometry.translate( 0, 0.1, 0 );
    final vehicleMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );

    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.6 );
    hemiLight.position.setValues( 0, 100, 0 );
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
    dirLight.position.setValues( 0, 200, 100 );
    threeJs.scene.add( dirLight );

    // dat.gui
    final gui = panel.addFolder('GUI')..open();
    gui.addCheckBox( params, 'showNavigationPaths')..name = 'show navigation paths'..onChange( ( value ){
      for ( int i = 0, l = pathHelpers.length; i < l; i ++ ) {
        pathHelpers[ i ].visible = value;
      }
    } );

    gui.addCheckBox( params, 'showRegions')..name = 'show regions'..onChange( ( value ){
      regionHelper?.visible = value;
    } );

    gui.addCheckBox( params, 'showSpatialIndex')..name = 'show spatial index'..onChange( ( value ){
      spatialIndexHelper?.visible = value;
    } );

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 10;
    controls.maxDistance = 200;

    await three.GLTFLoader( ).fromAsset( 'assets/models/level.glb').then( (gltf ){
      // add object to scene
      threeJs.scene.add( gltf!.scene );
      gltf.scene.rotation.y = math.pi;
    } );

    await yuka.NavMeshLoader().fromAsset( 'assets/models/navmesh.glb' ).then( ( navigationMesh ){
      // visualize convex regions
      regionHelper = NavMeshHelper.createConvexRegionHelper( navigationMesh! );
      regionHelper?.visible = false;
      threeJs.scene.add( regionHelper );

      pathPlanner = PathPlanner( navigationMesh );

      // setup spatial index
      final double width = 100, height = 40, depth = 75;
      final int cellsX = 20, cellsY = 5, cellsZ = 20;

      navigationMesh.spatialIndex = yuka.CellSpacePartitioning( width, height, depth, cellsX, cellsY, cellsZ );
      navigationMesh.updateSpatialIndex();

      spatialIndexHelper = NavMeshHelper.createCellSpaceHelper( navigationMesh.spatialIndex );
      threeJs.scene.add( spatialIndexHelper );
      spatialIndexHelper?.visible = false;

      // create vehicles
      vehicleMesh = three.InstancedMesh( vehicleGeometry, vehicleMaterial, vehicleCount );
      vehicleMesh.frustumCulled = false;
      threeJs.scene.add( vehicleMesh );

      for ( int i = 0; i < vehicleCount; i ++ ) {
        // path helper
        final pathHelper = three.Line( three.BufferGeometry(), pathMaterial );
        pathHelper.visible = false;
        threeJs.scene.add( pathHelper );
        pathHelpers.add( pathHelper );

        // vehicle
        final vehicle = CustomVehicle();
        vehicle.navMesh = navigationMesh;
        vehicle.maxSpeed = 1.5;
        vehicle.maxForce = 10;

        final toRegion = vehicle.navMesh!.getRandomRegion();
        vehicle.position.copy( toRegion.centroid );
        vehicle.toRegion = toRegion;

        final followPathBehavior = yuka.FollowPathBehavior();
        followPathBehavior.nextWaypointDistance = 0.5;
        followPathBehavior.active = false;
        vehicle.steering.add( followPathBehavior );

        entityManager.add( vehicle );
        vehicles.add( vehicle );
      }

      // update UI
      regionsCount = navigationMesh.regions.length;
      spatialIndex = navigationMesh.spatialIndex!.cells.length;
    } );

    time.reset();

    threeJs.addAnimationEvent((dt){
      updatePathfinding();
			final delta = time.update().delta;
			entityManager.update( delta );
			pathPlanner.update();
			updateInstancing();
    });
  }

  void onPathFound( vehicle, path ) {
    // update path helper
    final index = vehicles.indexOf( vehicle );
    final pathHelper = pathHelpers[ index ];

    pathHelper.geometry?.dispose();
    pathHelper.geometry = three.BufferGeometry().setFromPoints( path );

    // update path and steering
    final followPathBehavior = vehicle.steering.behaviors[ 0 ];
    followPathBehavior.active = true;
    followPathBehavior.path.clear();

    for ( final point in path ) {
      followPathBehavior.path.add( point );
    }
  }

  void updatePathfinding() {
    for ( int i = 0, l = vehicles.length; i < l; i ++ ) {
      final vehicle = vehicles[ i ];

      if ( vehicle.currentRegion == vehicle.toRegion ) {
        vehicle.fromRegion = vehicle.toRegion;
        vehicle.toRegion = vehicle.navMesh?.getRandomRegion();

        final from = vehicle.position;
        final to = vehicle.toRegion!.centroid;

        pathPlanner.findPath( vehicle, from, to, onPathFound );
      }
    }
  }

  void updateInstancing() {
    for ( int i = 0, l = vehicles.length; i < l; i ++ ) {
      final vehicle = vehicles[ i ];
      vehicleMesh.setMatrixAt( i, three.Matrix4().copyFromArray(vehicle.worldMatrix().elements) );
    }

    vehicleMesh.instanceMatrix?.needsUpdate = true;
  }
  
  void sync(yuka.GameEntity entity, three.Object3D renderComponent ) {
    renderComponent.matrix.copyFromArray( entity.worldMatrix().elements );
  }
}
