import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_constants.dart';
import '../../services/print_service.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<BluetoothInfo> _devices = [];
  bool _isScanning = false;
  bool _isBluetoothOn = true;
  bool _showPrinterList = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    _scanDevices();
  }

  Future<void> _checkBluetoothStatus() async {
    final isOn = await PrintService.instance.isBluetoothEnabled;
    if (mounted) setState(() => _isBluetoothOn = isOn);
  }

  Future<void> _scanDevices() async {
    await _checkBluetoothStatus();
    if (!_isBluetoothOn) {
      if (mounted) setState(() => _devices = []);
      return;
    }
    
    setState(() => _isScanning = true);
    try {
      _devices = await PrintService.instance.getDevices();
    } catch (_) {
      _devices = [];
    }
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connect(BluetoothInfo device) async {
    final success = await PrintService.instance.connect(device);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '✅ Terhubung ke ${device.name}'
              : '❌ Gagal terhubung ke ${device.name}'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await PrintService.instance.disconnect();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PENGATURAN', style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 24),

              // PRINTER SECTION
              _buildSectionHeader(Icons.print_rounded, 'Printer Bluetooth'),
              const SizedBox(height: 12),
              _buildBluetoothSetup(),
              
              const SizedBox(height: 32),

              // INFO SECTION
              _buildSectionHeader(Icons.info_outline_rounded, 'Tentang Aplikasi'),
              const SizedBox(height: 12),
              _buildAppInfo(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothSetup() {
    if (!_showPrinterList && !PrintService.instance.isConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(Icons.bluetooth_audio_rounded, color: AppColors.accent, size: 32),
            const SizedBox(height: 12),
            Text('Siapkan Printer', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Hubungkan printer untuk cetak struk.', 
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'HUBUNGKAN',
                icon: Icons.bluetooth_searching_rounded,
                height: 44,
                onPressed: () {
                  _checkBluetoothStatus();
                  setState(() => _showPrinterList = true);
                  _scanDevices();
                },
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!_isBluetoothOn) _buildBluetoothBanner(),
        if (_isBluetoothOn) ...[
          _buildPrinterStatus(),
          if (!PrintService.instance.isConnected) ...[
            const SizedBox(height: 8),
            _buildDeviceList(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _showPrinterList = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 14),
              label: Text('KEMBALI', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textHint,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBluetoothBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bluetooth Mati', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.error)),
                Text('Aktifkan Bluetooth untuk mengatur printer.', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: _scanDevices,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent)),
      ],
    );
  }

  Widget _buildPrinterStatus() {
    final isConnected = PrintService.instance.isConnected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : AppColors.textHint).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                  color: isConnected ? AppColors.success : AppColors.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isConnected ? 'Printer Terhubung' : 'Printer Terputus', 
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    if (isConnected)
                      Text(PrintService.instance.connectedDeviceName ?? 'Printer', style: AppTextStyles.caption)
                    else
                      Text('Belum ada perangkat yang aktif', style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: _disconnect,
                  child: Text('PUTUS', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                )
              else
                IconButton(
                  onPressed: _scanDevices,
                  icon: Icon(_isScanning ? Icons.sync : Icons.refresh_rounded, color: AppColors.accent, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_devices.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        ..._devices.map((device) {
          final isConnected = PrintService.instance.connectedDeviceName == device.name;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isConnected ? AppColors.accent : AppColors.divider),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(device.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(device.macAdress, style: AppTextStyles.caption),
              trailing: TextButton(
                onPressed: () => _connect(device),
                child: Text(isConnected ? 'TERHUBUNG' : 'HUBUNGKAN', 
                  style: AppTextStyles.caption.copyWith(
                    color: isConnected ? AppColors.success : AppColors.accent,
                    fontWeight: FontWeight.bold,
                  )),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          leading: const Icon(Icons.info_outline_rounded, color: AppColors.textHint, size: 20),
          title: Text('Info Aplikasi', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            _buildInfoRow('Nama', AppConstants.appName),
            const SizedBox(height: 12),
            _buildInfoRow('Versi', AppConstants.appVersion),
            const SizedBox(height: 12),
            _buildInfoRow('Vendor', AppConstants.developer),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
