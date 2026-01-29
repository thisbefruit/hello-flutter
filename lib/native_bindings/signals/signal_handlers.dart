part of 'signals.dart';

final assignRustSignal = <String, void Function(Uint8List, Uint8List)>{
  'BigBool': (Uint8List messageBytes, Uint8List binary) {
    final message = BigBool.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _bigBoolStreamController.add(rustSignal);
    BigBool.latestRustSignal = rustSignal;
  },
  'SmallNumber': (Uint8List messageBytes, Uint8List binary) {
    final message = SmallNumber.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _smallNumberStreamController.add(rustSignal);
    SmallNumber.latestRustSignal = rustSignal;
  },
};
