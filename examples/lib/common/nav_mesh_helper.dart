import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;
import 'dart:math' as math;

class NavMeshHelper {
  static three.Mesh createConvexRegionHelper(NavMesh navMesh ) {
    final regions = navMesh.regions;
    final geometry = three.BufferGeometry();
    final material = three.MeshBasicMaterial.fromMap( { 'vertexColors': true } );
    final mesh = three.Mesh( geometry, material );
    final positions = <double>[];
    final colors = <double>[];

    final color = three.Color();

    for ( final region in regions ) {
      // one color for each convex region
      color.setFromHex32( (math.Random().nextDouble() * 0xffffff).toInt() );

      // count edges
      HalfEdge? edge = region.edge;
      final edges = <HalfEdge>[];

      while ( edge != region.edge ) {
        edges.add( edge! );
        edge = edge.next;
      }

      // triangulate
      final triangleCount = ( edges.length - 2 );

      for ( int i = 1, l = triangleCount; i <= l; i ++ ) {
        final v1 = edges[ 0 ].vertex;
        final v2 = edges[ i + 0 ].vertex;
        final v3 = edges[ i + 1 ].vertex;

        positions.addAll([ v1.x, v1.y, v1.z ]);
        positions.addAll([ v2.x, v2.y, v2.z ]);
        positions.addAll([ v3.x, v3.y, v3.z ]);

        colors.addAll([ color.red, color.green, color.blue ]);
        colors.addAll([ color.red, color.green, color.blue ]);
        colors.addAll([ color.red, color.green, color.blue ]);
      }
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    return mesh;
  }
}