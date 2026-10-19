import 'dart:io';
import 'package:flutter/material.dart';

/// Resolves a song's image reference to the right [ImageProvider]:
/// network URLs (imported songs), local files, or bundled assets.
ImageProvider songImageProvider(String image) {
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return NetworkImage(image);
  }
  if (image.startsWith('/')) {
    return FileImage(File(image));
  }
  return AssetImage(image);
}
