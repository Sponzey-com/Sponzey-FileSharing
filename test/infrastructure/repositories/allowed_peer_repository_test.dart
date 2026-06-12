import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/allowed_peer_repository.dart';

void main() {
  late AppDatabase database;
  late AllowedPeerRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AllowedPeerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('saves, updates, lists, and deletes allowed peers', () async {
    final saved = await repository.save(
      userId: 'peer-a',
      label: 'Peer A',
      verifierBase64: 'verifier-a',
    );

    expect(saved.userId, 'peer-a');

    final updated = await repository.save(
      userId: 'peer-a',
      label: 'Peer A Updated',
      verifierBase64: 'verifier-b',
    );
    final all = await repository.listAll();

    expect(updated.label, 'Peer A Updated');
    expect(all, hasLength(1));
    expect(all.single.verifierBase64, 'verifier-b');

    await repository.deleteByUserId('peer-a');
    expect(await repository.listAll(), isEmpty);
  });
}
