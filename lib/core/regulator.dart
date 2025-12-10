import './time.dart';

/// Not all components of an AI system need to be updated in each simulation step.
/// This class can be used to control the update process by defining how many updates
/// should be executed per second.
class Regulator {
  double updateFrequency;
  final Time _time = Time();
  double _nextUpdateTime = 0;

	/// Constructs a new regulator.
	Regulator([ this.updateFrequency = 0 ]) {
		_nextUpdateTime = 0;
	}

	/// Returns true if it is time to allow the next update.
	bool ready() {
		_time.update();

		final elapsedTime = _time.elapsed;

		if ( elapsedTime >= _nextUpdateTime ) {
			_nextUpdateTime = elapsedTime + ( 1 / updateFrequency );
			return true;
		}

		return false;
	}
}
