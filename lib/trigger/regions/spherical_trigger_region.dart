import '../../core/game_entity.dart';
import '../../math/bounding_sphere.dart';
import '../trigger.dart';
import '../trigger_region.dart';

/// Class for representing a spherical trigger region as a bounding sphere.
class SphericalTriggerRegion extends TriggerRegion {
  double radius = 0;
  final BoundingSphere _boundingSphere = BoundingSphere();
  final boundingSphereEntity = BoundingSphere();

	/// Constructs a new spherical trigger region.
	SphericalTriggerRegion([this.radius = 0]):super();

	/// Returns true if the bounding volume of the given game entity touches/intersects
	/// the trigger region.
  @override
	bool touching([GameEntity? entity]) {
		entity?.getWorldPosition( boundingSphereEntity.center );
		boundingSphereEntity.radius = entity?.boundingRadius ?? 0;

		return _boundingSphere.intersectsBoundingSphere( boundingSphereEntity );
	}

	/// Updates this trigger region.
  @override
	SphericalTriggerRegion update([Trigger? trigger]) {
		trigger?.getWorldPosition( _boundingSphere.center );
		_boundingSphere.radius = radius;

		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['radius'] = radius;
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	SphericalTriggerRegion fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		radius = json['radius'];
		return this;
	}
}
