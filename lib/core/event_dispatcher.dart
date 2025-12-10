
/// Other classes can inherit from this class in order to provide an
/// event based API. Useful for controls development.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class EventDispatcher {
  final Map<String, List<Function>> _events = {};

	/// Adds an event listener for the given event type.
	void addEventListener(String type, Function listener ) {
		final events = _events;

		if ( events.containsKey( type ) == false ) {
			events[type] = [];
		}

		final listeners = events[type];

		if ( !listeners!.contains( listener )) {
			listeners.add( listener );
		}
	}

	/// Removes the given event listener for the given event type.
	void removeEventListener(String type, Function listener ) {
		final events = _events;
		final listeners = events[type];

		if ( listeners != null ) {
			final index = listeners.indexOf( listener );
			if ( index != - 1 ) listeners.removeAt( index );
		}
	}

	/// Returns true if the given event listener is set for the given event type.
	bool hasEventListener(String type, Function listener ) {
		final events = _events;
		final listeners = events[type];

		return ( listeners != null ) && (listeners.contains( listener ));
	}

	/// Dispatches an event to all respective event listeners.
	void dispatchEvent( event ) {
		final events = _events;
		final listeners = events[event.type];

		if ( listeners != null ) {
			event.target = this;

			for ( int i = 0, l = listeners.length; i < l; i ++ ) {
				listeners[i].call( this, event );
			}
		}
	}
}
