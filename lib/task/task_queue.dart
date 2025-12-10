import 'task.dart';

/// This class is used for task management. Tasks are processed in an asynchronous
/// way when there is idle time within a single simulation step or after a defined amount
/// of time (deadline). The class is a wrapper around {@link https://w3.org/TR/requestidlecallback|requestidlecallback()},
/// a JavaScript API for cooperative scheduling of background tasks.
class TaskQueue {
  Duration options = Duration(milliseconds: 1000);
  bool _active = false;
  void Function()? _handler;
  Future<dynamic>? taskHandle;
  List<Task> tasks = [];
  Stopwatch stopwatch = Stopwatch();
    
	/// Constructs a new task queue.
	TaskQueue() {
		_handler = runTaskQueue;
	}

	/// Adds the given task to the task queue.
	TaskQueue enqueue(Task task ) {
		tasks.add( task );
		return this;
	}

	/// Updates the internal state of the task queue. Should be called
	/// per simulation step.
	TaskQueue update() {
		if ( tasks.isNotEmpty ) {
			if ( _active == false ) {
        stopwatch.reset();
        stopwatch.start();
				taskHandle = Future.delayed(Duration.zero, _handler).timeout(options,onTimeout: (){stopwatch.stop();});//requestIdleCallback( _handler, options );
				_active = true;
			}
		} 
    else {
			_active = false;
		}
		return this;
	}

  /// This function controls the processing of tasks. It schedules tasks when there
  /// is idle time at the end of a simulation step.
  void runTaskQueue() {//deadline
    final tasks = this.tasks;

    while ( stopwatch.elapsed < options && tasks.isNotEmpty ) {
      final task = tasks[ 0 ];
      task.execute();
      tasks.removeAt(0);
    }

    if ( tasks.isNotEmpty ) {
      stopwatch.reset();
      stopwatch.start();
      taskHandle = Future.delayed(Duration.zero, _handler).timeout(options,onTimeout: (){stopwatch.stop();});//requestIdleCallback( _handler, options );
      _active = true;
    } 
    else {
      taskHandle = null;
      _active = false;
      stopwatch.stop();
    }
  }
}
