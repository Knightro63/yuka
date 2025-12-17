import 'package:examples/navigation/path_planner.dart';
import 'package:yuka/yuka.dart';

class PathPlannerTask extends Task {
  final PathPlanner planner;
  final Vehicle vehicle;
  final Vector3 from;
  final Vector3 to;
  final void Function(Vehicle vehicle, List<Vector3> path) callback;

	PathPlannerTask(this.planner, this.vehicle, this.from, this.to, this.callback ):super();

  @override
	void execute() {
		final path = planner.navMesh.findPath( from, to );
		callback( vehicle, path );
	}
}
