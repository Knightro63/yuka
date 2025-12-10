import 'dart:async';
import 'package:examples/playground/shooter/world.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:examples/src/gui.dart';

class Shooter extends StatefulWidget {
  const Shooter({super.key});
  @override
  createState() => _State();
}

class _State extends State<Shooter> {
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    threeJs = three.ThreeJS(
      onSetupComplete: (){
        setState(() {});
      },
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          threeJs.build(),
          Text('The white fan represents the visibility range of the game entity.\nWhen the target is visible for the game entity, the target\'s color changes to green.'),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render()
            )
          ),
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.scene = three.Scene();
    final World world = World(threeJs);
    await world.init();
    threeJs.addAnimationEvent((dt){
      world.animate();
    });
	}
}
