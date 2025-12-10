import 'dart:math' as math;
import 'package:examples/playground/shooter/player.dart';
import 'package:examples/playground/shooter/world.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:yuka/yuka.dart';

class YukaFirstPersonControls extends EventDispatcher {
  final PI05 = math.pi / 2;
  final direction = Vector3();
  final velocity = Vector3();

  double currentSign = 1;
  double elapsedTime = 0;

  Map<String,bool> input = {
    'forward': false,
    'backward': false,
    'right': false,
    'left': false
  };


  double movementX = 0; // mouse left/right
  double movementY = 0; // mouse up/down

  double acceleration = 100;
  double brakingPower = 10;
  double lookingSpeed = 1;
  double headMovement = 0.75;

  Player owner;
  final World world;
  late final three.ThreeJS threeJs;

	YukaFirstPersonControls(this.owner,this.world ):super(){
    threeJs = world.threeJs!;
  }

	connect() {
		threeJs.domElement.addEventListener( three.PeripheralType.pointerdown, onMouseDown, false );
		threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onMouseMove, false );
		//threeJs.domElement.addEventListener( 'pointerlockchange',onPointerlockChange, false );
		//threeJs.domElement.addEventListener( 'pointerlockerror', onPointerlockError, false );
		threeJs.domElement.addEventListener( three.PeripheralType.keydown, onKeyDown, false );
		threeJs.domElement.addEventListener( three.PeripheralType.keyup, onKeyUp, false );

		//threeJs.domElement.body.requestPointerLock();
	}

	disconnect() {
		threeJs.domElement.removeEventListener( three.PeripheralType.pointerdown, onMouseDown, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.pointerHover, onMouseMove, false );
		//threeJs.domElement.removeEventListener( 'pointerlockchange', onPointerlockChange, false );
		//threeJs.domElement.removeEventListener( 'pointerlockerror', onPointerlockError, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.keydown, onKeyDown, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.keyup, onKeyUp, false );
	}

  double _getNumber(bool e){
    return e?1:0;
  } 

	update( delta ) {
		final input = this.input;
		final owner = this.owner;

		velocity.x -= velocity.x * brakingPower * delta;
		velocity.z -= velocity.z * brakingPower * delta;

		direction.z = _getNumber( input['forward']! ) - _getNumber( input['backward']! );
		direction.x = _getNumber( input['left']! ) - _getNumber( input['right']! );
		direction.normalize();

		if ( input['forward']! || input['backward']! ) velocity.z -= direction.z * acceleration * delta;
		if ( input['left']! || input['right']! ) velocity.x -= direction.x * acceleration * delta;

		owner.velocity.copy( velocity ).applyRotation( owner.rotation );

		//

		final speed = owner.getSpeed();
		elapsedTime += delta * speed; // scale delta with movement speed

		final motion = math.sin( elapsedTime * headMovement );

		_updateHead( motion );
		_updateWeapon( motion );
	}

	setRotation( yaw, pitch ) {
		movementX = yaw;
		movementY = pitch;

		owner.rotation.fromEuler( 0, movementX, 0 );
		owner.head.rotation.fromEuler( movementY, 0, 0 );
	}

	_updateHead( motion ) {
		final owner = this.owner;
		final headContainer = owner.headContainer;

		// some simple head bobbing
		headContainer.position.x = motion * 0.14;
		headContainer.position.y = motion.abs() * 0.12;

		//
		final sign = math.cos( elapsedTime * headMovement ).sign;

		if ( sign < currentSign ) {
			currentSign = sign;
		}

		if ( sign > currentSign ) {
			currentSign = sign;
		}
	}

	_updateWeapon( motion ) {
		final owner = this.owner;
		final weaponContainer = owner.weaponContainer;

		weaponContainer.position.x = motion * 0.005;
		weaponContainer.position.y = motion.abs() * 0.002;
	}

  onMouseDown( event ) {
    if ( event.button == 0 ) {
      owner.weapon.shoot();
    }
  }

  onMouseMove( event ) {
    movementX -= event.movementX * 0.001 * lookingSpeed;
    movementY -= event.movementY * 0.001 * lookingSpeed;
    movementY = math.max( - PI05, math.min( PI05, movementY ) );
    owner.rotation.fromEuler( 0.0, movementX*1.0, 0.0 ); // yaw
    owner.head.rotation.fromEuler( movementY*1.0, 0.0, 0.0 ); // pitch
  }

  onPointerlockChange() {
    // if ( document.pointerLockElement == document.body ) {
    //   dispatchEvent( { 'type': 'lock' } );
    // } 
    // else {
    //   disconnect();
    //   dispatchEvent( { 'type': 'unlock' } );
    // }
  }

  onPointerlockError() {
    yukaConsole.warning( 'YUKA.Player: Unable to use Pointer Lock API.' );
  }

  onKeyDown( event ) {
    switch ( event.keyId ) {
      case 4294968068:
      case 119: // up
        input['forward'] = true;
        break;
      case 4294968066:
      case 97: // left
        input['left'] = true;
        break;
      case 4294968065:
      case 115: // down
        input['backward'] = true;
        break;
      case 4294968067:
      case 100: // right
        input['right'] = true;
        break;
      case 114: // r
        owner.weapon.reload();
        break;
    }
  }

  onKeyUp( event ) {
    switch ( event.keyId ) {
      case 4294968068:
      case 119: // up
        input['forward'] = false;
        break;
      case 4294968066:
      case 97: // left
        input['left'] = false;
        break;
      case 4294968065:
      case 115: // down
        input['backward'] = false;
        break;
      case 4294968067:
      case 100: // right
        input['right'] = false;
        break;
    }
  }
}