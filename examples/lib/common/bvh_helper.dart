import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'package:three_js_helpers/three_js_helpers.dart';

class BVHHelper{
  static three.Group createBVHHelper(yuka.BVH bvh, double depth ) {
    final group = three.Group();

    bvh.traverse( (yuka.BVHNode node ){
      final box3 = three.BoundingBox();

      box3.min.copyFromArray( node.boundingVolume.min.storage );
      box3.max.copyFromArray( node.boundingVolume.max.storage );

      final currentDepth = node.getDepth();
      final l = 0.2 + ( currentDepth / depth * 0.8 );
      final color = three.Color().setHSL( 0.4, 1, l );
      final helper = BoundingBoxHelper( box3, color.getHex() );

      group.add( helper );
    } );

    return group;
  }
}
