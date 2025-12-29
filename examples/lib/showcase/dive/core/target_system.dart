import 'package:yuka/yuka.dart';


/// Class to select a target from the opponents currently in a bot's perceptive memory.
///
/// @author {@link https://github.com/robp94|robp94}
class TargetSystem {
  final visibleRecords = [];
  final invisibleRecords = [];

  dynamic owner;
  dynamic _currentRecord;
	TargetSystem( this.owner );

	/// Updates the target system internal state.
	TargetSystem update() {
		final records = owner.memoryRecords;

		// reset
		_currentRecord = null;

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
				final distance = owner.position.squaredDistanceTo( record.lastSensedPosition );

				if ( distance < minDistance ) {
					minDistance = distance;
					_currentRecord = record;
				}
			}
		} 
    else if ( invisibleRecords.isNotEmpty ) {
			// if there are invisible records, select the one that was last sensed
			double maxTimeLastSensed = - double.infinity;

			for ( int i = 0, l = invisibleRecords.length; i < l; i ++ ) {
				final record = invisibleRecords[ i ];

				if ( record.timeLastSensed > maxTimeLastSensed ){
					maxTimeLastSensed = record.timeLastSensed;
					_currentRecord = record;
				}
			}
		}

		return this;
	}

	/// Resets the internal data structures.
	TargetSystem reset() {
		_currentRecord = null;
		return this;
	}

	/// Checks if the target is shootable/visible or not
	bool isTargetShootable() {
		return _currentRecord.visible ?? false;
	}

	/// Returns the last sensed position of the target, or null if there is no target.
	Vector3? getLastSensedPosition() {
		return _currentRecord.lastSensedPosition;
	}

	/// Returns the time when the target was last sensed or -1 if there is none.
	double getTimeLastSensed() {
		return _currentRecord.timeLastSensed ?? - 1;
	}

	/// Returns the time when the target became visible or -1 if there is none.
	double getTimeBecameVisible() {
		return _currentRecord.timeBecameVisible ?? - 1;
	}

	/// Returns the current target if there is one.
	getTarget() {
		return _currentRecord?.entity;
	}

	/// Returns true if the enemy has an active target.
	bool hasTarget() {
		return _currentRecord != null;
	}
}