
import 'package:examples/common/path_planner_task.dart';
import 'package:yuka/yuka.dart';

class PathPlanner {
  final NavMesh navMesh;
  final taskQueue = TaskQueue();

	PathPlanner( this.navMesh );

	void findPath(Vehicle vehicle, Vector3 from, Vector3 to, void Function(Vehicle vehicle, List<Vector3> path) callback ) {
		final task = new PathPlannerTask( this, vehicle, from, to, callback );
		taskQueue.enqueue( task );
	}

	void update() {
		taskQueue.update();
	}
}
