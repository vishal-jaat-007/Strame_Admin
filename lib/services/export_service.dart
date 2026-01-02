import 'dart:convert';
import 'package:csv/csv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:intl/intl.dart';

class ExportService {
  /// Exports platform data to a CSV file and triggers a browser download.
  static void exportToCsv({
    required Map<String, dynamic> summaryStats,
    required List<List<dynamic>> transactionData,
    required List<List<dynamic>> creatorData,
  }) {
    List<List<dynamic>> rows = [];

    // --- PLATFORM SUMMARY ---
    rows.add(['--- PLATFORM PERFORMANCE SUMMARY ---']);
    rows.add(['Metric', 'Value', 'Generated At']);
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    rows.add([
      'Total Revenue',
      '₹${summaryStats['totalRevenue'].toStringAsFixed(2)}',
      now,
    ]);
    rows.add([
      'Daily Revenue',
      '₹${summaryStats['todayRevenue'].toStringAsFixed(2)}',
      '',
    ]);
    rows.add(['Active Creators', summaryStats['totalCreators'], '']);
    rows.add(['Platform Users', summaryStats['totalUsers'], '']);
    rows.add(['Total Interactions', summaryStats['totalCalls'], '']);
    rows.add(['Pending Payouts', summaryStats['pendingWithdrawals'], '']);
    rows.add([]); // Spacing

    // --- CREATOR DATA ---
    rows.add(['--- ACCREDITED CREATORS ---']);
    rows.add(['Name/ID', 'Status', 'Revenue Contribution (Est.)']);
    for (var creator in creatorData) {
      rows.add(creator);
    }
    rows.add([]); // Spacing

    // --- TRANSACTION LOGS ---
    rows.add(['--- RECENT TRANSACTION LOGS ---']);
    rows.add([
      'Date',
      'Type',
      'Amount (Coins)',
      'Value (INR)',
      'Status',
      'Description',
    ]);
    for (var tx in transactionData) {
      rows.add(tx);
    }

    // Convert to CSV
    String csvData = const ListToCsvConverter().convert(rows);

    // Trigger Download
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..setAttribute(
        'download',
        'Strame_Platform_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
