import 'package:examples/playground/hideseek/world.dart';
import 'package:examples/playground/hideseek/hide_behavior.dart';
import 'package:yuka/yuka.dart';

class Enemy extends Vehicle {
  double deathAnimDuration = 0.5;
  double currentTime = 0;
  bool dead = false;
  bool notifiedWorld = false;
  Vector3? spawningPoint;
  MeshGeometry geometry;
  HideSeekWorld world;
  
	Enemy( this.geometry, this.world ):super() {
		maxSpeed = 5;
	}

  @override
	GameEntity start() {
		final MovingEntity player = manager?.getEntityByName( 'player' ) as MovingEntity;
		final hideBehavior = HideBehavior( manager!, player );

		steering.add( hideBehavior );
		return this;
	}

  @override
	Vehicle update(double delta ) {
		super.update( delta );

		if ( dead ) {
			if ( notifiedWorld == false ) {
				notifiedWorld = true;
				world.hits ++;
				world.updateUI();
			}

			currentTime += delta;

			if ( currentTime <= deathAnimDuration ) {
				final value = currentTime / deathAnimDuration;
				final shader = renderComponent.material.userData['shader'];

				shader.uniforms['alpha']['value'] = ( value <= 1 ) ? value : 1.0;
				renderComponent.material.opacity = 1.0 - shader.uniforms['alpha']['value'];
			} 
      else {
				world.remove( this );
			}
		}

		return this;
	}

  @override
	bool handleMessage(Telegram telegram) {
		dead = true;
		renderComponent.castShadow = false;
		return true;
	}
}