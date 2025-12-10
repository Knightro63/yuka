import 'dart:typed_data';

import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart' as yuka;
import 'dart:math' as math;

class VisionHelper {
   static three.Mesh createVisionHelper(yuka.Vision vision, [int division = 8 ]) {

    final fieldOfView = vision.fieldOfView;
    final range = vision.range;

    final geometry = three.BufferGeometry();
    final material = three.MeshBasicMaterial.fromMap( { 'wireframe': false } );

    final mesh = three.Mesh( geometry, material );

    final positions = <double>[];

    final foV05 = fieldOfView ~/ 2;
    final step = fieldOfView ~/ division;

    // for now, let's create a simple helper that lies in the xz plane

    for ( int i = - foV05; i < foV05; i += step ) {
      positions.addAll([ 0, 0, 0 ]);
      positions.addAll([ math.sin( i ) * range, 0, math.cos( i ) * range ]);
      positions.addAll([ math.sin( i + step ) * range, 0, math.cos( i + step ) * range ]);
    }
    
    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geometry.attributes['position'].needsUpdate = true;

    return mesh;
  }
}

class YukaVisionHelper extends three.Line {
  yuka.Vision vision;
  int divisionsInnerAngle;
  int divisionsOuterAngle;

	YukaVisionHelper.create(
    super.geometry,
    super.materials,
    this.vision, 
    [this.divisionsInnerAngle = 16, this.divisionsOuterAngle = 2 ]
  ){
		type = 'PositionalAudioHelper';
	  update();
	}

  factory YukaVisionHelper(yuka.Vision vision, [int divisionsInnerAngle = 16, int divisionsOuterAngle = 2 ]){
		final geometry = three.BufferGeometry();
		final divisions = divisionsInnerAngle + divisionsOuterAngle * 2;
		final positions = Float32List( ( divisions * 3 + 3 ) * 3 );
		geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );

		final materialInnerAngle = three.LineBasicMaterial.fromMap( { 'color': 0xffffff } );
		final materialOuterAngle = three.LineBasicMaterial.fromMap( { 'color': 0xffffff } );

    return YukaVisionHelper.create(
      geometry, 
      three.GroupMaterial([materialOuterAngle, materialInnerAngle]), 
      vision,
      divisionsInnerAngle,divisionsOuterAngle
    );
  }

	void update() {
		final vision = this.vision;
		final range = vision.range;
		final divisionsInnerAngle = this.divisionsInnerAngle;
		final divisionsOuterAngle = this.divisionsOuterAngle;

		final coneInnerAngle = three.MathUtils.degToRad( 0 );
		final coneOuterAngle = three.MathUtils.degToRad( 45 );

		final halfConeInnerAngle = coneInnerAngle;
		final halfConeOuterAngle = coneOuterAngle;

		int start = 0;
		int count = 0;
		double i;
		int stride;

		final geometry = this.geometry;
		final positionAttribute = geometry?.attributes['position'];

		geometry?.clearGroups();

		void generateSegment(double from,double to,int divisions,int materialIndex ) {
			final double step = ( to - from ) / divisions;

			(positionAttribute as three.Float32BufferAttribute).setXYZ( start, 0, 0, 0 );
			count ++;

			for ( i = from; i < to; i += step ) {
				stride = start + count;
				positionAttribute.setXYZ( stride, math.sin( i ) * range, 0, math.cos( i ) * range );
				positionAttribute.setXYZ( stride + 1, math.sin( math.min( i + step, to ) ) * range, 0, math.cos( math.min( i + step, to ) ) * range );
				positionAttribute.setXYZ( stride + 2, 0, 0, 0 );

				count += 3;
			}

			geometry?.addGroup( start, count, materialIndex );

			start += count;
			count = 0;
		}

		//

		generateSegment( - halfConeOuterAngle, - halfConeInnerAngle, divisionsOuterAngle, 0 );
		generateSegment( - halfConeInnerAngle, halfConeInnerAngle, divisionsInnerAngle, 1 );
		generateSegment( halfConeInnerAngle, halfConeOuterAngle, divisionsOuterAngle, 0 );

		//

		positionAttribute.needsUpdate = true;

		if ( coneInnerAngle == coneOuterAngle ) (material as three.GroupMaterial).children[ 0 ].visible = false;

	}
  
  @override
	void dispose() {
		geometry?.dispose();
		(material as three.GroupMaterial).children[ 0 ].dispose();
		(material as three.GroupMaterial).children[ 1 ].dispose();
	}
}
