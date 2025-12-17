import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

/// Class with various helper methods.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SceneUtils {

	/// Clones a skinned mesh. This method is necessary since three.js
	/// does not yet support cloning of skinned meshes in the core.
	static three.SkinnedMesh cloneWithSkinning(three.SkinnedMesh source ) {
		// see https://github.com/mrdoob/three.js/pull/14494
		final cloneLookup = {};
		final clone = source.clone();

		parallelTraverse( source, clone, ( sourceNode, clonedNode ){
			cloneLookup[sourceNode] = clonedNode;
		} );

		source.traverse( ( sourceMesh ) {
			if (sourceMesh is! three.SkinnedMesh ) return;

			final sourceBones = sourceMesh.skeleton.bones;
			final clonedMesh = cloneLookup[sourceMesh];

			clonedMesh.skeleton = sourceMesh.skeleton?.clone();

			clonedMesh.skeleton.bones = sourceBones.map( ( sourceBone ) {

				if ( ! cloneLookup.containsValue( sourceBone ) ) {
					throw( 'SceneUtils: Required bones are not descendants of the given object.' );
				}

				return cloneLookup.get( sourceBone );
			} );

			clonedMesh.bind( clonedMesh.skeleton, sourceMesh.bindMatrix );
		} );

		return clone;
	}

	/// Creates a label that visualizes the UUID of a game entity.
	static three.Sprite createUUIDLabel(String uuid ) {
		final canvas = document.createElement( 'canvas' );
		final context = canvas.getContext( '2d' );

		canvas.width = 512;
		canvas.height = 64;

		context.fillStyle = '#ee0808';
		context.fillRect( 0, 0, canvas.width, canvas.height );

		context.fillStyle = '#ffffff';
		context.font = '24px Arial';
		context.textAlign = 'center';
		context.textBaseline = 'middle';
		context.fillText( uuid, canvas.width / 2, canvas.height / 2 );

		final texture = new CanvasTexture( canvas );
		final material = three.SpriteMaterial.fromJson( { 'map': texture } );

		final sprite = three.Sprite( material );

		sprite.scale.setValues( 4, 0.5, 1 );

		return sprite;

	}

	/// Creates a helper that visualizes the hitbox of an enemy.
	static three.LineSegments createHitboxHelper( AABB hitbox ) {
		final indices = <int>[ 0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7 ];
		final positions = <double>[ 1, 1, 1, - 1, 1, 1, - 1, - 1, 1, 1, - 1, 1, 1, 1, - 1, - 1, 1, - 1, - 1, - 1, - 1, 1, - 1, - 1 ];
		final geometry = three.BufferGeometry();

		geometry.setIndex( indices );
		geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );

		final lines = three.LineSegments( geometry, three.LineBasicMaterial.fromMap( { 'color': 0xffffff } ) );
		lines.matrixAutoUpdate = false;

		hitbox.getCenter( lines.position );
		hitbox.getSize( lines.scale );
		lines.scale.scale( 0.5 );
		lines.updateMatrix();

		return lines;

	}

	/// Creates helper points to visualize the spawning points of the game.
	static three.Group createSpawnPointHelper(List<Vector3> spawnPoints ) {
		final group = three.Group();
		group.matrixAutoUpdate = false;

		final nodeColor = 0xff0000;
		final nodeMaterial = three.MeshBasicMaterial.fromMap( { 'color': nodeColor } );
		final nodeGeometry = three.CylinderGeometry( 0.2, 0.2, 0.5 );
		nodeGeometry.translate( 0, 0.25, 0 );

		for ( int i = 0, l = spawnPoints.length; i < l; i ++ ) {

			final nodeMesh = three.Mesh( nodeGeometry, nodeMaterial );
			nodeMesh.position.setFrom( spawnPoints[ i ].position );

			nodeMesh.matrixAutoUpdate = false;
			nodeMesh.updateMatrix();

			group.add( nodeMesh );

		}

		group.visible = false;

		return group;

	}

	/// Creates a trigger helper in order to visualize the position and
	/// trigger region.
	static three.Mesh createTriggerHelper(Trigger trigger ) {
		// assuming trigger.region is of type SphericalTriggerRegion
		final triggerGeometry = three.SphereGeometry( trigger.region.radius, 16, 16 );
		final triggerMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x6083c2, 'wireframe': true } );

		final triggerMesh = three.Mesh( triggerGeometry, triggerMaterial );
		triggerMesh.matrixAutoUpdate = false;
		triggerMesh.visible = false;

		return triggerMesh;
	}

  //
  static void parallelTraverse( a, b, callback ) {
    callback( a, b );
    for ( int i = 0; i < a.children.length; i ++ ) {
      parallelTraverse( a.children[ i ], b.children[ i ], callback );
    }
  }
}
