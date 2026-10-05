import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/printer_provider.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────
const _bgDark      = Color(0xFF09090B);
const _surfaceDark = Color(0xFF141417);
const _cardDark    = Color(0xFF18181B);
const _borderDark  = Color(0xFF27272A);
const _borderSubtle= Color(0xFF1F1F23);
const _textMuted   = Color(0xFF71717A);
const _textSub     = Color(0xFFA1A1AA);
const _textMain    = Color(0xFFFAFAFA);
const _stockGreen  = Color(0xFF22C55E);
const _stockRed    = Color(0xFFEF4444);
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _font(double size, FontWeight weight, Color color, {double letterSpacing = 0}) =>
    GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrinterProvider>().getDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Consumer<PrinterProvider>(
          builder: (context, printer, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(printer),
                _buildStatusCard(printer),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Perangkat Sekitar',
                        style: _font(12, FontWeight.w600, _textMain),
                      ),
                      const Spacer(),
                      if (printer.isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: printer.devices.isEmpty && !printer.isLoading
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: printer.devices.length,
                          itemBuilder: (context, index) {
                            return _buildDeviceTile(
                              printer.devices[index],
                              printer,
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        printer.getDevices();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textMain,
                        foregroundColor: _bgDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Pindai Ulang',
                            style: _font(13, FontWeight.w700, _bgDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header (konsisten dengan halaman lain) ─────────────────────────────────
  Widget _buildHeader(PrinterProvider printer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textSub,
              size: 18,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: printer.isConnected ? _stockGreen : _textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Printer Bluetooth',
                      style: _font(
                        15,
                        FontWeight.w700,
                        _textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    printer.isConnected
                        ? 'Terhubung & siap mencetak'
                        : 'Hubungkan printer untuk cetak struk',
                    style: _font(10, FontWeight.w500, _textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Connection Status Card ─────────────────────────────────────────────────
  Widget _buildStatusCard(PrinterProvider printer) {
    final isConnected = printer.isConnected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? _stockGreen.withValues(alpha: 0.35)
                : _borderDark,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isConnected
                    ? _stockGreen.withValues(alpha: 0.12)
                    : _cardDark,
                borderRadius: BorderRadius.circular(10),
                border: isConnected
                    ? null
                    : Border.all(color: _borderSubtle),
              ),
              child: Icon(
                isConnected
                    ? Icons.print_rounded
                    : Icons.print_disabled_outlined,
                color: isConnected ? _stockGreen : _textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Terhubung' : 'Belum Terhubung',
                    style: _font(
                      13,
                      FontWeight.w700,
                      isConnected ? _stockGreen : _textMain,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected
                        ? (printer.connectedDevice?.name ?? 'Unknown Device')
                        : 'Belum ada printer aktif',
                    style: _font(10.5, FontWeight.w500, _textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isConnected)
              SizedBox(
                height: 32,
                child: Material(
                  color: _stockRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      printer.disconnect();
                    },
                    splashColor: _stockRed.withValues(alpha: 0.12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Text(
                        'Putuskan',
                        style: _font(11, FontWeight.w600, _stockRed),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: _borderSubtle),
            ),
            child: const Icon(
              Icons.bluetooth_searching_rounded,
              size: 24,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tidak ada perangkat ditemukan',
            style: _font(13, FontWeight.w600, _textMain),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Pastikan bluetooth & mode pairing printer dinyalakan',
              textAlign: TextAlign.center,
              style: _font(11, FontWeight.w400, _textSub),
            ),
          ),
        ],
      ),
    );
  }

  // ── Device Tile ────────────────────────────────────────────────────────────
  Widget _buildDeviceTile(BluetoothDevice device, PrinterProvider printer) {
    final isConnected = printer.connectedDevice?.address == device.address;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected
                ? _stockGreen.withValues(alpha: 0.35)
                : _borderDark,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              printer.connect(device);
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: _textMain.withValues(alpha: 0.04),
            highlightColor: _textMain.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? _stockGreen.withValues(alpha: 0.12)
                          : _cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: isConnected
                          ? null
                          : Border.all(color: _borderSubtle),
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: isConnected ? _stockGreen : _textMuted,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name ?? 'Unknown Device',
                          style: _font(
                            12.5,
                            FontWeight.w600,
                            _textMain,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.address ?? 'MAC Address Hidden',
                          style: _font(10, FontWeight.w500, _textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? _stockGreen.withValues(alpha: 0.14)
                          : _borderSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnected) ...[
                          const Icon(
                            Icons.check_rounded,
                            color: _stockGreen,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          isConnected ? 'Aktif' : 'Hubungkan',
                          style: _font(
                            9.5,
                            FontWeight.w600,
                            isConnected ? _stockGreen : _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
