import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;

/// Class for representing the bounds of an enemy. Its primary purpose is to avoid
/// expensive operations on the actual geometry of an enemy. Hence, intersection test
/// are perfomed with a simple hierarchy of AABBs.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class CharacterBounds {
  final rayBindSpace = Ray();
  final GameEntity owner;

  final _outerHitbox = AABB();
  final _outerHitboxDefinition = AABB();

  final Map<String,dynamic> _cache = {};
  final List _innerHitboxes = [];

	CharacterBounds( this.owner );

	// Inits the bounding volumes of this instance.
	CharacterBounds init() {
		_outerHitboxDefinition.set( Vector3( - 0.5, 0, - 0.5 ), Vector3( 0.5, 1.8, 0.5 ) );

		final owner = this.owner;

		// skeleton based AABBs
		final renderComponent = owner.renderComponent;
		final hitboxes = _innerHitboxes;

		// ensure world matrices are up to date
		renderComponent.updateMatrixWorld( true );

		// head and torso

		final headBone = renderComponent.getObjectByName( 'Armature_mixamorigHead' );
		final head = AABB( Vector3( - 0.1, 1.6, - 0.1 ), Vector3( 0.1, 1.8, 0.1 ) );
		Matrix4 bindMatrix = Matrix4().copy( headBone.matrixWorld );
		Matrix4 bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': head, 'bone': headBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final spineBone = renderComponent.getObjectByName( 'Armature_mixamorigSpine1' );
		final spine = AABB( Vector3( - 0.2, 1, - 0.2 ), Vector3( 0.2, 1.6, 0.2 ) );
		bindMatrix = Matrix4().copy( spineBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': spine, 'bone': spineBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		// arms

		final rightArmBone = renderComponent.getObjectByName( 'Armature_mixamorigRightArm' );
		final rightArm = AABB( Vector3( - 0.4, 1.42, - 0.15 ), Vector3( - 0.2, 1.58, 0.1 ) );
		bindMatrix = Matrix4().copy( rightArmBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': rightArm, 'bone': rightArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final rightForeArmBone = renderComponent.getObjectByName( 'Armature_mixamorigRightForeArm' );
		final rightForeArm = AABB( Vector3( - 0.8, 1.42, - 0.15 ), Vector3( - 0.4, 1.55, 0.05 ) );
		bindMatrix = Matrix4().copy( rightForeArmBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': rightForeArm, 'bone': rightForeArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftArmBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftArm' );
		final leftArm = AABB( Vector3( 0.2, 1.42, - 0.15 ), Vector3( 0.4, 1.58, 0.1 ) );
		bindMatrix = Matrix4().copy( leftArmBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': leftArm, 'bone': leftArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftForeArmBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftForeArm' );
		final leftForeArm = AABB( Vector3( 0.4, 1.42, - 0.15 ), Vector3( 0.8, 1.55, 0.05 ) );
		bindMatrix = Matrix4().copy( leftForeArmBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': leftForeArm, 'bone': leftForeArmBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		// legs
		final rightUpLegBone = renderComponent.getObjectByName( 'Armature_mixamorigRightUpLeg' );
		final rightUpLeg = AABB( Vector3( - 0.2, 0.6, - 0.15 ), Vector3( 0, 1, 0.15 ) );
		bindMatrix = Matrix4().copy( rightUpLegBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': rightUpLeg, 'bone': rightUpLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final rightLegBone = renderComponent.getObjectByName( 'Armature_mixamorigRightLeg' );
		final rightLeg = AABB( Vector3( - 0.2, 0, - 0.15 ), Vector3( 0, 0.6, 0.15 ) );
		bindMatrix = Matrix4().copy( rightLegBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': rightLeg, 'bone': rightLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftUpLegBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftUpLeg' );
		final leftUpLeg = AABB( Vector3( 0, 0.6, - 0.15 ), Vector3( 0.2, 1, 0.15 ) );
		bindMatrix = Matrix4().copy( leftUpLegBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': leftUpLeg, 'bone': leftUpLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		final leftLegBone = renderComponent.getObjectByName( 'Armature_mixamorigLeftLeg' );
		final leftLeg = AABB( Vector3( 0, 0, - 0.15 ), Vector3( 0.2, 0.6, 0.15 ) );
		bindMatrix = Matrix4().copy( leftLegBone.matrixWorld );
		bindMatrixInverse = Matrix4().getInverse( bindMatrix );
		hitboxes.add( { 'aabb': leftLeg, 'bone': leftLegBone, 'bindMatrix': bindMatrix, 'bindMatrixInverse': bindMatrixInverse } );

		//

		// debugging the AABBs requires the skeleton the be in bind pose at the origin

		// for ( let i = 0, l = hitboxes.length; i < l; i ++ ) {

		// 	final hitbox = hitboxes[ i ];

		// 	final hitboxHelper = SceneUtils.createHitboxHelper( hitbox.aabb );
		// 	this.owner.world.scene.add( hitboxHelper );

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
				final hitbox = hitboxes[ i ];
				final bone = hitbox.bone;

				final inverseBoneMatrix = _getInverseBoneMatrix( bone );

				// transform the ray from world space to local space of the bone
				rayBindSpace.copy( ray ).applyMatrix4( inverseBoneMatrix );

				// transform the ray from local space of the bone to its bind space (T-Pose)
				rayBindSpace.applyMatrix4( hitbox.bindMatrix );

				// now perform the intersection test
				if ( rayBindSpace.intersectAABB( hitbox.aabb, intersectionPoint ) != null) {
					// since the intersection point is in bind space, it's necessary to convert back to world space
					intersectionPoint.applyMatrix4( hitbox.bindMatrixInverse ).applyMatrix4( bone.matrixWorld );
					return intersectionPoint;
				}
			}
		}

		return null;
	}

	/// Returns the current inverse matrix for the given bone. A cache system ensures, the inverse matrix
	/// is computed only once per simulation step.
	Matrix4 _getInverseBoneMatrix( three.Bone bone ) {
    final dynamic owner = this.owner;
    
		final world = owner.world;
		final tick = world.tick;

		// since computing inverse matrices is expensive, do it only once per simulation step
		let entry = _cache[bone];

		if ( entry == null ) {
			entry = { 'tick': tick, 'inverseBoneMatrix': Matrix4().fromArray( bone.matrixWorld.invert().storage ) };
			_cache[bone] = entry;
		} 
    else {
			if ( entry.tick < tick ) {
				entry.tick = tick;
				entry.inverseBoneMatrix.getInverse( bone.matrixWorld );
			} 
      else {
				if ( world.debug ) {
					yukaConsole.info( 'DIVE.CharacterBounds: Inverse matrix found in cache for bone.' );
				}
			}
		}

		return entry.inverseBoneMatrix;
	}
}
