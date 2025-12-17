import 'dart:async';
import 'dart:math' as math;
import 'package:examples/common/bvh_helper.dart';
import 'package:examples/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class BVHExample extends StatefulWidget {
  const BVHExample({super.key});
  @override
  createState() => _State();
}

class _State extends State<BVHExample> {
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true,
      )
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
          Text('			Demonstrates different types of auto-generated bounding volumes.'),
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

	final Map<String,dynamic> params = {
    'branchingFactor': 2.0,
    'primitives/Node': 1.0,
    'depth': 5.0,
    'meshVisible': true
	};
  final List<yuka.Vector3> points = [];
  three.Object3D? helper;
  late final yuka.MeshGeometry meshGeometry;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 20, 40 );

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width /threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( 0, 3, - 8 );

    //

    final geometry = three.PlaneGeometry( 150, 150 );
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0x999999, 'depthWrite': false } );

    final ground = three.Mesh( geometry, material );
    ground.rotation.x = - math.pi / 2;
    ground.matrixAutoUpdate = false;
    ground.receiveShadow = true;
    ground.updateMatrix();
    threeJs.scene.add( ground );

    //

    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 0.6 );
    hemiLight.position.setValues( 0, 100, 0 );
    hemiLight.matrixAutoUpdate = false;
    hemiLight.updateMatrix();
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 0.8 );
    dirLight.position.setValues( - 4, 5, - 5 );
    dirLight.matrixAutoUpdate = false;
    dirLight.updateMatrix();
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 4;
    dirLight.shadow?.camera?.bottom = - 4;
    dirLight.shadow?.camera?.left = - 4;
    dirLight.shadow?.camera?.right = 4;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 20;
    threeJs.scene.add( dirLight );

    final sphereGeometry = three.TorusKnotGeometry( 1, 0.2, 64, 16 ).toNonIndexed();
    final sphereMaterial = three.MeshPhongMaterial.fromMap( { 'color': 0xee0808 } );
    final icoSphere = three.Mesh( sphereGeometry, sphereMaterial );
    icoSphere.position.setValues( 0, 1.5, 0 );
    icoSphere.updateMatrix();
    icoSphere.castShadow = true;
    threeJs.scene.add( icoSphere );

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableKeys = false;
    controls.enablePan = false;
    controls.target.setFrom( icoSphere.position );
    controls.update();

    // dat.gui

    final gui = panel.addFolder('GUI')..open();

    gui.addSlider( params, 'branchingFactor', 2, 6 )..step( 1 )..onChange( createBVH );
    gui.addSlider( params, 'primitives/Node', 1, 10 )..step( 1 )..onChange( createBVH );
    gui.addSlider( params, 'depth', 1, 8 )..step( 1 )..onChange( createBVH );
    gui.addCheckBox( params, 'meshVisible' ).onChange( ( value ) => icoSphere.visible = value );

    // bvh setup
    final threeGeometry = sphereGeometry.clone();
    threeGeometry.applyMatrix4( icoSphere.matrix ); // transform vertices to world space

    final vertices = threeGeometry.attributes['position'].array as three.Float32Array;
    meshGeometry = yuka.MeshGeometry( vertices.toDartList() );

    createBVH(null);
  }

  void createBVH(e) {
    if ( helper != null) removeHelper();

    final bvh = yuka.BVH( params['branchingFactor'], params['primitives/Node'], params['depth'] );
    bvh.fromMeshGeometry( meshGeometry );

    helper = BVHHelper.createBVHHelper( bvh, params['depth'] );
    threeJs.scene.add( helper );
  }

  void removeHelper() {
    helper?.traverse( ( child ){
      if ( child is three.LineSegments ) {
        child.geometry?.dispose();
        child.material?.dispose();
      }
    } );

    threeJs.scene.remove( helper! );
  }
}
