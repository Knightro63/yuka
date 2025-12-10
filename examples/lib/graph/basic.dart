import 'dart:async';
import 'package:examples/common/graph_helper.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:examples/src/gui.dart';

class GraphBasic extends StatefulWidget {
  const GraphBasic({super.key});
  @override
  createState() => _State();
}

class _State extends State<GraphBasic> {
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
          Text('Click on one of the nodes to perform a graph search.\nThe green line represents the shortest path, the red lines the search tree.'),
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

  late final yuka.Graph graph;
  three.LineSegments? searchTreeHelper;
  three.Group? pathHelper;
	int from = 60; // source node index
	int to = 104; // target node index
  final List<three.Object3D> nodes = [];
  late final three.Raycaster raycaster;
  final Map<String,String> params = {
		'algorithm': 'AStar'
	};

  Future<void> setup() async {
		threeJs.scene = three.Scene();

		threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
		threeJs.camera.position.setValues( 50, 50, 0 );
		threeJs.camera.lookAt( threeJs.scene.position );

		raycaster = three.Raycaster();

		// graph
		graph = yuka.GraphUtils.createGridLayout( 50, 10 );

		final graphHelper = GraphHelper.createGraphHelper( graph, 0.25 );
		threeJs.scene.add( graphHelper );

		graphHelper.traverse( ( child ){
			if ( child is three.Mesh ) nodes.add( child );
		} );

		performSearch('AStar');

    threeJs.domElement.addEventListener(three.PeripheralType.pointerup, ( event ) {
      onDocumentMouseDown(event);
    });

		// dat.gui
		final gui = panel.addFolder('GUI')..open();
		gui.addDropDown( params, 'algorithm', [ 'AStar', 'Dijkstra', 'BFS', 'DFS' ] ).onChange( performSearch );
	}

	onDocumentMouseDown( event ) {
		final mouse = three.Vector2();

		mouse.x = ( event.clientX / threeJs.width ) * 2 - 1;
		mouse.y = - ( event.clientY / threeJs.height ) * 2 + 1;

		raycaster.setFromCamera( mouse, threeJs.camera );

		final intersects = raycaster.intersectObjects( nodes );

		if ( intersects.isNotEmpty ) {
			final intersection = intersects[ 0 ];
			// set new target node
			to = intersection.object?.userData['nodeIndex'];
			performSearch(params['algorithm']);
		}
	}

	void performSearch(e) {
    late final graphSearch;

    switch (e) {
      case 'Dijkstra':
          graphSearch = yuka.Dijkstra( graph, from, to );
        break;
      case 'BFS':
          graphSearch = yuka.BFS( graph, from, to );
        break;
      case 'DFS':
          graphSearch = yuka.DFS( graph, from, to );
        break;
      default:
        graphSearch = yuka.AStar( graph, from, to );
    }

		graphSearch.search();

		final searchTree = graphSearch.getSearchTree();
		final path = graphSearch.getPath();

		// update helper
		if ( searchTreeHelper != null && pathHelper != null ) {
			threeJs.scene.remove( searchTreeHelper! );
			threeJs.scene.remove( pathHelper! );

			searchTreeHelper?.dispose() ;
			pathHelper?.dispose();
		}

		searchTreeHelper = GraphHelper.createSearchTreeHelper( graph, searchTree );
		searchTreeHelper?.renderOrder = 1;
		threeJs.scene.add( searchTreeHelper );

		pathHelper = GraphHelper.createPathHelper( graph, path, 0.4 );
		pathHelper?.renderOrder = 2;
		threeJs.scene.add( pathHelper );

		// clean up
		graphSearch.clear();
  }
}
