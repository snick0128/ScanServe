import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart' as model;
import 'dart:html' as html; // Only works for Web

class PrintingService {
  static final PrintingService _instance = PrintingService._internal();
  factory PrintingService() => _instance;
  PrintingService._internal();

  bool _isPrinterReady = true;
  DateTime? _lastFailureAt;
  String? _lastError;

  bool get isPrinterReady => _isPrinterReady;
  DateTime? get lastFailureAt => _lastFailureAt;
  String? get lastError => _lastError;

  /// Generates KOT HTML and triggers window.print()
  Future<bool> printKOT(model.Order order, {List<model.OrderItem>? itemsToPrint}) async {
    if (!kIsWeb) return false;

    try {
      final items = itemsToPrint ?? order.items;
      if (items.isEmpty) return true;

      final isAddon = items.any((i) => i.isAddon);
      final kotHtml = _generateKOTHtml(order, items, isAddon: isAddon);

      // Create a hidden iframe for printing
      final iframe = html.IFrameElement()
        ..style.display = 'none'
        ..srcdoc = kotHtml;
      
      html.document.body?.append(iframe);

      // Wait for content to load
      await Future.delayed(const Duration(milliseconds: 500));

      final printSuccess = _triggerBrowserPrint(iframe);
      
      if (printSuccess) {
        _isPrinterReady = true;
        _lastError = null;
      } else {
        _handleFailure('Print request ignored by browser or user.');
      }

      // Cleanup
      Future.delayed(const Duration(seconds: 5), () => iframe.remove());
      
      return printSuccess;
    } catch (e) {
      _handleFailure(e.toString());
      return false;
    }
  }

  bool _triggerBrowserPrint(html.IFrameElement iframe) {
    try {
      final window = iframe.contentWindow;
      if (window != null) {
        // Use js interop to call print
        final jsWindow = window as dynamic;
        jsWindow.print();
        return true; 
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _handleFailure(String error) {
    _isPrinterReady = false;
    _lastFailureAt = DateTime.now();
    _lastError = error;
    debugPrint('❌ Printing Service Failure: $error');
  }

  String _generateKOTHtml(model.Order order, List<model.OrderItem> items, {bool isAddon = false}) {
    final title = isAddon ? 'KOT: ADD-ON' : 'KOT: NEW ORDER';
    final dateStr = DateTime.now().toString().split('.')[0];
    
    String itemsHtml = '';
    for (var item in items) {
      itemsHtml += '''
        <tr>
          <td style="padding: 4px 0; font-size: 16px;"><strong>${item.quantity} x ${item.name}</strong>${item.variantName != null ? ' ($item.variantName)' : ''}</td>
        </tr>
        ${item.notes != null && item.notes!.isNotEmpty ? '<tr><td style="padding-bottom: 8px; font-size: 12px; font-style: italic;">Note: ${item.notes}</td></tr>' : ''}
      ''';
    }

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { 
            font-family: 'Courier New', Courier, monospace; 
            width: 80mm; 
            margin: 0; 
            padding: 10px;
          }
          .header { text-align: center; border-bottom: 2px dashed #000; padding-bottom: 10px; margin-bottom: 10px; }
          .title { font-size: 20px; font-weight: bold; margin: 5px 0; }
          .info { font-size: 14px; margin: 2px 0; }
          table { width: 100%; border-collapse: collapse; }
          .footer { border-top: 2px dashed #000; margin-top: 10px; padding-top: 10px; text-align: center; font-size: 12px; }
          @media print {
            @page { margin: 0; }
            body { margin: 0.5cm; }
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="title">$title</div>
          <div class="info">Table: ${order.tableName ?? 'Parcel'}</div>
          <div class="info">Order ID: #${order.id.substring(0, 8)}</div>
          <div class="info">Time: $dateStr</div>
        </div>
        <table>
          $itemsHtml
        </table>
        ${order.chefNote != null && order.chefNote!.isNotEmpty ? '<div style="margin-top: 10px; font-size: 14px; border: 1px solid #000; padding: 5px;"><strong>Chef Instruction:</strong><br/>${order.chefNote}</div>' : ''}
        <div class="footer">
          ScanServe KOT System
        </div>
      </body>
      </html>
    ''';
  }

  /// Manual health check
  Future<bool> checkPrinter() async {
    // Generate a test print
    final testOrder = model.Order(
      id: 'TEST-PRINTER',
      tenantId: 'system',
      items: [model.OrderItem(id: 'test', name: 'PRINTER TEST PAGE', price: 0, quantity: 1)],
      subtotal: 0,
      tax: 0,
      total: 0,
      status: model.OrderStatus.pending,
      createdAt: DateTime.now()
    );
    
    return await printKOT(testOrder);
  }
}
