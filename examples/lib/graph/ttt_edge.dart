import 'package:yuka/yuka.dart';

class TTTEdge extends Edge {
  int cell;
  int player;

	TTTEdge( super.from, super.to, this.cell, this.player );
}