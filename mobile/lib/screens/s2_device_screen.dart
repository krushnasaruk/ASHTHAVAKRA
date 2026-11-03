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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Connection Mode Selector (Preserves 'CONNECTION SOURCE' and 'Simulator (Localhost)')
          const Text(
            'CONNECTION SOURCE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFF7A837E)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Simulator (Localhost)'),
                  selected: dev.mode == ConnectionMode.simulator,
                  selectedColor: const Color(0xFFC8F05F),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: dev.mode == ConnectionMode.simulator ? const Color(0xFF121715) : const Color(0xFF7A837E),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      dev.setMode(ConnectionMode.simulator);
                      _ipController.text = dev.host;
                      _portController.text = dev.port.toString();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('ESP32 Glove (Wi-Fi)'),
                  selected: dev.mode == ConnectionMode.esp32,
                  selectedColor: const Color(0xFFC8F05F),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: dev.mode == ConnectionMode.esp32 ? const Color(0xFF121715) : const Color(0xFF7A837E),
                  ),
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
          const SizedBox(height: 16),

          // 2. IP & Port Entry Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Device Socket Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dev.state == DeviceConnectionState.streaming ? const Color(0xFFC8F05F) : const Color(0xFF1E2822),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dev.state.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: dev.state == DeviceConnectionState.streaming ? const Color(0xFF121715) : const Color(0xFF8E958E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ipController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'IP / Host',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E958E)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF222B26)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFC8F05F)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Port',
                          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E958E)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF222B26)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFC8F05F)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dev.lastValidationError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B1212),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dev.lastValidationError!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B6B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? const Color(0xFFDC2626) : const Color(0xFFC8F05F),
                      foregroundColor: isConnected ? Colors.white : const Color(0xFF0B0F0E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (isConnected) {
                        dev.disconnect();
                      } else {
                        final portVal = int.tryParse(_portController.text.trim()) ?? 8000;
                        dev.validateAndConnect(_ipController.text, portVal);
                      }
                    },
                    child: Text(
                      isConnected ? 'Disconnect Device' : 'Connect & Validate Stream',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Live Diagnostics Panel (Obsidian Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LIVE DIAGNOSTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFFC8F05F))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2822),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ESP32-S3 N16R8', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _diagRow('Controller', dev.controllerModel),
                _diagRow('Hardware Profile', '${dev.hardwareProfile.toUpperCase()} (${dev.hardwareProfile == "demo3" ? "3-Flex + FSR + IMU" : "5-Flex + FSR + IMU"})'),
                _diagRow('ADC Subsystem', dev.adcModel),
                _diagRow('IMU Subsystem', dev.imuModel),
                _diagRow('Serial Baud Rate', '${dev.baudRate} baud'),
                _diagRow('Power Source', dev.batteryStatus),
                _diagRow('Stream Rate', '${dev.currentPacketRateHz} Hz (Target: 25 Hz)'),
                _diagRow('Total Packets', '${dev.decoder.diagnostics.totalPacketsDecoded}'),
                _diagRow('Decode Errors', '${dev.decoder.diagnostics.decodeErrors}'),
                _diagRow('Gaps Detected', '${dev.decoder.diagnostics.gapsDetected}'),
                _diagRow('Last Packet Age', '${dev.lastPacketAgeMs} ms'),
                _diagRow('Data Source', dev.isSimulated ? 'SIMULATOR / REPLAY' : 'REAL ESP32-S3 GLOVE'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Hardware Controls (Haptics & Calibration)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141A17),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF222B26), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HARDWARE CONTROLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFF8E958E))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.vibration, size: 18),
                        label: Text(_isTestingHaptic ? 'Pulsing...' : 'Test Haptic', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF222B26), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(0, 44),
                        ),
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
                        icon: const Icon(Icons.tune, size: 18, color: Color(0xFF0B0F0E)),
                        label: const Text('Calibration Wizard', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B0F0E))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC8F05F),
                          foregroundColor: const Color(0xFF0B0F0E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(0, 44),
                          elevation: 0,
                        ),
                        onPressed: widget.onOpenCalibration,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFA0AAB0)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
