import 'package:flutter/material.dart';

class AppConfig {
  // ==== IDENTITAS BISNIS — GANTI TIAP KLIEN BARU ====
  static const String businessName = 'KasirKu';
  static const String receiptFooter = 'Terima kasih telah berkunjung!';

  // ==== BRANDING WARNA — BIRU PROFESIONAL ====
  static const Color primaryColor = Color(0xFF1565C0);      // Primary (blue-800)
  static const Color primaryLight = Color(0xFF1976D2);     // Light (blue-700)
  static const Color primaryDark = Color(0xFF0D47A1);     // Dark (blue-900)
  static const Color accentColor = Color(0xFF42A5F5);     // Accent (blue-400)
  static const Color backgroundColor = Color(0xFFF5F7FA);  // Background
  static const Color cardColor = Colors.white;
  static const Color secondaryColor = Color(0xFF37474F);    // Text secondary

  // ==== PAJAK & SERVICE CHARGE ====
  static const bool taxEnabled = true;
  static const double taxPercent = 10.0;
  static const bool serviceChargeEnabled = false;
  static const double serviceChargePercent = 5.0;

  // ==== FITUR OPSIONAL (ON/OFF PER KLIEN) ====
  static const bool tableManagementEnabled = true;
  static const bool printerEnabled = true;

  // ==== FORMAT MATA UANG ====
  static const String currencyLocale = 'id_ID';
  static const String currencySymbol = 'Rp ';
}
