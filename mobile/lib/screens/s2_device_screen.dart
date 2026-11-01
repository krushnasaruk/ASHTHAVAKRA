import 'package:flutter/material.dart';
import 'package:h10_core/h10_core.dart';
import '../services/device_service.dart';

class DeviceScreen extends StatefulWidget {
  final DeviceService deviceService;
  final VoidCallback onOpenCalibration;

  const DeviceScreen({
    super.key,
    required this.deviceService,
    required this.onOpenCalibration,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  bool _isTestingHaptic = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.deviceService.host);
    _portController = TextEditingController(text: widget.deviceService.port.toString());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.deviceService;
    final isConnected = dev.state == DeviceConnectionState.streaming;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(H10Tokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Connection Mode Selector
          const Text(
            'CONNECTION SOURCE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText)),
          ),
          const SizedBox(height: H10Tokens.space8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Simulator (Localhost)'),
                  selected: dev.mode == ConnectionMode.simulator,
                  onSelected: (selected) {
                    if (selected) {
                      dev.setMode(ConnectionMode.simulator);
                      _ipController.text = dev.host;
                      _portController.text = dev.port.toString();
                    }
                  },
                ),
              ),
              const SizedBox(width: H10Tokens.space8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('ESP32 Glove (Wi-Fi)'),
                  selected: dev.mode == ConnectionMode.esp32,
                  onSelected: (selected) {
                    if (selected) {
                      dev.setMode(ConnectionMode.esp32);
                      _ipController.text = dev.host;
                      _portController.text = dev.port.toString();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: H10Tokens.space16),

          // 2. IP & Port Entry
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: H10Tokens.space12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP / Host',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: H10Tokens.space12),
                  if (dev.lastValidationError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: H10Tokens.space12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(H10Tokens.colorError), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dev.lastValidationError!,
                              style: const TextStyle(fontSize: 12, color: Color(H10Tokens.colorError)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnected ? const Color(H10Tokens.colorError) : const Color(H10Tokens.colorPrimary),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (isConnected) {
                          dev.disconnect();
                        } else {
                          final portVal = int.tryParse(_portController.text.trim()) ?? 8000;
                          dev.validateAndConnect(_ipController.text, portVal);
                        }
                      },
                      child: Text(isConnected ? 'Disconnect' : 'Connect & Validate'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 3. Live Diagnostics Panel
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LIVE DIAGNOSTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: H10Tokens.space12),
                  _diagRow('Connection State', dev.state.name.toUpperCase()),
                  _diagRow('Stream Rate', '${dev.currentPacketRateHz} Hz'),
                  _diagRow('Total Packets', '${dev.decoder.diagnostics.totalPacketsDecoded}'),
                  _diagRow('Decode Errors', '${dev.decoder.diagnostics.decodeErrors}'),
                  _diagRow('Gaps Detected', '${dev.decoder.diagnostics.gapsDetected}'),
                  _diagRow('Last Packet Age', '${dev.lastPacketAgeMs} ms'),
                  _diagRow('Battery', '${dev.batteryPct}%'),
                  _diagRow('Simulated Badge', dev.isSimulated ? 'YES (Simulated)' : 'NO (Physical Glove)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: H10Tokens.space16),

          // 4. Hardware Controls (Haptics & Calibration)
          Card(
            color: const Color(H10Tokens.colorCard),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(H10Tokens.radiusCard),
              side: const BorderSide(color: Color(H10Tokens.colorBorder)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(H10Tokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HARDWARE CONTROLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(H10Tokens.colorSecondaryText))),
                  const SizedBox(height: H10Tokens.space12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.vibration),
                          label: Text(_isTestingHaptic ? 'Pulsing...' : 'Test Haptic'),
                          onPressed: isConnected && !_isTestingHaptic
                              ? () async {
                                  setState(() => _isTestingHaptic = true);
                                  await dev.sendHapticPulse();
                                  if (mounted) setState(() => _isTestingHaptic = false);
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.tune),
                          label: const Text('Calibration Wizard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(H10Tokens.colorPrimary),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: widget.onOpenCalibration,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(H10Tokens.colorSecondaryText))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

