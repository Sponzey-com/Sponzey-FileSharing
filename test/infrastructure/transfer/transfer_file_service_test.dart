import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

void main() {
  late Directory tempDirectory;
  late LocalTransferFileService service;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'sponzey-transfer-service-test-',
    );
    service = LocalTransferFileService();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('splits file into chunks and reassembles bytes', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'sample.txt'));
    const content = 'hello-transfer-world';
    await sourceFile.writeAsString(content);

    final prepared = await service.prepareOutgoingFile(
      sourceFile.path,
      chunkSize: 5,
    );
    final chunks = await service
        .readChunks(sourceFile.path, chunkSize: 5)
        .toList();
    final merged = chunks.expand((chunk) => chunk.data).toList();

    expect(prepared.fileName, 'sample.txt');
    expect(prepared.fileSize, content.length);
    expect(prepared.chunkCount, 4);
    expect(utf8.decode(merged), content);
  });

  test('computes sha256 and finalizes incoming file', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'hash.txt'));
    const content = 'sponzey-file-sharing';
    await sourceFile.writeAsString(content);

    final hash = await service.computeSha256(sourceFile.path);
    expect(hash, sha256.convert(utf8.encode(content)).toString());

    final draft = await service.createIncomingDraft(
      transferId: 'transfer-001',
      fileName: 'received.txt',
    );
    await service.appendChunk(
      tempFilePath: draft.tempFilePath,
      bytes: utf8.encode(content),
    );

    final finalPath = await service.finalizeIncomingFile(
      tempFilePath: draft.tempFilePath,
      destinationDirectory: tempDirectory.path,
      fileName: 'received.txt',
    );

    expect(await File(finalPath).readAsString(), content);
    expect(await File(draft.tempFilePath).exists(), isFalse);
  });
}
