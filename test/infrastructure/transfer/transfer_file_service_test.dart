import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
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

  test('prepares outgoing metadata without computing sha256', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'metadata.txt'));
    await sourceFile.writeAsString('metadata-only');

    final metadata = await service.prepareOutgoingMetadata(
      sourceFile.path,
      chunkSize: 4,
    );

    expect(metadata.fileName, 'metadata.txt');
    expect(metadata.fileSize, 'metadata-only'.length);
    expect(metadata.chunkCount, 4);
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

  test('keeps incoming writer open across multiple appends', () async {
    final draft = await service.createIncomingDraft(
      transferId: 'transfer-writer',
      fileName: 'writer.txt',
    );
    final writer = await service.openIncomingWriter(draft.tempFilePath);

    await writer.append(utf8.encode('fast-'));
    await writer.append(utf8.encode('path-'));
    await writer.append(utf8.encode('receive'));
    await writer.close();

    expect(await File(draft.tempFilePath).readAsString(), 'fast-path-receive');
  });

  test(
    'finalize uses duplicate filename suffix instead of overwrite',
    () async {
      final existing = File(p.join(tempDirectory.path, 'report.txt'));
      await existing.writeAsString('existing');
      final draft = await service.createIncomingDraft(
        transferId: 'transfer-duplicate-name',
        fileName: 'report.txt',
      );
      await service.appendChunk(
        tempFilePath: draft.tempFilePath,
        bytes: utf8.encode('received'),
      );

      final finalPath = await service.finalizeIncomingFile(
        tempFilePath: draft.tempFilePath,
        destinationDirectory: tempDirectory.path,
        fileName: 'report.txt',
      );

      expect(p.basename(finalPath), 'report (1).txt');
      expect(await existing.readAsString(), 'existing');
      expect(await File(finalPath).readAsString(), 'received');
    },
  );

  test('finalize failure removes temporary draft directory', () async {
    final destinationFile = File(p.join(tempDirectory.path, 'not-directory'));
    await destinationFile.writeAsString('block directory creation');
    final draft = await service.createIncomingDraft(
      transferId: 'transfer-finalize-fail',
      fileName: 'fail.txt',
    );
    await service.appendChunk(
      tempFilePath: draft.tempFilePath,
      bytes: utf8.encode('temporary payload'),
    );

    await expectLater(
      service.finalizeIncomingFile(
        tempFilePath: draft.tempFilePath,
        destinationDirectory: destinationFile.path,
        fileName: 'fail.txt',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'incoming_finalize_failed',
        ),
      ),
    );

    expect(await File(draft.tempFilePath).exists(), isFalse);
    expect(await Directory(draft.tempDirectoryPath).exists(), isFalse);
  });

  test('sanitizes Windows sender path names for incoming drafts', () async {
    final draft = await service.createIncomingDraft(
      transferId: 'transfer-windows-name',
      fileName: r'C:\Users\atom\Downloads\report?.txt',
    );

    expect(draft.fileName, 'report_.txt');
    expect(p.basename(draft.tempFilePath), 'report_.txt.part');
    expect(await File(draft.tempFilePath).exists(), isTrue);
  });

  test(
    'digesting incoming writer computes streaming sha256 while appending',
    () async {
      final draft = await service.createIncomingDraft(
        transferId: 'transfer-digest',
        fileName: 'digest.txt',
      );
      final writer = await service.openIncomingDigestingWriter(
        draft.tempFilePath,
      );

      await writer.append(utf8.encode('stream-'));
      await writer.append(utf8.encode('digest'));
      final digest = await writer.closeWithDigest();

      expect(digest, sha256.convert(utf8.encode('stream-digest')).toString());
      expect(await File(draft.tempFilePath).readAsString(), 'stream-digest');
    },
  );

  test('keeps outgoing reader open across positioned chunk reads', () async {
    final sourceFile = File(p.join(tempDirectory.path, 'reader.txt'));
    await sourceFile.writeAsString('abcdefghij');
    final reader = await service.openOutgoingReader(sourceFile.path);

    final secondChunk = await reader.readAt(chunkSize: 3, chunkIndex: 1);
    final fourthChunk = await reader.readAt(chunkSize: 3, chunkIndex: 3);
    await reader.close();

    expect(utf8.decode(secondChunk), 'def');
    expect(utf8.decode(fourthChunk), 'j');
  });
}
