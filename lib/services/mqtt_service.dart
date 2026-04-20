import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  static const _host =
      '654dcb2e2b224e16af4fe695597c1b42.s1.eu.hivemq.cloud';
  static const _port = 8883;
  static const _user = 'esp32_user';
  static const _pass = 'Esp32_user';

  MqttServerClient? _client;
  StreamSubscription? _rideSub;

  Future<void> connect() async {
    final id = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_host, id, _port);
    _client!.secure = true;
    _client!.onBadCertificate = (_) => true;
    _client!.keepAlivePeriod = 60;
    _client!.logging(on: false);
    _client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(id)
        .authenticateAs(_user, _pass)
        .startClean();
    await _client!.connect();
  }

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Publish OTP to the lock so ESP32 can receive it on the keypad.
  void publishOtp(String lockNumber, String otp) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(otp);
    _client!.publishMessage(
      'lock/$lockNumber/otp',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  /// Subscribe to lock/{lockNumber}/data.
  /// When ESP32 sends ride duration (ms), write rideDurationSeconds
  /// to Firestore so ActiveRideScreen's existing listener handles it.
  void listenForRideEnd(String lockNumber, String rideId) {
    if (!isConnected) return;
    _client!.subscribe('lock/$lockNumber/data', MqttQos.atLeastOnce);
    _rideSub = _client!.updates?.listen((messages) {
      for (final msg in messages) {
        if (msg.topic != 'lock/$lockNumber/data') continue;
        final raw = MqttPublishPayload.bytesToStringAsString(
            (msg.payload as MqttPublishMessage).payload.message);
        final ms = int.tryParse(raw.trim()) ?? 0;
        final secs = (ms / 1000).round();
        FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .update({'rideDurationSeconds': secs});
        _rideSub?.cancel();
      }
    });
  }

  void disconnect() {
    _rideSub?.cancel();
    _client?.disconnect();
    _client = null;
  }
}
