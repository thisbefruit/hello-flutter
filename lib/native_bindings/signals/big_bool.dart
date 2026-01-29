// ignore_for_file: type=lint, type=warning
part of 'signals.dart';

/// A signal can be nested inside another signal.
@immutable
class BigBool {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _bigBoolStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<BigBool>? latestRustSignal = null;

  const BigBool({
    required this.member,
    required this.nested,
  });

  static BigBool deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = BigBool(
      member: deserializer.deserializeBool(),
      nested: SmallBool.deserialize(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static BigBool bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = BigBool.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final bool member;
  final SmallBool nested;

  BigBool copyWith({
    bool? member,
    SmallBool? nested,
  }) {
    return BigBool(
      member: member ?? this.member,
      nested: nested ?? this.nested,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeBool(member);
    nested.serialize(serializer);
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

    return other is BigBool
      && member == other.member
      && nested == other.nested;
  }

  @override
  int get hashCode => Object.hash(
        member,
        nested,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'member: $member, '
        'nested: $nested'
        ')';
      return true;
    }());

    return fullString ?? 'BigBool';
  }
}

final _bigBoolStreamController =
    StreamController<RustSignalPack<BigBool>>();
