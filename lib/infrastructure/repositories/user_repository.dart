import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';

class UserRepository {
  const UserRepository(this._database);

  final AppDatabase _database;

  Future<User?> findByUserId(String userId) {
    return _database.getUserByUserId(userId);
  }

  Future<User> create({
    required String userId,
    required String displayName,
    required String deviceName,
    required String passwordHash,
    required String passwordSalt,
    required String hashAlgorithm,
    required String hashParams,
  }) async {
    final existing = await findByUserId(userId);
    if (existing != null) {
      throw const AppException(
        code: 'user_id_taken',
        message: '이미 사용 중인 아이디입니다.',
      );
    }

    final now = DateTime.now();
    await _database.createUser(
      UsersCompanion.insert(
        userId: userId,
        displayName: displayName,
        deviceName: deviceName,
        passwordHash: passwordHash,
        passwordSalt: passwordSalt,
        hashAlgorithm: hashAlgorithm,
        hashParams: hashParams,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return (await findByUserId(userId))!;
  }

  Future<void> updatePasswordMetadata({
    required int id,
    required String passwordHash,
    required String passwordSalt,
    required String hashAlgorithm,
    required String hashParams,
  }) {
    return (_database.update(
      _database.users,
    )..where((tbl) => tbl.id.equals(id))).write(
      UsersCompanion(
        passwordHash: Value(passwordHash),
        passwordSalt: Value(passwordSalt),
        hashAlgorithm: Value(hashAlgorithm),
        hashParams: Value(hashParams),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(appDatabaseProvider));
});
