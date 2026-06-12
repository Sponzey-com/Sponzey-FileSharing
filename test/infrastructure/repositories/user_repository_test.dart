import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/user_repository.dart';

void main() {
  late AppDatabase database;
  late UserRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = UserRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates and retrieves a user', () async {
    final user = await repository.create(
      userId: 'admin',
      displayName: 'Sponzey Admin',
      deviceName: 'Main Mac',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      hashAlgorithm: 'argon2id',
      hashParams: '{}',
    );

    final fetched = await repository.findByUserId('admin');

    expect(user.userId, 'admin');
    expect(fetched?.displayName, 'Sponzey Admin');
  });

  test('prevents duplicate user ids', () async {
    await repository.create(
      userId: 'admin',
      displayName: 'Sponzey Admin',
      deviceName: 'Main Mac',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      hashAlgorithm: 'argon2id',
      hashParams: '{}',
    );

    expect(
      () => repository.create(
        userId: 'admin',
        displayName: 'Duplicate',
        deviceName: 'Second Mac',
        passwordHash: 'hash2',
        passwordSalt: 'salt2',
        hashAlgorithm: 'argon2id',
        hashParams: '{}',
      ),
      throwsA(isA<AppException>()),
    );
  });
}
