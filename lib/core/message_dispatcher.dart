import "console_logger/console_platform.dart";
import "game_entity.dart";
import "telegram.dart";

/// This class is the core of the messaging system for game entities and used by the
/// { @link EntityManager}. The implementation can directly dispatch messages or use a
/// delayed delivery for deferred communication. This can be useful if a game entity
/// wants to inform itself about a particular event in the future.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MessageDispatcher {
  List<Telegram> delayedTelegrams = [];

	/// Delivers the message to the receiver.
	MessageDispatcher deliver(Telegram telegram ) {
		final receiver = telegram.receiver;

		if ( receiver.handleMessage( telegram ) == false ) {
			yukaConsole.warning( 'YUKA.MessageDispatcher: Message not handled by receiver: $receiver');
		}

		return this;
	}

	/// Receives the raw telegram data and decides how to dispatch the telegram (with or without delay).
	MessageDispatcher dispatch(GameEntity sender, GameEntity receiver, String message, double delay, [Map<String,dynamic>? data ]) {
		final telegram = Telegram( sender, receiver, message, delay, data );

		if ( delay <= 0 ) {
			deliver( telegram );
		} 
    else {
			delayedTelegrams.add( telegram );
		}

		return this;
	}

	/// Used to process delayed messages.
	MessageDispatcher dispatchDelayedMessages(double delta ) {
		int i = delayedTelegrams.length;

		while ( i-- > 0 ) {
			final telegram = delayedTelegrams[ i ];
			telegram.delay -= delta;

			if ( telegram.delay <= 0 ) {
				deliver( telegram );
				delayedTelegrams.removeLast();
			}
		}

		return this;
	}

	/// Clears the internal state of this message dispatcher.
	MessageDispatcher clear() {
		delayedTelegrams.length = 0;
		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {

		final Map<String,dynamic> data = {
			'type': runtimeType.toString(),
			'delayedTelegrams': []
		};

		// delayed telegrams
		for ( int i = 0, l = delayedTelegrams.length; i < l; i ++ ) {
			final delayedTelegram = delayedTelegrams[ i ];
			data['delayedTelegrams'].add( delayedTelegram.toJSON() );
		}

		return data;
	}

	/// Restores this instance from the given JSON object.
	MessageDispatcher fromJSON(Map<String,dynamic> json ) {
		clear();
		final telegramsJSON = json['delayedTelegrams'];

		for ( int i = 0, l = telegramsJSON.length; i < l; i ++ ) {
			final telegramJSON = telegramsJSON[ i ];
			final telegram = Telegram.fromJson( telegramJSON );

			delayedTelegrams.add( telegram );
		}

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	MessageDispatcher resolveReferences(Map<String,GameEntity> entities ) {
		final delayedTelegrams = this.delayedTelegrams;

		for ( int i = 0, l = delayedTelegrams.length; i < l; i ++ ) {
			final delayedTelegram = delayedTelegrams[ i ];
			delayedTelegram.resolveReferences( entities );
		}

		return this;
	}
}
