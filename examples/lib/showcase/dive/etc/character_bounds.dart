import 'package:examples/showcase/dive/core/world.dart';
import 'package:examples/showcase/dive/entities/enemy.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;

final rayBindSpace = Ray();

/// Class for representing the bounds of an enemy. Its primary purpose is to avoid
/// expensive operations on the actual geometry of an enemy. Hence, intersection test
/// are perfomed with a simple hierarchy of AABBs.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CharacterBounds {
  
  final GameEntity owner;

  final _outerHitbox = AABB();
  final _outerHitboxDefinition = AABB();

  final Map _cache = {};
  final List _innerHitboxes = [];

	CharacterBounds( this.owner );

	// Inits the bounding volumes of this instance.
	CharacterBounds init() {
		_outerHitboxDefinition.set( Vector3( - 0.5, 0, - 0.5 ), Vector3( 0.5, 1.8, 0.5 ) );

		final Enemy owner = this.owner as Enemy;
    //final bool debug = owner.world.debug;

		// skeleton based AABBs
		final renderComponent = owner.renderComponent;

		// ensure world matrices are up to date
		renderComponent.updateMatrixWorld( true );

		// head and torso
		final three.Object3D headBone = renderComponent.getObjectByName( 'Armature_mixamorigHead' );
		final head = AABB( Vector3( - 0.1, 1.6, - 0.1 ), Vector3( 0.1, 1.8, 0.1 ) );
		Matrix4 bindMatrix = Matrix4().fromArray( headBone.matrixWorld.storage );
		Matrix4 bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': head, 'bone': headBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );
    //if(debug) headBone.add(SceneUtils.createHitBoxHelper( head ));

		final spineBone = renderComponent.getObjectByName( 'Armature_mixamorigSpine1' );
		final spine = AABB( Vector3( - 0.2, 1, - 0.2 ), Vector3( 0.2, 1.6, 0.2 ) );
		bindMatrix = Matrix4().fromArray( spineBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': spine, 'bone': spineBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		// arms
		final rightArmBone = renderComponent.getObjectByName( 'Armature_mixamorigRightArm' );
		final rightArm = AABB( Vector3( - 0.4, 1.42, - 0.15 ), Vector3( - 0.2, 1.58, 0.1 ) );
		bindMatrix = Matrix4().fromArray( rightArmBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': rightArm, 'bone': rightArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final rightForeArmBone = renderComponent.getObjectByName( 'Armature_mixamorigRightForeArm' );
		final rightForeArm = AABB( Vector3( - 0.8, 1.42, - 0.15 ), Vector3( - 0.4, 1.55, 0.05 ) );
		bindMatrix = Matrix4().fromArray( rightForeArmBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': rightForeArm, 'bone': rightForeArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftArmBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftArm' );
		final leftArm = AABB( Vector3( 0.2, 1.42, - 0.15 ), Vector3( 0.4, 1.58, 0.1 ) );
		bindMatrix = Matrix4().fromArray( leftArmBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': leftArm, 'bone': leftArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftForeArmBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftForeArm' );
		final leftForeArm = AABB( Vector3( 0.4, 1.42, - 0.15 ), Vector3( 0.8, 1.55, 0.05 ) );
		bindMatrix = Matrix4().fromArray( leftForeArmBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': leftForeArm, 'bone': leftForeArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		// legs
		final rightUpLegBone = renderComponent.getObjectByName( 'Armature_mixamorigRightUpLeg' );
		final rightUpLeg = AABB( Vector3( - 0.2, 0.6, - 0.15 ), Vector3( 0, 1, 0.15 ) );
		bindMatrix = Matrix4().fromArray( rightUpLegBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': rightUpLeg, 'bone': rightUpLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final rightLegBone = renderComponent.getObjectByName( 'Armature_mixamorigRightLeg' );
		final rightLeg = AABB( Vector3( - 0.2, 0, - 0.15 ), Vector3( 0, 0.6, 0.15 ) );
		bindMatrix = Matrix4().fromArray( rightLegBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': rightLeg, 'bone': rightLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftUpLegBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftUpLeg' );
		final leftUpLeg = AABB( Vector3( 0, 0.6, - 0.15 ), Vector3( 0.2, 1, 0.15 ) );
		bindMatrix = Matrix4().fromArray( leftUpLegBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': leftUpLeg, 'bone': leftUpLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftLegBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftLeg' );
		final leftLeg = AABB( Vector3( 0, 0, - 0.15 ), Vector3( 0.2, 0.6, 0.15 ) );
		bindMatrix = Matrix4().fromArray( leftLegBone.matrixWorld.storage );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		_innerHitboxes.add( { 'aabb': leftLeg, 'bone': leftLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		//

		// debugging the AABBs requires the skeleton the be in bind pose at the origin
    // if(owner.world.debug){
    //   for ( int i = 0, l = _innerHitboxes.length; i < l; i ++ ) {
    //     final hitbox = _innerHitboxes[ i ];
    //     final hitboxHelper = SceneUtils.createHitBoxHelper( hitbox['aabb'] );
    //     owner.renderComponent.add( hitboxHelper );
    //   }

    //   final hitboxHelper = SceneUtils.createHitBoxHelper( _outerHitboxDefinition );
    //   owner.renderComponent.add( hitboxHelper );
    // }

		return this;
	}

	/// Updates the outer bounding volume of this instance. Deeper bounding volumes
	/// are only update if necessary.
	CharacterBounds update() {
		_outerHitbox.copy( _outerHitboxDefinition ).applyMatrix4( owner.worldMatrix() );
		return this;
	}

	/// Computes the center point of this instance and stores it into the given vector.
	Vector3 getCenter( Vector3 center ) {
		return _outerHitbox.getCenter( center );
	}

	/// Returns the intesection point if the given ray hits one of the bounding volumes.
	/// If no intersection is detected, null is returned.
	Vector3? intersectRay( Ray ray, Vector3 intersectionPoint ) {
		// first text outer hitbox
		if ( ray.intersectAABB( _outerHitbox, intersectionPoint ) != null) {
			// now test with inner hitboxes
			final hitboxes = _innerHitboxes;

			for ( int i = 0, l = hitboxes.length; i < l; i ++ ) {
				final Map<String, dynamic> hitbox = hitboxes[ i ];
				final bone = hitbox['bone'];
        bone.updateMatrixWorld();

				final inverseBoneMatrix = _getInverseBoneMatrix( bone );

				// transform the ray from world space to local space of the bone
				rayBindSpace.copy( ray ).applyMatrix4( inverseBoneMatrix );

				// transform the ray from local space of the bone to its bind space (T-Pose)
				rayBindSpace.applyMatrix4( hitbox['bindMatrix'] );

				// now perform the intersection test
				if ( rayBindSpace.intersectAABB( hitbox['aabb'], intersectionPoint ) != null) {
					// since the intersection point is in bind space, it's necessary to convert back to world space
					intersectionPoint.applyMatrix4( hitbox['bindMatrixInverse'] ).applyMatrix4( Matrix4().fromArray((bone.matrixWorld as three.Matrix4).storage ));
					return intersectionPoint;
				}
			}

      return intersectionPoint;
		}

		return null;
	}

	/// Returns the current inverse matrix for the given bone. A cache system ensures, the inverse matrix
	/// is computed only once per simulation step.
	Matrix4 _getInverseBoneMatrix( three.Bone bone ) {
    final dynamic owner = this.owner;
    
		final World world = owner.world;
		final tick = world.tick;

		// since computing inverse matrices is expensive, do it only once per simulation step
		Map<String,dynamic>? entry = _cache[bone];

		if ( entry == null ) {
      final temp = Matrix4().fromArray(bone.matrixWorld.storage);
			entry = { 'tick': tick, 'inverseBoneMatrix': Matrix4().getInverse( temp ) };
			_cache[bone] = entry;
		} 
    else {
			if ( entry['tick'] < tick ) {
				entry['tick'] = tick;
        final temp = Matrix4().fromArray(bone.matrixWorld.storage);
				(entry['inverseBoneMatrix'] as Matrix4).getInverse( temp );
			} 
      else {
				if ( world.debug ) {
					yukaConsole.info( 'DIVE.CharacterBounds: Inverse matrix found in cache for bone.' );
				}
			}
		}

		return entry['inverseBoneMatrix'];
	}
}
