import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class PreparedTransferFile {
  const PreparedTransferFile({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.sha256,
    required this.chunkSize,
    required this.chunkCount,
  });

  final String filePath;
  final String fileName;
  final int fileSize;
  final String sha256;
  final int chunkSize;
  final int chunkCount;
}

class TransferChunk {
  const TransferChunk({required this.index, required this.data});

  final int index;
  final List<int> data;
}

class IncomingTransferDraft {
  const IncomingTransferDraft({
    required this.transferId,
    required this.fileName,
    required this.tempDirectoryPath,
    required this.tempFilePath,
  });

  final String transferId;
  final String fileName;
  final String tempDirectoryPath;
  final String tempFilePath;
}

abstract interface class TransferFileService {
  Future<PreparedTransferFile> prepareOutgoingFile(
    String filePath, {
    required int chunkSize,
  });

  Stream<TransferChunk> readChunks(String filePath, {required int chunkSize});

  Future<List<int>> readChunkAt(
    String filePath, {
    required int chunkSize,
    required int chunkIndex,
  });

  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  });

  Future<void> appendChunk({
    required String tempFilePath,
    required List<int> bytes,
  });

  Future<String> computeSha256(String filePath);

  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  });

  Future<void> discardDraft(String tempFilePath);
}

class LocalTransferFileService implements TransferFileService {
  @override
  Future<PreparedTransferFile> prepareOutgoingFile(
    String filePath, {
    required int chunkSize,
  }) async {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty) {
      throw const AppException(
        code: 'transfer_path_required',
        message: '전송할 파일 경로를 입력해 주세요.',
      );
    }

    final file = File(normalizedPath);
    final exists = await file.exists();
    if (!exists) {
      throw AppException(
        code: 'transfer_file_missing',
        message: '파일을 찾을 수 없습니다: $normalizedPath',
      );
    }

    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw AppException(
        code: 'transfer_path_not_file',
        message: '파일만 전송할 수 있습니다: $normalizedPath',
      );
    }

    if (stat.size <= 0) {
      throw const AppException(
        code: 'transfer_file_empty',
        message: '빈 파일은 아직 전송할 수 없습니다.',
      );
    }

    final safeChunkSize = chunkSize <= 0 ? 8192 : chunkSize;
    final sha256 = await computeSha256(normalizedPath);
    final chunkCount = (stat.size / safeChunkSize).ceil();
    return PreparedTransferFile(
      filePath: normalizedPath,
      fileName: p.basename(normalizedPath),
      fileSize: stat.size,
      sha256: sha256,
      chunkSize: safeChunkSize,
      chunkCount: chunkCount,
    );
  }

  @override
  Stream<TransferChunk> readChunks(
    String filePath, {
    required int chunkSize,
  }) async* {
    final file = File(filePath);
    final access = await file.open();
    var index = 0;
    try {
      while (true) {
        final bytes = await access.read(chunkSize);
        if (bytes.isEmpty) {
          break;
        }
        yield TransferChunk(index: index, data: bytes);
        index += 1;
      }
    } finally {
      await access.close();
    }
  }

  @override
  Future<List<int>> readChunkAt(
    String filePath, {
    required int chunkSize,
    required int chunkIndex,
  }) async {
    final file = File(filePath);
    final access = await file.open();
    try {
      await access.setPosition(chunkSize * chunkIndex);
      final bytes = await access.read(chunkSize);
      return bytes;
    } finally {
      await access.close();
    }
  }

  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) async {
    final draftDirectory = await Directory.systemTemp.createTemp(
      'sponzey-transfer-$transferId-',
    );
    final safeFileName = p.basename(fileName.trim());
    final tempFilePath = p.join(draftDirectory.path, '$safeFileName.part');
    await File(tempFilePath).create(recursive: true);
    return IncomingTransferDraft(
      transferId: transferId,
      fileName: safeFileName,
      tempDirectoryPath: draftDirectory.path,
      tempFilePath: tempFilePath,
    );
  }

  @override
  Future<void> appendChunk({
    required String tempFilePath,
    required List<int> bytes,
  }) async {
    final file = File(tempFilePath);
    final sink = file.openWrite(mode: FileMode.append);
    sink.add(bytes);
    await sink.flush();
    await sink.close();
  }

  @override
  Future<String> computeSha256(String filePath) async {
    final digest = await sha256.bind(File(filePath).openRead()).first;
    return digest.toString();
  }

  @override
  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  }) async {
    final directory = Directory(destinationDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final targetPath = await _uniqueDestinationPath(
      destinationDirectory: directory.path,
      fileName: p.basename(fileName),
    );
    final sourceFile = File(tempFilePath);
    await sourceFile.rename(targetPath);
    await _cleanupParentDirectory(tempFilePath);
    return targetPath;
  }

  @override
  Future<void> discardDraft(String tempFilePath) async {
    final file = File(tempFilePath);
    if (await file.exists()) {
      await file.delete();
    }
    await _cleanupParentDirectory(tempFilePath);
  }

  Future<String> _uniqueDestinationPath({
    required String destinationDirectory,
    required String fileName,
  }) async {
    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);
    var candidate = p.join(destinationDirectory, fileName);
    var index = 1;
    while (await File(candidate).exists()) {
      final nextName = extension.isEmpty
          ? '$baseName ($index)'
          : '$baseName ($index)$extension';
      candidate = p.join(destinationDirectory, nextName);
      index += 1;
    }
    return candidate;
  }

  Future<void> _cleanupParentDirectory(String tempFilePath) async {
    final parent = Directory(p.dirname(tempFilePath));
    if (await parent.exists()) {
      await parent.delete(recursive: true);
    }
  }
}

final transferFileServiceProvider = Provider<TransferFileService>((ref) {
  return LocalTransferFileService();
});
