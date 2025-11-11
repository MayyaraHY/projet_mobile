import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

Widget buildInsuranceLogo(
  String source, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (source.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
  final isNetwork = source.startsWith('http://') || source.startsWith('https://');
  final isDataUrl = source.startsWith('data:image');
  if (isDataUrl) {
    try {
      final base64Part = source.split(',').last;
      final bytes = base64Decode(base64Part);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    } catch (_) {
      // fall through to placeholder below
    }
  }
  if (isNetwork) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }
  return Image.file(
    File(source),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    ),
  );
}
