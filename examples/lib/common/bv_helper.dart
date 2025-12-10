import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'dart:math' as math;

class BVHelper {
  static three.Mesh createSphereHelper(yuka.BoundingSphere boundingSphere ) {
    final geometry = three.SphereGeometry( boundingSphere.radius, 16, 16 );
    final material = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'wireframe': true } );
    final mesh = three.Mesh( geometry, material );

    mesh.position.copyFromArray( boundingSphere.center.storage );

    return mesh;
  }

  static three.Mesh createAABBHelper(yuka.AABB aabb ) {

    final center = aabb.getCenter( yuka.Vector3() );
    final size = aabb.getSize( yuka.Vector3() );

    final geometry = three.BoxGeometry( size.x, size.y, size.z );
    final material = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'wireframe': true } );
    final mesh = three.Mesh( geometry, material );

    mesh.position.copyFromArray( center.storage );

    return mesh;
  }

   static three.Mesh createOBBHelper(yuka.OBB obb ) {
    final center = obb.center;
    final size = yuka.Vector3().copy( obb.halfSizes ).multiplyScalar( 2 );
    final rotation = yuka.Quaternion().fromMatrix3( obb.rotation );

    final geometry = three.BoxGeometry( size.x, size.y, size.z );
    final material = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'wireframe': true } );
    final mesh = three.Mesh( geometry, material );

    mesh.position.copyFromArray( center.storage );
    mesh.quaternion.copyFromUnknown( rotation.storage );

    return mesh;
  }

  static three.Mesh createConvexHullHelper(yuka.ConvexHull convexHull ) {
    final faces = convexHull.faces;

    final positions = <double>[];
    final colors = <double>[];
    final centroids = <double>[];

    final color = three.Color();

    for ( int i = 0; i < faces.length; i ++ ) {

      final face = faces[ i ];
      final centroid = face.centroid;
      yuka.HalfEdge? edge = face.edge;
      final edges = [];

      color.setFromHex32( (math.Random().nextDouble() * 0xffffff).toInt() );

      centroids.addAll([ centroid.x, centroid.y, centroid.z ]);

      while ( edge != face.edge ) {
        edges.add( edge );
        edge = edge?.next;
      }

      // triangulate
      final triangleCount = ( edges.length - 2 );

      for ( int i = 1, l = triangleCount; i <= l; i ++ ) {
        final v1 = edges[ 0 ].vertex;
        final v2 = edges[ i + 0 ].vertex;
        final v3 = edges[ i + 1 ].vertex;

        positions.addAll([ v1.x, v1.y, v1.z ]);
        positions.addAll( [v2.x, v2.y, v2.z ]);
        positions.addAll([ v3.x, v3.y, v3.z ]);

        colors.addAll([ color.red, color.green, color.blue ]);
        colors.addAll([ color.red, color.green, color.blue ]);
        colors.addAll([ color.red, color.green, color.blue ]);
      }
    }

    // convex hull
    final convexGeometry = three.BufferGeometry();
    convexGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    convexGeometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    final convexMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'wireframe': true } );
    final mesh = three.Mesh( convexGeometry, convexMaterial );

    // centroids (useful for debugging)
    final centroidGeometry = three.BufferGeometry();
    centroidGeometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( centroids, 3 ) );

    final centroidMaterial = three.PointsMaterial.fromMap( { 'color': 0xffff00, 'size': 0.25 } );
    final pointCloud = three.Points( centroidGeometry, centroidMaterial );

    mesh.add( pointCloud );

    //
    return mesh;
  }
}