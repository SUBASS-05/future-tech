import 'package:flutter/material.dart';

String formatDateTime(String? isoString) {
  if (isoString == null) return 'N/A';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month-1]} ${dt.day}, ${dt.year} ${hour}:${min} $ampm';
  } catch (_) {
    return isoString;
  }
}

String formatDate(String? isoString) {
  if (isoString == null) return 'N/A';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month-1]} ${dt.year}';
  } catch (_) {
    return isoString;
  }
}
