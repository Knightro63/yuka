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

      do{
        edges.add( edge! );
        edge = edge.next;
      } while ( edge != region.edge );

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

  static three.LineSegments createCellSpaceHelper( spatialIndex ) {
    final cells = spatialIndex.cells;
    final geometry = three.BufferGeometry();
    final material = three.LineBasicMaterial();
    final lines = three.LineSegments( geometry, material );
    final positions = <double>[];

    for ( int i = 0, l = cells.length; i < l; i ++ ) {
      final cell = cells[ i ];
      final min = cell.aabb.min;
      final max = cell.aabb.max;

      // generate data for twelve lines segments

      // bottom lines
      positions.addAll( [min.x, min.y, min.z, 	max.x, min.y, min.z] );
      positions.addAll( [min.x, min.y, min.z, 	min.x, min.y, max.z] );
      positions.addAll( [max.x, min.y, max.z, 	max.x, min.y, min.z] );
      positions.addAll( [max.x, min.y, max.z, 	min.x, min.y, max.z] );

      // top lines
      positions.addAll( [min.x, max.y, min.z, 	max.x, max.y, min.z] );
      positions.addAll( [min.x, max.y, min.z, 	min.x, max.y, max.z] );
      positions.addAll( [max.x, max.y, max.z, 	max.x, max.y, min.z] );
      positions.addAll( [max.x, max.y, max.z, 	min.x, max.y, max.z] );

      // torso lines
      positions.addAll( [min.x, min.y, min.z, 	min.x, max.y, min.z] );
      positions.addAll( [max.x, min.y, min.z, 	max.x, max.y, min.z] );
      positions.addAll( [max.x, min.y, max.z, 	max.x, max.y, max.z] );
      positions.addAll( [min.x, min.y, max.z, 	min.x, max.y, max.z] );
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );

    return lines;
  }
}