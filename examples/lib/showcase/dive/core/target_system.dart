import 'package:yuka/yuka.dart';

final visibleRecords = [];
final invisibleRecords = [];

/**
* Class to select a target from the opponents currently in a bot's perceptive memory.
*
* @author {@link https://github.com/robp94|robp94}
*/
class TargetSystem {

	/**
	* finalructs a new target system with the given values.
	*
	* @param {GameEntity} owner - The owner of this weapon system.
	*/
	TargetSystem( owner ) {
		this.owner = owner; // enemy
		this._currentRecord = null; // represents the memory record of the current target
	}

	/**
	* Updates the target system internal state.
	*
	* @return {TargetSystem} A reference to this target system.
	*/
	TargetSystem update() {
		final records = this.owner.memoryRecords;

		// reset
		this._currentRecord = null;

		visibleRecords.length = 0;
		invisibleRecords.length = 0;

		// sort records according to their visibility
		for ( int i = 0, l = records.length; i < l; i ++ ) {
			final record = records[ i ];

			if ( record.visible ) {
				visibleRecords.add( record );
			} 
      else {
				invisibleRecords.add( record );
			}
		}

		// record selection
		if ( visibleRecords.isNotEmpty ) {
			// if there are visible records, select the closest one
			double minDistance = double.infinity;

			for ( int i = 0, l = visibleRecords.length; i < l; i ++ ) {
				final record = visibleRecords[ i ];
				final distance = this.owner.position.squaredDistanceTo( record.lastSensedPosition );

				if ( distance < minDistance ) {
					minDistance = distance;
					this._currentRecord = record;
				}
			}
		} 
    else if ( invisibleRecords.isNotEmpty ) {
			// if there are invisible records, select the one that was last sensed
			let maxTimeLastSensed = - double.infinity;

			for ( int i = 0, l = invisibleRecords.length; i < l; i ++ ) {
				final record = invisibleRecords[ i ];

				if ( record.timeLastSensed > maxTimeLastSensed ) {
					maxTimeLastSensed = record.timeLastSensed;
					this._currentRecord = record;
				}
			}
		}

		return this;
	}

	/**
	* Resets the internal data structures.
	*
	* @return {TargetSystem} A reference to this target system.
	*/
	TargetSystem reset() {
		this._currentRecord = null;
		return this;
	}

	/**
	* Checks if the target is shootable/visible or not
	*
	* @return {Boolean} Whether the target is shootable/visible or not.
	*/
	bool isTargetShootable() {
		return this._currentRecord.visible ?? false;
	}

	/**
	* Returns the last sensed position of the target, or null if there is no target.
	*
	* @return {Vector3} The last sensed position of the target.
	*/
	Vector3? getLastSensedPosition() {
		return this._currentRecord.lastSensedPosition;
	}

	/**
	* Returns the time when the target was last sensed or -1 if there is none.
	*
	* @return {Number} The time when the target was last sensed.
	*/
	double getTimeLastSensed() {
		return this._currentRecord.timeLastSensed ?? - 1;
	}

	/**
	* Returns the time when the target became visible or -1 if there is none.
	*
	* @return {Number} The time when the target became visible.
	*/
	double getTimeBecameVisible() {
		return this._currentRecord.timeBecameVisible ?? - 1;
	}

	/** Returns the current target if there is one.
	*
	* @returns {Enemy} Returns the current target if there is one, else null.
	*/
	Enemy getTarget() {
		return this._currentRecord.entity;
	}

	/** Returns true if the enemy has an active target.
	*
	* @returns {Boolean} Whether the enemy has an active target or not.
	*/
	bool hasTarget() {
		return this._currentRecord != null;
	}
}