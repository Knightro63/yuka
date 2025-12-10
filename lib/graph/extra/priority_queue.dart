
/// Class for representing a binary heap priority queue that enables
/// more efficient sorting of arrays. The implementation is based on
/// { @link https://github.com/mourner/tinyqueue tinyqueue}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class PriorityQueue {
  int length = 0;
  late Function compare;
  List data = [];

	/// Constructs a new priority queue.
	PriorityQueue([Function? compare]) {
		this.compare = compare ?? defaultCompare;
	}

	/// Pushes an item to the priority queue.
	void push( item ) {
		data.add( item );
		length ++;
		_up( length - 1 );
	}

	/// Returns the item with the highest priority and removes
	/// it from the priority queue.
	pop() {
		if ( length == 0 ) return null;

		final top = data[ 0 ];
		length --;

		if ( length > 0 ) {
			data[ 0 ] = data[ length ];
			_down( 0 );
		}

		data.removeLast();

		return top;
	}

	/// Returns the item with the highest priority without removal.
	peek() {
		return data[ 0 ];
	}

	void _up(int index ) {
		final data = this.data;
		final compare = this.compare;
		final item = data[ index ];

		while ( index > 0 ) {
			final parent = ( index - 1 ) >> 1;
			final current = data[ parent ];
			if ( compare( item, current ) >= 0 ) break;
			data[ index ] = current;
			index = parent;
		}

		data[ index ] = item;
	}

	void _down(int index ) {
		final data = this.data;
		final compare = this.compare;
		final item = data[ index ];
		final halfLength = length >> 1;

		while ( index < halfLength ) {
			int left = ( index << 1 ) + 1;
			int right = left + 1;
			dynamic best = data[ left ];

			if ( right < length && compare( data[ right ], best ) < 0 ) {

				left = right;
				best = data[ right ];

			}

			if ( compare( best, item ) >= 0 ) break;

			data[ index ] = best;
			index = left;
		}

		data[ index ] = item;
	}

  defaultCompare( a, b ) {
    return ( a < b ) ? - 1 : ( a > b ) ? 1 : 0;
  }
}
