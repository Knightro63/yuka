import 'game_entity.dart';
import '../constants.dart';

/// Class for representing a telegram, an envelope which contains a message
/// and certain metadata like sender and receiver. Part of the messaging system
/// for game entities.
class Telegram {
  late GameEntity sender;
  late GameEntity receiver;
  late String message;
  late double delay;
  Map<String,dynamic>? data;

	/// Constructs a new telegram object.
	Telegram(this.sender, this.receiver, this.message, this.delay, this.data );

  Telegram.fromJson(Map<String,dynamic> json ) {
		sender = json['sender'];
		receiver = json['receiver'];
		message = json['message'];
		delay = json['delay'];
		data = json['data'];
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': 'Telegram',
			'sender': sender.uuid,
			'receiver': receiver.uuid,
			'message': message,
			'delay': delay,
			'data': data
		};
	}

	/// Restores this instance from the given JSON object.
	Telegram fromJSON(Map<String,dynamic> json ) {
		sender = json['sender'];
		receiver = json['receiver'];
		message = json['message'];
		delay = json['delay'];
		data = json['data'];

		return this;
	}

	/// Restores UUIDs with references to GameEntity objects.
	Telegram resolveReferences(Map<String,GameEntity> entities ) {
		sender = entities.get(sender)!;
		receiver = entities.get(receiver)!;

		return this;
	}
}
