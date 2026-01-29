// ignore_for_file: type=lint, type=warning
part of 'signals.dart';

/// To nest a signal inside other signal, use `SignalPiece`.
@immutable
class SmallBool {
  const SmallBool({
    required this.value,
  });

  static SmallBool deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = SmallBool(
      value: deserializer.deserializeBool(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static SmallBool bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SmallBool.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final bool value;

  SmallBool copyWith({
    bool? value,
  }) {
    return SmallBool(
      value: value ?? this.value,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeBool(value);
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

    return other is SmallBool
      && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'value: $value'
        ')';
      return true;
    }());

    return fullString ?? 'SmallBool';
  }
}
