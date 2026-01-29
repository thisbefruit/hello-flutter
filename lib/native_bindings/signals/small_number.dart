// ignore_for_file: type=lint, type=warning
part of 'signals.dart';

/// To send data from Rust to Dart, use `RustSignal`.
@immutable
class SmallNumber {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _smallNumberStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<SmallNumber>? latestRustSignal = null;

  const SmallNumber({
    required this.number,
  });

  static SmallNumber deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = SmallNumber(
      number: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static SmallNumber bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SmallNumber.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int number;

  SmallNumber copyWith({
    int? number,
  }) {
    return SmallNumber(
      number: number ?? this.number,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt32(number);
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

    return other is SmallNumber
      && number == other.number;
  }

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'number: $number'
        ')';
      return true;
    }());

    return fullString ?? 'SmallNumber';
  }
}

final _smallNumberStreamController =
    StreamController<RustSignalPack<SmallNumber>>();
