import '../math/vector3.dart';

/// This class can be used to smooth the result of a vector calculation. One use case
/// is the smoothing of the velocity vector of game entities in order to avoid a shaky
/// movements due to conflicting forces.
class Smoother {
  int count;
  int _slot = 0; // the current sample slot
  final List<Vector3> _history = [];
  
	/// Constructs a new smoother.
	Smoother([ this.count = 10 ]) {
		// initialize history with Vector3s
		for ( int i = 0; i < count; i ++ ) {
			_history.add(Vector3());
		}
	}

	/// Calculates for the given value a smooth average.
	Vector3 calculate(Vector3 value, Vector3 average ) {
		// ensure, average is a zero vector
		average.set( 0, 0, 0 );

		// make sure the slot index wraps around

		if ( _slot == count ) {
			_slot = 0;
		}

		// overwrite the oldest value with the newest
		_history[ _slot ].copy( value );

		// increase slot index
		_slot ++;

		// now calculate the average of the history array

		for ( int i = 0; i < count; i ++ ) {
			average.add( _history[ i ] );
		}

		average.divideScalar( count *1.0 );

		return average;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> data = {
			'type': runtimeType.toString(),
			'count': count,
			'_history': [],
			'_slot': _slot
		};

		// history

		final history = _history;

		for (int i = 0, l = history.length; i < l; i ++ ) {
			final value = history[ i ];
			data['_history']?.add( value.storage );
		}

		return data;
	}

	/// Restores this instance from the given JSON object.
	Smoother fromJSON(Map<String,dynamic> json ) {
		count = json['count'];
		_slot = json['_slot'];

		// history

		final historyJSON = json['_history'];
		_history.length = 0;

		for ( int i = 0, l = historyJSON.length; i < l; i ++ ) {
			final valueJSON = historyJSON[ i ];
			_history.add( Vector3().fromArray( valueJSON ) );
		}


		return this;
	}
}
