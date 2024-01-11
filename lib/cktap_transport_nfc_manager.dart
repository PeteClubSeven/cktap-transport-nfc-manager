import 'dart:io';
import 'dart:typed_data';

import 'package:cktap_transport/cktap_transport.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

/// Specifies the NFC specification used to communicate with a device
enum NfcProtocol {
  none,
  isoDep,
  iso7816,
}

/// An implementation of [Transport] using the nfc_manager package. Android/iOS
/// only. This may require a big rework for nfc_manager v4.0.0
class NfcManagerTransport implements Transport {
  /// Original tag used to construct the bridge
  final NfcTag _tag;

  /// Android uses IsoDep
  final IsoDep? _isoDep;

  /// iOS uses ISO7816
  final Iso7816? _iso7816;

  /// Internal constructor
  NfcManagerTransport._internal(this._tag, this._isoDep, this._iso7816);

  /// Constructs a valid bridge provided the given tag supports the correct
  /// formats, e.g. IsoDep on Android or ISO7816 on iOS
  factory NfcManagerTransport(NfcTag tag) {
    if (Platform.isAndroid) {
      var isoDep = IsoDep.from(tag);
      if (isoDep != null && isoDep.maxTransceiveLength > 0) {
        // Requires custom fork: https://github.com/PeteClubSeven/flutter-nfc-manager
        /*// Ensure we have a valid timeout value for CKTapCard::Wait()
        if (isoDep.initialTimeout < 2000) {
          isoDep.setTimeout(time: 2000);
        }*/
        return NfcManagerTransport._internal(tag, isoDep, null);
      }
    } else if (Platform.isIOS) {
      var iso7816 = Iso7816.from(tag);
      if (iso7816 != null) {
        return NfcManagerTransport._internal(tag, null, iso7816);
      }
    }

    throw NfcIncompatibilityException(tag);
  }

  /// Gets the type of communication used for the current platform
  NfcProtocol getCommunicationType() {
    if (_isoDep != null) {
      return NfcProtocol.isoDep;
    } else if (_iso7816 != null) {
      return NfcProtocol.iso7816;
    }
    return NfcProtocol.none;
  }

  /// Sends raw data to the NFC device (if still available). Returns the raw
  /// response as bytes
  @override
  Future<Uint8List> sendBytes(final Uint8List bytes) async {
    return Future.sync(() async {
      try {
        if (_isoDep != null) {
          return await _isoDep!.transceive(data: bytes);
        }
      } catch (e) {
        if (_isoDep != null && bytes.length > _isoDep!.maxTransceiveLength) {
          throw NfcTransceiveException(
              _tag, bytes.length, _isoDep!.maxTransceiveLength);
        }

        throw NfcCommunicationException(
            e.toString(), _tag, getCommunicationType());
      }

      throw UnsupportedError(
          "Attempt to send data to an NFC device on an unsupported platform");
    });
  }
}

/// Thrown when attempts to communicate via NFC fail
class NfcCommunicationException implements TransportException {
  final String message;
  final NfcTag tag;
  final NfcProtocol protocol;

  NfcCommunicationException(this.message, this.tag, this.protocol);

  @override
  String toString() =>
      "Failure to communicate via $protocol with the given tag (${tag.handle}): $message";
}

/// Thrown when a given NfcTag doesn't support the required protocols for the
/// platform. Currently only IsoDep on Android and ISO7816 on iOS are supported
class NfcIncompatibilityException implements TransportException {
  final NfcTag tag;

  NfcIncompatibilityException(this.tag);

  @override
  String toString() => "Given tag is incompatible with the CKTap plugin: $tag";
}

/// Thrown when trying to send more bytes to an NFC device than is supported by
/// the users device
class NfcTransceiveException implements TransportException {
  final NfcTag tag;
  final int bytesLength;
  final int maxLength;

  NfcTransceiveException(this.tag, this.bytesLength, this.maxLength);

  @override
  String toString() =>
      "Given tag can not transceive $bytesLength bytes, max length is $maxLength for tag: $tag";
}
