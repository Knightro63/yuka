
/// Class for representing a timer.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Time {
  double _previousTime = 0;
  double _currentTime = 0;
  double _delta = 0;
  double _elapsed = 0;
  double _timescale = 1;
  bool _useFixedDelta = false;
  double _fixedDelta = 16.67; // ms, corresponds to approx.
  bool usePageVisibilityAPI = false;
  late void Function()? pageVisibilityHandler;

	/// Constructs a new time object.
	Time([void Function()? pageVisibilityHandler]) {
		if ( usePageVisibilityAPI == true ) {
			pageVisibilityHandler = pageVisibilityHandler;
			//document.addEventListener( 'visibilitychange', _pageVisibilityHandler, false );
		}

	}

	/// Disables the usage of a fixed delta value.
	Time disableFixedDelta() {
		_useFixedDelta = false;
		return this;
	}

	/// Frees all internal resources.
	Time dispose() {
		if ( usePageVisibilityAPI == true ) {
			//document.removeEventListener( 'visibilitychange', _pageVisibilityHandler );
		}

		return this;
	}

	/// Enables the usage of a fixed delta value. Can be useful for debugging and testing.
	Time enableFixedDelta() {
		_useFixedDelta = true;
		return this;
	}

	/// Returns the delta time in seconds. Represents the completion time in seconds since
	/// the last simulation step.
	double get delta => _delta / 1000;

	/// Returns the elapsed time in seconds. It's the accumulated
	/// value of all previous time deltas.
	double get elapsed => _elapsed / 1000;

	/// Returns the fixed delta time in seconds.
	double get fixedDelta => _fixedDelta / 1000;

	/// Returns the timescale value.
	double get timescale => _timescale;

	/// Resets this time object.
	Time reset() {
		_currentTime = _now();
		return this;
	}

	/// Sets a fixed time delta value.
	Time setFixedDelta(double fixedDelta ) {
		_fixedDelta = fixedDelta * 1000;
		return this;
	}

	/// Sets a timescale value. This value represents the scale at which time passes.
	/// Can be used for slow down or  accelerate the simulation.
	Time setTimescale(double timescale ) {
		_timescale = timescale;
		return this;
	}

	/// Updates the internal state of this time object.
	Time update() {
		if ( _useFixedDelta == true ) {
			_delta = _fixedDelta;
		} 
    else {
			_previousTime = _currentTime;
			_currentTime = _now();

			_delta = _currentTime - _previousTime;
		}

		_delta *= _timescale;
		_elapsed += _delta; // _elapsed is the accumulation of all previous deltas

		return this;
	}

	// private
  double _now() {
    return DateTime.now().millisecondsSinceEpoch.toDouble(); // see #10732
  }
}