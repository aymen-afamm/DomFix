import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// Service for uploading files to Firebase Storage
class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload audio file to Firebase Storage
  /// Returns download URL
  Future<String> uploadAudio({
    required String chatId,
    required File audioFile,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
      final ref = _storage.ref().child('chats/$chatId/audio/$fileName');
      
      debugPrint('[Storage] Uploading audio: $fileName');
      
      final uploadTask = ref.putFile(audioFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('[Storage] Audio uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[Storage] Error uploading audio: $e');
      rethrow;
    }
  }

  /// Upload image file to Firebase Storage with compression
  /// Returns download URL
  Future<String> uploadImage({
    required String chatId,
    required File imageFile,
    bool compress = true,
  }) async {
    try {
      File fileToUpload = imageFile;
      
      // Compress image before upload
      if (compress) {
        debugPrint('[Storage] Compressing image...');
        final compressedFile = await _compressImage(imageFile);
        if (compressedFile != null) {
          fileToUpload = compressedFile;
          debugPrint('[Storage] Image compressed');
        }
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final ref = _storage.ref().child('chats/$chatId/images/$fileName');
      
      debugPrint('[Storage] Uploading image: $fileName');
      
      final uploadTask = ref.putFile(fileToUpload);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('[Storage] Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[Storage] Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload file to Firebase Storage
  /// Returns download URL
  Future<String> uploadFile({
    required String chatId,
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('chats/$chatId/files/$fileName');
      
      debugPrint('[Storage] Uploading file: $fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('[Storage] File uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[Storage] Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload with progress tracking
  Stream<double> uploadWithProgress({
    required String chatId,
    required File file,
    required String type, // 'audio', 'image', 'file'
    String? fileName,
  }) {
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final ref = _storage.ref().child('chats/$chatId/$type/$name');
    
    final uploadTask = ref.putFile(file);
    
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  /// Compress image to reduce file size
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed${filePath.substring(lastIndex)}';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('[Storage] Error compressing image: $e');
      return null;
    }
  }
}
