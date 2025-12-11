import 'dart:async';
import 'package:examples/playground/shooter/world.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class Shooter extends StatefulWidget {
  const Shooter({super.key});
  @override
  createState() => _State();
}

class _State extends State<Shooter> {
  late three.ThreeJS threeJs;
  late final World world;

  @override
  void initState() {
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
          Text('This demo implements some basic concepts of First-Person shooters e.g. simulating bullets and collision detection.'),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xff992129).withValues(alpha:0.5),
                  width: 2
                ),
                borderRadius: BorderRadius.circular(5)
              ),
            )
          ),
          if(threeJs.mounted)Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 120,
              height: 75,
              color: Colors.grey[900],
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    world.player!.weapon.ui['roundsLeft'].toString(),
                    style: TextStyle(fontSize: 20),
                  ),
                  Container(
                    width: 0.5,
                    height: 75,
                    color: Colors.white,
                  ),
                  Text(
                    world.player!.weapon.ui['ammo'].toString(),
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              )
            ),
          )
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.scene = three.Scene();
    world = World(threeJs);
    await world.init();
    threeJs.addAnimationEvent((dt){
      world.animate();
    });
	}
}
