import 'dart:async';
import 'package:examples/playground/shooter/world.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_lock/pointer_lock.dart';
import 'package:three_js/three_js.dart' as three;

class Shooter extends StatefulWidget {
  const Shooter({super.key});
  @override
  createState() => _State();
}

class _State extends State<Shooter> {
  late three.ThreeJS threeJs;
  late final ShooterWorld world;

  StreamSubscription<PointerLockMoveEvent>? _subscription;
  Offset lastPointerDelta = Offset.zero;
  bool isPlaying = false;

  @override
  void initState() {
    pointerLock.ensureInitialized();
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
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: CallbackShortcuts(
      // Define the key combination to listen for
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _stopSession();
          },
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          child:Scaffold(
            body: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [
                threeJs.build(),
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
                ),
                if(!isPlaying)InkWell(
                  onTap: (){
                    if(threeJs.mounted){
                      setState(() {
                        isPlaying = true;
                        _startSession();
                      });
                    }
                  },
                  child:Container(
                    padding: EdgeInsets.only(left: 20,right: 20),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Colors.black.withAlpha(128),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text(
                            'Click to Play',
                            style: TextStyle(fontSize: 48),
                          ),
                          SizedBox(height: 50),
                          Text(
                            'This demo impliments some basic concepts of First-Person shooters e.g.(simulating bullets and collision detection.).',
                            style: TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  )
                )
              ],
            ) 
          )
        )
      )
    );
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.scene = three.Scene();
    world = ShooterWorld(threeJs);
    await world.init();
    threeJs.addAnimationEvent((dt){
      world.animate();
    });
	}

  void _startSession() {
    if (_subscription != null) {
      return;
    }
    final deltaStream = pointerLock.createSession(
      windowsMode: PointerLockWindowsMode.capture,
      cursor: PointerLockCursor.hidden,
    );
    final subscription = deltaStream.listen(
      (event) {
        _processMoveDelta(event.delta);
      },
      onDone: () {
        // Stream closed naturally
        _setSubscription(null);
      },
      onError: (error) {
        // Handle any errors
        debugPrint('Pointer lock error: $error');
        _setSubscription(null);
      },
    );
    _setSubscription(subscription);
  }

  void _stopSession() async {
    final subscription = _subscription;
    if (subscription == null) {
      return;
    }
    _setSubscription(null);
    await subscription.cancel();
  }

  void _setSubscription(StreamSubscription<PointerLockMoveEvent>? value) {
    _subscription = value;
  }

  void _processMoveDelta(Offset delta) {
    if (!mounted) {
      return;
    }
    lastPointerDelta = delta;
    threeJs.domElement.overrideEmit(three.PeripheralType.pointerHover,three.WebPointerEvent()..movementX = lastPointerDelta.dx ..movementY = lastPointerDelta.dy);
  }
}
