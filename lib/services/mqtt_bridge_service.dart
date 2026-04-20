import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class MqttBridgeService {
  MqttBridgeService._();
  static final MqttBridgeService instance = MqttBridgeService._();

  final ApiService _api = ApiService();
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  bool _started = false;

  Future<void> start() async {
    if (_started || !AppConfig.mqttEnabled) return;

    final clientId =
        '${AppConfig.mqttClientId}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final client = MqttServerClient.withPort(
      AppConfig.mqttHost,
      clientId,
      AppConfig.mqttPort,
    );

    client.logging(on: false);
    client.keepAlivePeriod = AppConfig.mqttKeepAliveSeconds;
    client.autoReconnect = true;
    client.onConnected = () => debugPrint('[MQTT] Connected');
    client.onDisconnected = () => debugPrint('[MQTT] Disconnected');
    client.onSubscribed = (topic) => debugPrint('[MQTT] Subscribed: $topic');
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      if (AppConfig.mqttUsername.isNotEmpty) {
        await client.connect(AppConfig.mqttUsername, AppConfig.mqttPassword);
      } else {
        await client.connect();
      }
    } catch (e) {
      debugPrint('[MQTT] Connect failed: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint(
          '[MQTT] Connection state: ${client.connectionStatus?.state} - ${client.connectionStatus}');
      client.disconnect();
      return;
    }

    _client = client;
    _started = true;

    final telemetryTopic = '${AppConfig.mqttTopicPrefix}/+/telemetry';
    final statusTopic = '${AppConfig.mqttTopicPrefix}/+/status';
    final rideTopic = '${AppConfig.mqttTopicPrefix}/+/ride';

    client.subscribe(telemetryTopic, MqttQos.atLeastOnce);
    client.subscribe(statusTopic, MqttQos.atLeastOnce);
    client.subscribe(rideTopic, MqttQos.atLeastOnce);

    _updatesSub = client.updates?.listen(_handleMessages);
  }

  Future<void> stop() async {
    await _updatesSub?.cancel();
    _updatesSub = null;
    _client?.disconnect();
    _client = null;
    _started = false;
  }

  void _handleMessages(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final topic = event.topic;
      final payloadMessage = event.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        payloadMessage.payload.message,
      );
      _processMessage(topic: topic, payloadRaw: payload);
    }
  }

  Future<void> _processMessage({
    required String topic,
    required String payloadRaw,
  }) async {
    final bikeId = _extractBikeId(topic);
    if (bikeId == null || bikeId.isEmpty) {
      debugPrint('[MQTT] Could not parse bikeId from topic: $topic');
      return;
    }

    Map<String, dynamic> payload;
    try {
      final dynamic parsed = jsonDecode(payloadRaw);
      if (parsed is! Map<String, dynamic>) {
        debugPrint('[MQTT] Payload is not object JSON: $payloadRaw');
        return;
      }
      payload = parsed;
    } catch (_) {
      // Keep compatibility for plain text lock status messages.
      payload = {'lockStatus': payloadRaw};
    }

    try {
      await _api.ingestHardwarePayload(
        bikeId: bikeId,
        topic: topic,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[MQTT] Failed to ingest payload for $bikeId: $e');
    }
  }

  String? _extractBikeId(String topic) {
    final parts = topic.split('/');
    final prefixParts = AppConfig.mqttTopicPrefix.split('/');
    if (parts.length < prefixParts.length + 2) return null;

    // For prefix "campus-bike/hardware", bikeId is next part:
    // "campus-bike/hardware/{bikeId}/telemetry"
    return parts[prefixParts.length];
  }
}

