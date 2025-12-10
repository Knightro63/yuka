import 'dart:math' as math;
import 'package:yuka/perception/vision/vision.dart';

import '../math/math_utils.dart';
import '../math/matrix4.dart';
import '../math/quaternion.dart';
import '../math/ray.dart';
import '../math/vector3.dart';
import 'console_logger/console_platform.dart';
import 'entity_manager.dart';
import 'telegram.dart';
import '../constants.dart';

/// Base class for all game entities.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class GameEntity {
  final targetRotation = Quaternion();
  final targetDirection = Vector3();
  final positionWorld = Vector3();
  final quaternionWorld = Quaternion();

  Vision? vision;

  String name = '';
  bool active = true;
  final List<GameEntity> children = [];
  GameEntity? parent;
  final List<GameEntity> neighbors = [];
  double neighborhoodRadius = 1;
  bool updateNeighborhood = false;
  final Vector3 position = Vector3();
  final Quaternion rotation = Quaternion();
  final Vector3 scale = Vector3( 1, 1, 1 );
  final Vector3 forward = Vector3( 0, 0, 1 );
  final Vector3 up = Vector3( 0, 1, 0 );
  double boundingRadius = 0;
  double maxTurnRate = math.pi;
  bool canActivateTrigger = true;
  EntityManager? manager;

	final _localMatrix = Matrix4();
	final  _worldMatrix = Matrix4();
	final Map<String,dynamic> _cache = {
    'position': Vector3(),
    'rotation': Quaternion(),
    'scale': Vector3( 1, 1, 1 )
  };

  // render component
  dynamic renderComponent;
  Function? renderComponentCallback;

	bool started = false;
	String? _uuid;
	bool _worldMatrixDirty = false;

	/// A transformation matrix representing the world space of this game entity.
	Matrix4 worldMatrix(){
		_updateWorldMatrix();
		return _worldMatrix;
	}

	/// Unique ID, primarily used in context of serialization/deserialization.
	String? get uuid => _uuid ??= MathUtils.generateUUID();

	/// Executed when this game entity is updated for the first time by its {@link EntityManager}.
	GameEntity start() {
		return this;
	}

	/// Updates the internal state of this game entity. Normally called by {@link EntityManager#update}
	/// in each simulation step.
	GameEntity update(double delta) {
		return this;
	}

	/// Adds a game entity as a child to this game entity.
	GameEntity add(GameEntity entity ) {
		if ( entity.parent != null ) {
			entity.parent?.remove( entity );
		}

		children.add( entity );
		entity.parent = this;

		return this;
	}

	/// Removes a game entity as a child from this game entity.
	GameEntity remove(GameEntity entity ) {
		final index = children.indexOf( entity );
		children.removeAt( index );

		entity.parent = null;

		return this;
	}

	/// Computes the current direction (forward) vector of this game entity
	/// and stores the result in the given vector.
	Vector3 getDirection(Vector3 result ) {
		return result.copy( forward ).applyRotation( rotation ).normalize();
	}

	/// Directly rotates the entity so it faces the given target position.
	GameEntity lookAt(Vector3 target ) {
		final parent = this.parent;

		if ( parent != null ) {
			getWorldPosition( positionWorld );
			targetDirection.subVectors( target, positionWorld ).normalize();
			rotation.lookAt( forward, targetDirection, up );
			quaternionWorld.extractRotationFromMatrix( parent.worldMatrix() ).inverse();
			rotation.premultiply( quaternionWorld );
		} 
    else {
			targetDirection.subVectors( target, position ).normalize();
			rotation.lookAt( forward, targetDirection, up );
		}

		return this;
	}

	/// Given a target position, this method rotates the entity by an amount not
	/// greater than {@link GameEntity#maxTurnRate} until it directly faces the target.
	bool rotateTo(Vector3 target, double delta, [double? tolerance] ) {
    tolerance ??= MathUtils.epsilon;
		final parent = this.parent;

		if ( parent != null ) {
			getWorldPosition( positionWorld );
			targetDirection.subVectors( target, positionWorld ).normalize();
			targetRotation.lookAt( forward, targetDirection, up );
			quaternionWorld.extractRotationFromMatrix( parent.worldMatrix() ).inverse();
			targetRotation.premultiply( quaternionWorld );
		} 
    else {
			targetDirection.subVectors( target, position ).normalize();
			targetRotation.lookAt( forward, targetDirection, up );
		}

		return rotation.rotateTo( targetRotation, maxTurnRate * delta, tolerance );
	}

	/// Computes the current direction (forward) vector of this game entity
	/// in world space and stores the result in the given vector.
	Vector3 getWorldDirection(Vector3 result ) {
		quaternionWorld.extractRotationFromMatrix( worldMatrix() );
		return result.copy( forward ).applyRotation( quaternionWorld ).normalize();
	}

	/// Computes the current position of this game entity in world space and
	/// stores the result in the given vector.
	Vector3 getWorldPosition(Vector3 result ) {
		return result.extractPositionFromMatrix( worldMatrix() );
	}

	/// Sets a renderable component of a 3D engine with a sync callback for this game entity.
	GameEntity setRenderComponent([ renderComponent, Function? callback ]) {
		this.renderComponent = renderComponent;
		renderComponentCallback = callback;

		return this;
	}

	/// Holds the implementation for the message handling of this game entity.
	bool handleMessage(Telegram telegram) {
		return false;
	}

	/// Holds the implementation for the line of sight test of this game entity.
	/// This method is used by {@link Vision#visible} in order to determine whether
	/// this game entity blocks the given line of sight or not. Implement this method
	/// when your game entity acts as an obstacle.
	Vector3? lineOfSightTest(Ray ray, Vector3 intersectionPoint) {
		return null;
	}

	/// Sends a message with the given data to the specified receiver.
	GameEntity sendMessage(GameEntity receiver, String message, [double delay = 0, Map<String,dynamic>? data]) {
		if ( manager != null ) {
			manager?.sendMessage( this, receiver, message, delay, data );
		} 
    else {
			yukaConsole.error( 'YUKA.GameEntity: The game entity must be added to a manager in order to send a message.' );
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'uuid': uuid,
			'name': name,
			'active': active,
			'children': entitiesToIds( children ),
			'parent': parent?.uuid,
			'neighbors': entitiesToIds( neighbors ),
			'neighborhoodRadius': neighborhoodRadius,
			'updateNeighborhood': updateNeighborhood,
			'position': position.storage,
			'rotation': rotation.storage,
			'scale': scale.storage,
			'forward': forward.storage,
			'up': up.storage,
			'boundingRadius': boundingRadius,
			'maxTurnRate': maxTurnRate,
			'canActivateTrigger': canActivateTrigger,
			'worldMatrix': worldMatrix().elements,
			'_localMatrix': _localMatrix.elements,
			'_cache': {
				position: _cache['position'].storage,
				rotation: _cache['rotation'].storage,
				scale: _cache['scale'].storage,
			},
			'_started': started
		};
	}

	/// Restores this instance from the given JSON object.
	GameEntity fromJSON(Map<String,dynamic> json ) {
		name = json['name'];
		active = json['active'];
		neighborhoodRadius = json['neighborhoodRadius'];
		updateNeighborhood = json['updateNeighborhood'];
		position.fromArray( json['position'] );
		rotation.fromArray( json['rotation'] );
		scale.fromArray( json['scale'] );
		forward.fromArray( json['forward'] );
		up.fromArray( json['up'] );
		boundingRadius = json['boundingRadius'];
		maxTurnRate = json['maxTurnRate'];
		canActivateTrigger = json['canActivateTrigger'];
    children.clear();
    children.addAll(json['children'].subList());
    neighbors.clear();
    neighbors.addAll(json['children'].subList());
		parent = json['parent'];

		_localMatrix.fromArray( json['_localMatrix'] );
		_worldMatrix.fromArray( json['worldMatrix'] );

		_cache['position'].fromArray( json['_cache'].position );
		_cache['rotation'].fromArray( json['_cache'].rotation );
		_cache['scale'].fromArray( json['_cache'].scale );

		started = json['_started'];

		_uuid = json['uuid'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	GameEntity resolveReferences(Map<String,GameEntity> entities ) {
		//
		final neighbors = this.neighbors;
		for ( int i = 0, l = neighbors.length; i < l; i ++ ) {
			neighbors[ i ] = entities.get( neighbors[ i ] )!;
		}

		//
		final children = this.children;
		for ( int i = 0, l = children.length; i < l; i ++ ) {
			children[ i ] = entities.get( children[ i ] )!;
		}

		//
		parent = entities.get( parent! );

		return this;
	}

	// Updates the transformation matrix representing the local space.
	void _updateMatrix() {
		final cache = _cache;

		if ( cache['position'].equals( position ) &&
				cache['rotation'].equals( rotation ) &&
				cache['scale'].equals( scale ) ) {
			return;
		}

		_localMatrix.compose( position, rotation, scale );

		cache['position'].copy( position );
		cache['rotation'].copy( rotation );
		cache['scale'].copy( scale );

		_worldMatrixDirty = true;
	}

	void _updateWorldMatrix() {
		final parent = this.parent;

		if ( parent != null ) {
			parent._updateWorldMatrix();
		}

		_updateMatrix();

		if ( _worldMatrixDirty == true ) {
			if ( parent == null ) {
				_worldMatrix.copy( _localMatrix );
			} 
      else {
				_worldMatrix.multiplyMatrices( this.parent!._worldMatrix, _localMatrix );
			}

			_worldMatrixDirty = false;

			// invalidate world matrices of children
			final children = this.children;

			for ( int i = 0, l = children.length; i < l; i ++ ) {
				final child = children[ i ];
				child._worldMatrixDirty = true;
			}
		}
	}

	// deprecated
	GameEntity updateWorldMatrix() {
		// this warning will be removed with v1.0.0
		yukaConsole.warning( 'GameEntity: .updateWorldMatrix() has been removed. World matrices are automatically updated on access.' );
		return this;
	}

  entitiesToIds( array ) {
    final ids = [];

    for ( int i = 0, l = array.length; i < l; i ++ ) {
      ids.add( array[ i ].uuid );
    }

    return ids;
  }
}
