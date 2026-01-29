// ignore_for_file: type=lint, type=warning
part of 'signals.dart';

/// To send data from Dart to Rust, use `DartSignal`.
@immutable
class SmallText {
  const SmallText({
    required this.text,
  });

  static SmallText deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = SmallText(
      text: deserializer.deserializeString(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static SmallText bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SmallText.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final String text;

  SmallText copyWith({
    String? text,
  }) {
    return SmallText(
      text: text ?? this.text,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeString(text);
    serializer.decreaseContainerDepth();
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is SmallText
      && text == other.text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'text: $text'
        ')';
      return true;
    }());

    return fullString ?? 'SmallText';
  }
}

extension SmallTextDartSignalExt on SmallText {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_small_text',
      messageBytes,
      binary,
    );
  }
}
