import 'dart:async';
import 'package:examples/showcase/dive/core/world.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_lock/pointer_lock.dart';
import 'package:three_js/three_js.dart' as three;

class Dive extends StatefulWidget {
  const Dive({super.key});
  @override
  createState() => _State();
}

class _State extends State<Dive> {
  late three.ThreeJS threeJs;
  late final World world;

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
      settings: three.Settings(
        autoClear: false,
        enableShadowMap: true
      )
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
            world.unlockControls();
          },
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          child:Scaffold(
            body: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [
                threeJs.build(),
                if(threeJs.mounted)Positioned(
                  top: 20,
                  right: 20,
                  child: SizedBox(
                    height: threeJs.height,
                    width: 240,
                    child: world.uiManager.datGui.render(context)
                  )
                ),
                
              ]+(!threeJs.mounted?[]:world.uiManager.render()),
            ) 
          )
        )
      )
    );
  }

  bool stateChange = true;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 1000 );
    threeJs.scene = three.Scene();
    world = World(threeJs,context);
    await world.init();
    world.startLoc = _startSession;
    world.removeLoc = _stopSession;
    threeJs.addAnimationEvent((dt){
      world.animate(dt);
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
