# NFC Manager Transport for Coinkite Tap Protocol

An implementation of [cktap_transport](https://github.com/PeteClubSeven/cktap-transport) using the [nfc_manager](https://github.com/okadan/flutter-nfc-manager) plugin. This is currently designed for NFC Manager v3, when v4 is released this plugin will be reworked to support the new API.

## Platform Support

- [x] Android
  - Please use the `bugfix/timeout-issues` branch or some devices may fail when performing the `CKTapCard.wait` command
- [ ] iOS

## Getting Started

```yaml
dependencies:
  # This transport plugin is designed to be used specifically for the cktap_protocol plugin
  cktap_protocol: ^0.0.1
  
  # The recommended way to use this plugin, we use a fork of nfc_manager which supports setting the timeout value for 
  # IsoDep tags. Unfortunately the required function is missing in the official nfc_manager codebase
  cktap_transport_nfc_manager:
    git:
      url: https://github.com/PeteClubSeven/cktap-transport-nfc-manager.git
      ref: bugfix/timeout-issues

  # Uses an unmodified version of nfc_manager v3
  cktap_transport_nfc_manager: ^0.0.1
```

## Usage

```dart
import 'package:cktap_protocol/cktap_protocol.dart';
import 'package:cktap_protocol/cktapcard.dart';
import 'package:cktap_protocol/satscard.dart';
import 'package:cktap_protocol/tapsigner.dart';
import 'package:cktap_transport_nfc_manager/cktap_transport_nfc_manager.dart';
import 'package:nfc_manager/nfc_manager.dart';

void exampleFunction() {
  NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // Create the transport from the given tag
        NfcManagerTransport transport = NfcManagerTransport(tag);
        // Attempt to read the card, exceptions are thrown when errors occur
        CKTapCard card = await CKTapProtocol.readCard(transport);
        
        // Cast to the correct card type and reuse the transport during the same NFC session
        if (card.isTapsigner) {
          Tapsigner tapsigner = card.toTapsigner();
          var result = await tapsigner.wait(transport);
        } else {
          Satscard satscard = card.toSatscard();
          var slots = await satscard.listSlots(transport);
        }
    },
  );
}
```

## Additional Information

See the [cktap_protocol](https://github.com/PeteClubSeven/cktap-protocol-flutter) plugin for more information of how this transport plugin can be used.