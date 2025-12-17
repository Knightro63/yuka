import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;

class GraphHelper{
  static three.Group createGraphHelper(yuka.Graph graph,[double nodeSize = 1,int nodeColor = 0x4e84c4,int edgeColor = 0xffffff ]) {
    final group = three.Group();

    // nodes
    final nodeMaterial = three.MeshBasicMaterial.fromMap( { 'color': nodeColor } );
    final nodeGeometry = three.IcosahedronGeometry( nodeSize, 2 );

    final nodes = <yuka.Node>[];

    graph.getNodes( nodes );

    for ( final node in nodes ) {
      final nodeMesh = three.Mesh( nodeGeometry, nodeMaterial );
      nodeMesh.position.copyFromArray( node.position.storage );
      nodeMesh.userData['nodeIndex'] = node.index;

      nodeMesh.matrixAutoUpdate = false;
      nodeMesh.updateMatrix();

      group.add( nodeMesh );
    }

    // edges

    final edgesGeometry = three.BufferGeometry();
    final position = <double>[];

    final edgesMaterial = three.LineBasicMaterial.fromMap( { 'color': edgeColor } );

    final edges = <yuka.Edge>[];

    for ( final node in nodes ) {
      graph.getEdgesOfNode( node.index, edges );

      for ( final edge in edges ) {

        final fromNode = graph.getNode( edge.from )!;
        final toNode = graph.getNode( edge.to )!;

        position.addAll([ fromNode.position.x, fromNode.position.y, fromNode.position.z ]);
        position.addAll([ toNode.position.x, toNode.position.y, toNode.position.z ]);
      }
    }

    edgesGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( position, 3 ) );

    final lines = three.LineSegments( edgesGeometry, edgesMaterial );
    lines.matrixAutoUpdate = false;

    group.add( lines );

    return group;

  }

	static three.Line createPathHelperBasic() {
		final pathHelper = three.Line( three.BufferGeometry(), three.LineBasicMaterial.fromMap( { 'color': 0xff0000 } ) );
		pathHelper.matrixAutoUpdate = false;
		pathHelper.visible = false;
		return pathHelper;
	}

  static three.Group createPathHelper(yuka.Graph graph, List<int> path, double nodeSize, [int color = 0x00ff00 ]) {
    final group = three.Group();

    // nodes
    final startNodeMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000 } );
    final endNodeMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x00ff00 } );
    final nodeGeometry = three.IcosahedronGeometry( nodeSize, 2 );

    final startNodeMesh = three.Mesh( nodeGeometry, startNodeMaterial );
    final endNodeMesh = three.Mesh( nodeGeometry, endNodeMaterial );

    final startNode = graph.getNode( path[ 0 ] )!;
    final endNode = graph.getNode( path[ path.length - 1 ] )!;

    startNodeMesh.position.copyFromArray( startNode.position.storage );
    endNodeMesh.position.copyFromArray( endNode.position.storage );

    group.add( startNodeMesh );
    group.add( endNodeMesh );

    // edges

    final edgesGeometry = three.BufferGeometry();
    final position = <double>[];

    final edgesMaterial = three.LineBasicMaterial.fromMap( { 'color': color } );

    for ( int i = 0, l = path.length - 1; i < l; i ++ ) {
      final fromNode = graph.getNode( path[ i ] )!;
      final toNode = graph.getNode( path[ i + 1 ] )!;

      position.addAll([ fromNode.position.x, fromNode.position.y, fromNode.position.z ]);
      position.addAll([ toNode.position.x, toNode.position.y, toNode.position.z ]);
    }

    edgesGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( position, 3 ) );

    final lines = three.LineSegments( edgesGeometry, edgesMaterial );
    lines.matrixAutoUpdate = false;

    group.add( lines );

    return group;
  }

  static three.LineSegments createSearchTreeHelper(yuka.Graph graph, List<yuka.Edge> searchTree, [int color = 0xff0000 ]) {
    final geometry = three.BufferGeometry();
    final position = <double>[];

    final material = three.LineBasicMaterial.fromMap( { 'color': color } );

    for ( final edge in searchTree ) {
      final fromNode = graph.getNode( edge.from )!;
      final toNode = graph.getNode( edge.to )!;

      position.addAll([ fromNode.position.x, fromNode.position.y, fromNode.position.z ]);
      position.addAll([ toNode.position.x, toNode.position.y, toNode.position.z ]);
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( position, 3 ) );

    final lines = three.LineSegments( geometry, material );
    lines.matrixAutoUpdate = false;

    return lines;
  }
}
