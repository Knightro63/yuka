import '../../core/game_entity.dart';
import '../trigger.dart';
import '../trigger_region.dart';
import '../../math/aabb.dart';
import '../../math/bounding_sphere.dart';
import '../../math/vector3.dart';

/// Class for representing a rectangular trigger region as an AABB.
class RectangularTriggerRegion extends TriggerRegion {
  late final Vector3 size;
  final AABB _aabb = AABB();
  final boundingSphereEntity = BoundingSphere();
  final center = Vector3();

	/// Constructs a new rectangular trigger region with the given values.
	RectangularTriggerRegion([Vector3? size]):super() {
		this.size = size ?? Vector3();
	}

	/// Returns true if the bounding volume of the given game entity touches/intersects
	/// the trigger region.
  @override
	bool touching([GameEntity? entity ]) {
    if(entity == null) return false;
		boundingSphereEntity.set( entity.position, entity.boundingRadius );
		return _aabb.intersectsBoundingSphere( boundingSphereEntity );
	}

	/// Updates this trigger region.
  @override
	RectangularTriggerRegion update([Trigger? trigger ]) {
		trigger?.getWorldPosition( center );
		_aabb.fromCenterAndSize( center, size );
		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['size'] = size.toArray([]);
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	RectangularTriggerRegion fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		size.fromArray( json['size'] );
		return this;
	}
}
