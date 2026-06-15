// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordSaltMeta = const VerificationMeta(
    'passwordSalt',
  );
  @override
  late final GeneratedColumn<String> passwordSalt = GeneratedColumn<String>(
    'password_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashAlgorithmMeta = const VerificationMeta(
    'hashAlgorithm',
  );
  @override
  late final GeneratedColumn<String> hashAlgorithm = GeneratedColumn<String>(
    'hash_algorithm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashParamsMeta = const VerificationMeta(
    'hashParams',
  );
  @override
  late final GeneratedColumn<String> hashParams = GeneratedColumn<String>(
    'hash_params',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    displayName,
    deviceName,
    passwordHash,
    passwordSalt,
    hashAlgorithm,
    hashParams,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('password_salt')) {
      context.handle(
        _passwordSaltMeta,
        passwordSalt.isAcceptableOrUnknown(
          data['password_salt']!,
          _passwordSaltMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordSaltMeta);
    }
    if (data.containsKey('hash_algorithm')) {
      context.handle(
        _hashAlgorithmMeta,
        hashAlgorithm.isAcceptableOrUnknown(
          data['hash_algorithm']!,
          _hashAlgorithmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashAlgorithmMeta);
    }
    if (data.containsKey('hash_params')) {
      context.handle(
        _hashParamsMeta,
        hashParams.isAcceptableOrUnknown(data['hash_params']!, _hashParamsMeta),
      );
    } else if (isInserting) {
      context.missing(_hashParamsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      passwordSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_salt'],
      )!,
      hashAlgorithm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_algorithm'],
      )!,
      hashParams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash_params'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String userId;
  final String displayName;
  final String deviceName;
  final String passwordHash;
  final String passwordSalt;
  final String hashAlgorithm;
  final String hashParams;
  final DateTime createdAt;
  final DateTime updatedAt;
  const User({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.deviceName,
    required this.passwordHash,
    required this.passwordSalt,
    required this.hashAlgorithm,
    required this.hashParams,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    map['device_name'] = Variable<String>(deviceName);
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    map['hash_algorithm'] = Variable<String>(hashAlgorithm);
    map['hash_params'] = Variable<String>(hashParams);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      userId: Value(userId),
      displayName: Value(displayName),
      deviceName: Value(deviceName),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      hashAlgorithm: Value(hashAlgorithm),
      hashParams: Value(hashParams),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      hashAlgorithm: serializer.fromJson<String>(json['hashAlgorithm']),
      hashParams: serializer.fromJson<String>(json['hashParams']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'deviceName': serializer.toJson<String>(deviceName),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'hashAlgorithm': serializer.toJson<String>(hashAlgorithm),
      'hashParams': serializer.toJson<String>(hashParams),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith({
    int? id,
    String? userId,
    String? displayName,
    String? deviceName,
    String? passwordHash,
    String? passwordSalt,
    String? hashAlgorithm,
    String? hashParams,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    deviceName: deviceName ?? this.deviceName,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    hashAlgorithm: hashAlgorithm ?? this.hashAlgorithm,
    hashParams: hashParams ?? this.hashParams,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      hashAlgorithm: data.hashAlgorithm.present
          ? data.hashAlgorithm.value
          : this.hashAlgorithm,
      hashParams: data.hashParams.present
          ? data.hashParams.value
          : this.hashParams,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('deviceName: $deviceName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('hashAlgorithm: $hashAlgorithm, ')
          ..write('hashParams: $hashParams, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    displayName,
    deviceName,
    passwordHash,
    passwordSalt,
    hashAlgorithm,
    hashParams,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.deviceName == this.deviceName &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.hashAlgorithm == this.hashAlgorithm &&
          other.hashParams == this.hashParams &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<String> deviceName;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<String> hashAlgorithm;
  final Value<String> hashParams;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.hashAlgorithm = const Value.absent(),
    this.hashParams = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String displayName,
    required String deviceName,
    required String passwordHash,
    required String passwordSalt,
    required String hashAlgorithm,
    required String hashParams,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : userId = Value(userId),
       displayName = Value(displayName),
       deviceName = Value(deviceName),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt),
       hashAlgorithm = Value(hashAlgorithm),
       hashParams = Value(hashParams),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? deviceName,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<String>? hashAlgorithm,
    Expression<String>? hashParams,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (deviceName != null) 'device_name': deviceName,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (hashAlgorithm != null) 'hash_algorithm': hashAlgorithm,
      if (hashParams != null) 'hash_params': hashParams,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? displayName,
    Value<String>? deviceName,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<String>? hashAlgorithm,
    Value<String>? hashParams,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      deviceName: deviceName ?? this.deviceName,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      hashAlgorithm: hashAlgorithm ?? this.hashAlgorithm,
      hashParams: hashParams ?? this.hashParams,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSalt.present) {
      map['password_salt'] = Variable<String>(passwordSalt.value);
    }
    if (hashAlgorithm.present) {
      map['hash_algorithm'] = Variable<String>(hashAlgorithm.value);
    }
    if (hashParams.present) {
      map['hash_params'] = Variable<String>(hashParams.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('deviceName: $deviceName, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('hashAlgorithm: $hashAlgorithm, ')
          ..write('hashParams: $hashParams, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _defaultSavePathMeta = const VerificationMeta(
    'defaultSavePath',
  );
  @override
  late final GeneratedColumn<String> defaultSavePath = GeneratedColumn<String>(
    'default_save_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoReceiveEnabledMeta =
      const VerificationMeta('autoReceiveEnabled');
  @override
  late final GeneratedColumn<bool> autoReceiveEnabled = GeneratedColumn<bool>(
    'auto_receive_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_receive_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _receivePolicyMeta = const VerificationMeta(
    'receivePolicy',
  );
  @override
  late final GeneratedColumn<String> receivePolicy = GeneratedColumn<String>(
    'receive_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logLevelMeta = const VerificationMeta(
    'logLevel',
  );
  @override
  late final GeneratedColumn<String> logLevel = GeneratedColumn<String>(
    'log_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    defaultSavePath,
    autoReceiveEnabled,
    receivePolicy,
    logLevel,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('default_save_path')) {
      context.handle(
        _defaultSavePathMeta,
        defaultSavePath.isAcceptableOrUnknown(
          data['default_save_path']!,
          _defaultSavePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultSavePathMeta);
    }
    if (data.containsKey('auto_receive_enabled')) {
      context.handle(
        _autoReceiveEnabledMeta,
        autoReceiveEnabled.isAcceptableOrUnknown(
          data['auto_receive_enabled']!,
          _autoReceiveEnabledMeta,
        ),
      );
    }
    if (data.containsKey('receive_policy')) {
      context.handle(
        _receivePolicyMeta,
        receivePolicy.isAcceptableOrUnknown(
          data['receive_policy']!,
          _receivePolicyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivePolicyMeta);
    }
    if (data.containsKey('log_level')) {
      context.handle(
        _logLevelMeta,
        logLevel.isAcceptableOrUnknown(data['log_level']!, _logLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_logLevelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      defaultSavePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_save_path'],
      )!,
      autoReceiveEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_receive_enabled'],
      )!,
      receivePolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receive_policy'],
      )!,
      logLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_level'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String defaultSavePath;
  final bool autoReceiveEnabled;
  final String receivePolicy;
  final String logLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Setting({
    required this.id,
    required this.defaultSavePath,
    required this.autoReceiveEnabled,
    required this.receivePolicy,
    required this.logLevel,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['default_save_path'] = Variable<String>(defaultSavePath);
    map['auto_receive_enabled'] = Variable<bool>(autoReceiveEnabled);
    map['receive_policy'] = Variable<String>(receivePolicy);
    map['log_level'] = Variable<String>(logLevel);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      defaultSavePath: Value(defaultSavePath),
      autoReceiveEnabled: Value(autoReceiveEnabled),
      receivePolicy: Value(receivePolicy),
      logLevel: Value(logLevel),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      defaultSavePath: serializer.fromJson<String>(json['defaultSavePath']),
      autoReceiveEnabled: serializer.fromJson<bool>(json['autoReceiveEnabled']),
      receivePolicy: serializer.fromJson<String>(json['receivePolicy']),
      logLevel: serializer.fromJson<String>(json['logLevel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'defaultSavePath': serializer.toJson<String>(defaultSavePath),
      'autoReceiveEnabled': serializer.toJson<bool>(autoReceiveEnabled),
      'receivePolicy': serializer.toJson<String>(receivePolicy),
      'logLevel': serializer.toJson<String>(logLevel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({
    int? id,
    String? defaultSavePath,
    bool? autoReceiveEnabled,
    String? receivePolicy,
    String? logLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Setting(
    id: id ?? this.id,
    defaultSavePath: defaultSavePath ?? this.defaultSavePath,
    autoReceiveEnabled: autoReceiveEnabled ?? this.autoReceiveEnabled,
    receivePolicy: receivePolicy ?? this.receivePolicy,
    logLevel: logLevel ?? this.logLevel,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      defaultSavePath: data.defaultSavePath.present
          ? data.defaultSavePath.value
          : this.defaultSavePath,
      autoReceiveEnabled: data.autoReceiveEnabled.present
          ? data.autoReceiveEnabled.value
          : this.autoReceiveEnabled,
      receivePolicy: data.receivePolicy.present
          ? data.receivePolicy.value
          : this.receivePolicy,
      logLevel: data.logLevel.present ? data.logLevel.value : this.logLevel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('defaultSavePath: $defaultSavePath, ')
          ..write('autoReceiveEnabled: $autoReceiveEnabled, ')
          ..write('receivePolicy: $receivePolicy, ')
          ..write('logLevel: $logLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    defaultSavePath,
    autoReceiveEnabled,
    receivePolicy,
    logLevel,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.defaultSavePath == this.defaultSavePath &&
          other.autoReceiveEnabled == this.autoReceiveEnabled &&
          other.receivePolicy == this.receivePolicy &&
          other.logLevel == this.logLevel &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> defaultSavePath;
  final Value<bool> autoReceiveEnabled;
  final Value<String> receivePolicy;
  final Value<String> logLevel;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.defaultSavePath = const Value.absent(),
    this.autoReceiveEnabled = const Value.absent(),
    this.receivePolicy = const Value.absent(),
    this.logLevel = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String defaultSavePath,
    this.autoReceiveEnabled = const Value.absent(),
    required String receivePolicy,
    required String logLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : defaultSavePath = Value(defaultSavePath),
       receivePolicy = Value(receivePolicy),
       logLevel = Value(logLevel),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? defaultSavePath,
    Expression<bool>? autoReceiveEnabled,
    Expression<String>? receivePolicy,
    Expression<String>? logLevel,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (defaultSavePath != null) 'default_save_path': defaultSavePath,
      if (autoReceiveEnabled != null)
        'auto_receive_enabled': autoReceiveEnabled,
      if (receivePolicy != null) 'receive_policy': receivePolicy,
      if (logLevel != null) 'log_level': logLevel,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? defaultSavePath,
    Value<bool>? autoReceiveEnabled,
    Value<String>? receivePolicy,
    Value<String>? logLevel,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      defaultSavePath: defaultSavePath ?? this.defaultSavePath,
      autoReceiveEnabled: autoReceiveEnabled ?? this.autoReceiveEnabled,
      receivePolicy: receivePolicy ?? this.receivePolicy,
      logLevel: logLevel ?? this.logLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (defaultSavePath.present) {
      map['default_save_path'] = Variable<String>(defaultSavePath.value);
    }
    if (autoReceiveEnabled.present) {
      map['auto_receive_enabled'] = Variable<bool>(autoReceiveEnabled.value);
    }
    if (receivePolicy.present) {
      map['receive_policy'] = Variable<String>(receivePolicy.value);
    }
    if (logLevel.present) {
      map['log_level'] = Variable<String>(logLevel.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('defaultSavePath: $defaultSavePath, ')
          ..write('autoReceiveEnabled: $autoReceiveEnabled, ')
          ..write('receivePolicy: $receivePolicy, ')
          ..write('logLevel: $logLevel, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PeersTable extends Peers with TableInfo<$PeersTable, Peer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<String> peerUserId = GeneratedColumn<String>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDeviceIdMeta = const VerificationMeta(
    'peerDeviceId',
  );
  @override
  late final GeneratedColumn<String> peerDeviceId = GeneratedColumn<String>(
    'peer_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _peerDisplayNameMeta = const VerificationMeta(
    'peerDisplayName',
  );
  @override
  late final GeneratedColumn<String> peerDisplayName = GeneratedColumn<String>(
    'peer_display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDeviceNameMeta = const VerificationMeta(
    'peerDeviceName',
  );
  @override
  late final GeneratedColumn<String> peerDeviceName = GeneratedColumn<String>(
    'peer_device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _osTypeMeta = const VerificationMeta('osType');
  @override
  late final GeneratedColumn<String> osType = GeneratedColumn<String>(
    'os_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastIpMeta = const VerificationMeta('lastIp');
  @override
  late final GeneratedColumn<String> lastIp = GeneratedColumn<String>(
    'last_ip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPortMeta = const VerificationMeta(
    'lastPort',
  );
  @override
  late final GeneratedColumn<int> lastPort = GeneratedColumn<int>(
    'last_port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<String> protocolVersion = GeneratedColumn<String>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiveAvailableMeta = const VerificationMeta(
    'receiveAvailable',
  );
  @override
  late final GeneratedColumn<bool> receiveAvailable = GeneratedColumn<bool>(
    'receive_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("receive_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerUserId,
    peerDeviceId,
    peerDisplayName,
    peerDeviceName,
    osType,
    lastIp,
    lastPort,
    protocolVersion,
    receiveAvailable,
    lastSeenAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Peer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('peer_device_id')) {
      context.handle(
        _peerDeviceIdMeta,
        peerDeviceId.isAcceptableOrUnknown(
          data['peer_device_id']!,
          _peerDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDeviceIdMeta);
    }
    if (data.containsKey('peer_display_name')) {
      context.handle(
        _peerDisplayNameMeta,
        peerDisplayName.isAcceptableOrUnknown(
          data['peer_display_name']!,
          _peerDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDisplayNameMeta);
    }
    if (data.containsKey('peer_device_name')) {
      context.handle(
        _peerDeviceNameMeta,
        peerDeviceName.isAcceptableOrUnknown(
          data['peer_device_name']!,
          _peerDeviceNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDeviceNameMeta);
    }
    if (data.containsKey('os_type')) {
      context.handle(
        _osTypeMeta,
        osType.isAcceptableOrUnknown(data['os_type']!, _osTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_osTypeMeta);
    }
    if (data.containsKey('last_ip')) {
      context.handle(
        _lastIpMeta,
        lastIp.isAcceptableOrUnknown(data['last_ip']!, _lastIpMeta),
      );
    } else if (isInserting) {
      context.missing(_lastIpMeta);
    }
    if (data.containsKey('last_port')) {
      context.handle(
        _lastPortMeta,
        lastPort.isAcceptableOrUnknown(data['last_port']!, _lastPortMeta),
      );
    } else if (isInserting) {
      context.missing(_lastPortMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('receive_available')) {
      context.handle(
        _receiveAvailableMeta,
        receiveAvailable.isAcceptableOrUnknown(
          data['receive_available']!,
          _receiveAvailableMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Peer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Peer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_user_id'],
      )!,
      peerDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_device_id'],
      )!,
      peerDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_display_name'],
      )!,
      peerDeviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_device_name'],
      )!,
      osType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_type'],
      )!,
      lastIp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_ip'],
      )!,
      lastPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_port'],
      )!,
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version'],
      )!,
      receiveAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}receive_available'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PeersTable createAlias(String alias) {
    return $PeersTable(attachedDatabase, alias);
  }
}

class Peer extends DataClass implements Insertable<Peer> {
  final int id;
  final String peerUserId;
  final String peerDeviceId;
  final String peerDisplayName;
  final String peerDeviceName;
  final String osType;
  final String lastIp;
  final int lastPort;
  final String protocolVersion;
  final bool receiveAvailable;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Peer({
    required this.id,
    required this.peerUserId,
    required this.peerDeviceId,
    required this.peerDisplayName,
    required this.peerDeviceName,
    required this.osType,
    required this.lastIp,
    required this.lastPort,
    required this.protocolVersion,
    required this.receiveAvailable,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['peer_user_id'] = Variable<String>(peerUserId);
    map['peer_device_id'] = Variable<String>(peerDeviceId);
    map['peer_display_name'] = Variable<String>(peerDisplayName);
    map['peer_device_name'] = Variable<String>(peerDeviceName);
    map['os_type'] = Variable<String>(osType);
    map['last_ip'] = Variable<String>(lastIp);
    map['last_port'] = Variable<int>(lastPort);
    map['protocol_version'] = Variable<String>(protocolVersion);
    map['receive_available'] = Variable<bool>(receiveAvailable);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PeersCompanion toCompanion(bool nullToAbsent) {
    return PeersCompanion(
      id: Value(id),
      peerUserId: Value(peerUserId),
      peerDeviceId: Value(peerDeviceId),
      peerDisplayName: Value(peerDisplayName),
      peerDeviceName: Value(peerDeviceName),
      osType: Value(osType),
      lastIp: Value(lastIp),
      lastPort: Value(lastPort),
      protocolVersion: Value(protocolVersion),
      receiveAvailable: Value(receiveAvailable),
      lastSeenAt: Value(lastSeenAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Peer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Peer(
      id: serializer.fromJson<int>(json['id']),
      peerUserId: serializer.fromJson<String>(json['peerUserId']),
      peerDeviceId: serializer.fromJson<String>(json['peerDeviceId']),
      peerDisplayName: serializer.fromJson<String>(json['peerDisplayName']),
      peerDeviceName: serializer.fromJson<String>(json['peerDeviceName']),
      osType: serializer.fromJson<String>(json['osType']),
      lastIp: serializer.fromJson<String>(json['lastIp']),
      lastPort: serializer.fromJson<int>(json['lastPort']),
      protocolVersion: serializer.fromJson<String>(json['protocolVersion']),
      receiveAvailable: serializer.fromJson<bool>(json['receiveAvailable']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'peerUserId': serializer.toJson<String>(peerUserId),
      'peerDeviceId': serializer.toJson<String>(peerDeviceId),
      'peerDisplayName': serializer.toJson<String>(peerDisplayName),
      'peerDeviceName': serializer.toJson<String>(peerDeviceName),
      'osType': serializer.toJson<String>(osType),
      'lastIp': serializer.toJson<String>(lastIp),
      'lastPort': serializer.toJson<int>(lastPort),
      'protocolVersion': serializer.toJson<String>(protocolVersion),
      'receiveAvailable': serializer.toJson<bool>(receiveAvailable),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Peer copyWith({
    int? id,
    String? peerUserId,
    String? peerDeviceId,
    String? peerDisplayName,
    String? peerDeviceName,
    String? osType,
    String? lastIp,
    int? lastPort,
    String? protocolVersion,
    bool? receiveAvailable,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Peer(
    id: id ?? this.id,
    peerUserId: peerUserId ?? this.peerUserId,
    peerDeviceId: peerDeviceId ?? this.peerDeviceId,
    peerDisplayName: peerDisplayName ?? this.peerDisplayName,
    peerDeviceName: peerDeviceName ?? this.peerDeviceName,
    osType: osType ?? this.osType,
    lastIp: lastIp ?? this.lastIp,
    lastPort: lastPort ?? this.lastPort,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    receiveAvailable: receiveAvailable ?? this.receiveAvailable,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Peer copyWithCompanion(PeersCompanion data) {
    return Peer(
      id: data.id.present ? data.id.value : this.id,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerDeviceId: data.peerDeviceId.present
          ? data.peerDeviceId.value
          : this.peerDeviceId,
      peerDisplayName: data.peerDisplayName.present
          ? data.peerDisplayName.value
          : this.peerDisplayName,
      peerDeviceName: data.peerDeviceName.present
          ? data.peerDeviceName.value
          : this.peerDeviceName,
      osType: data.osType.present ? data.osType.value : this.osType,
      lastIp: data.lastIp.present ? data.lastIp.value : this.lastIp,
      lastPort: data.lastPort.present ? data.lastPort.value : this.lastPort,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      receiveAvailable: data.receiveAvailable.present
          ? data.receiveAvailable.value
          : this.receiveAvailable,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Peer(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('osType: $osType, ')
          ..write('lastIp: $lastIp, ')
          ..write('lastPort: $lastPort, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('receiveAvailable: $receiveAvailable, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    peerUserId,
    peerDeviceId,
    peerDisplayName,
    peerDeviceName,
    osType,
    lastIp,
    lastPort,
    protocolVersion,
    receiveAvailable,
    lastSeenAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Peer &&
          other.id == this.id &&
          other.peerUserId == this.peerUserId &&
          other.peerDeviceId == this.peerDeviceId &&
          other.peerDisplayName == this.peerDisplayName &&
          other.peerDeviceName == this.peerDeviceName &&
          other.osType == this.osType &&
          other.lastIp == this.lastIp &&
          other.lastPort == this.lastPort &&
          other.protocolVersion == this.protocolVersion &&
          other.receiveAvailable == this.receiveAvailable &&
          other.lastSeenAt == this.lastSeenAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PeersCompanion extends UpdateCompanion<Peer> {
  final Value<int> id;
  final Value<String> peerUserId;
  final Value<String> peerDeviceId;
  final Value<String> peerDisplayName;
  final Value<String> peerDeviceName;
  final Value<String> osType;
  final Value<String> lastIp;
  final Value<int> lastPort;
  final Value<String> protocolVersion;
  final Value<bool> receiveAvailable;
  final Value<DateTime> lastSeenAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PeersCompanion({
    this.id = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerDeviceId = const Value.absent(),
    this.peerDisplayName = const Value.absent(),
    this.peerDeviceName = const Value.absent(),
    this.osType = const Value.absent(),
    this.lastIp = const Value.absent(),
    this.lastPort = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.receiveAvailable = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PeersCompanion.insert({
    this.id = const Value.absent(),
    required String peerUserId,
    required String peerDeviceId,
    required String peerDisplayName,
    required String peerDeviceName,
    required String osType,
    required String lastIp,
    required int lastPort,
    required String protocolVersion,
    this.receiveAvailable = const Value.absent(),
    required DateTime lastSeenAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : peerUserId = Value(peerUserId),
       peerDeviceId = Value(peerDeviceId),
       peerDisplayName = Value(peerDisplayName),
       peerDeviceName = Value(peerDeviceName),
       osType = Value(osType),
       lastIp = Value(lastIp),
       lastPort = Value(lastPort),
       protocolVersion = Value(protocolVersion),
       lastSeenAt = Value(lastSeenAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Peer> custom({
    Expression<int>? id,
    Expression<String>? peerUserId,
    Expression<String>? peerDeviceId,
    Expression<String>? peerDisplayName,
    Expression<String>? peerDeviceName,
    Expression<String>? osType,
    Expression<String>? lastIp,
    Expression<int>? lastPort,
    Expression<String>? protocolVersion,
    Expression<bool>? receiveAvailable,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerDeviceId != null) 'peer_device_id': peerDeviceId,
      if (peerDisplayName != null) 'peer_display_name': peerDisplayName,
      if (peerDeviceName != null) 'peer_device_name': peerDeviceName,
      if (osType != null) 'os_type': osType,
      if (lastIp != null) 'last_ip': lastIp,
      if (lastPort != null) 'last_port': lastPort,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (receiveAvailable != null) 'receive_available': receiveAvailable,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PeersCompanion copyWith({
    Value<int>? id,
    Value<String>? peerUserId,
    Value<String>? peerDeviceId,
    Value<String>? peerDisplayName,
    Value<String>? peerDeviceName,
    Value<String>? osType,
    Value<String>? lastIp,
    Value<int>? lastPort,
    Value<String>? protocolVersion,
    Value<bool>? receiveAvailable,
    Value<DateTime>? lastSeenAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PeersCompanion(
      id: id ?? this.id,
      peerUserId: peerUserId ?? this.peerUserId,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerDeviceName: peerDeviceName ?? this.peerDeviceName,
      osType: osType ?? this.osType,
      lastIp: lastIp ?? this.lastIp,
      lastPort: lastPort ?? this.lastPort,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      receiveAvailable: receiveAvailable ?? this.receiveAvailable,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<String>(peerUserId.value);
    }
    if (peerDeviceId.present) {
      map['peer_device_id'] = Variable<String>(peerDeviceId.value);
    }
    if (peerDisplayName.present) {
      map['peer_display_name'] = Variable<String>(peerDisplayName.value);
    }
    if (peerDeviceName.present) {
      map['peer_device_name'] = Variable<String>(peerDeviceName.value);
    }
    if (osType.present) {
      map['os_type'] = Variable<String>(osType.value);
    }
    if (lastIp.present) {
      map['last_ip'] = Variable<String>(lastIp.value);
    }
    if (lastPort.present) {
      map['last_port'] = Variable<int>(lastPort.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<String>(protocolVersion.value);
    }
    if (receiveAvailable.present) {
      map['receive_available'] = Variable<bool>(receiveAvailable.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeersCompanion(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerDeviceId: $peerDeviceId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('peerDeviceName: $peerDeviceName, ')
          ..write('osType: $osType, ')
          ..write('lastIp: $lastIp, ')
          ..write('lastPort: $lastPort, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('receiveAvailable: $receiveAvailable, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AllowedPeersTable extends AllowedPeers
    with TableInfo<$AllowedPeersTable, AllowedPeer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllowedPeersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<String> peerUserId = GeneratedColumn<String>(
    'peer_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifierBase64Meta = const VerificationMeta(
    'verifierBase64',
  );
  @override
  late final GeneratedColumn<String> verifierBase64 = GeneratedColumn<String>(
    'verifier_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    peerUserId,
    label,
    verifierBase64,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allowed_peers';
  @override
  VerificationContext validateIntegrity(
    Insertable<AllowedPeer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerUserIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('verifier_base64')) {
      context.handle(
        _verifierBase64Meta,
        verifierBase64.isAcceptableOrUnknown(
          data['verifier_base64']!,
          _verifierBase64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_verifierBase64Meta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AllowedPeer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AllowedPeer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_user_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      verifierBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verifier_base64'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AllowedPeersTable createAlias(String alias) {
    return $AllowedPeersTable(attachedDatabase, alias);
  }
}

class AllowedPeer extends DataClass implements Insertable<AllowedPeer> {
  final int id;
  final String peerUserId;
  final String label;
  final String verifierBase64;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AllowedPeer({
    required this.id,
    required this.peerUserId,
    required this.label,
    required this.verifierBase64,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['peer_user_id'] = Variable<String>(peerUserId);
    map['label'] = Variable<String>(label);
    map['verifier_base64'] = Variable<String>(verifierBase64);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AllowedPeersCompanion toCompanion(bool nullToAbsent) {
    return AllowedPeersCompanion(
      id: Value(id),
      peerUserId: Value(peerUserId),
      label: Value(label),
      verifierBase64: Value(verifierBase64),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AllowedPeer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AllowedPeer(
      id: serializer.fromJson<int>(json['id']),
      peerUserId: serializer.fromJson<String>(json['peerUserId']),
      label: serializer.fromJson<String>(json['label']),
      verifierBase64: serializer.fromJson<String>(json['verifierBase64']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'peerUserId': serializer.toJson<String>(peerUserId),
      'label': serializer.toJson<String>(label),
      'verifierBase64': serializer.toJson<String>(verifierBase64),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AllowedPeer copyWith({
    int? id,
    String? peerUserId,
    String? label,
    String? verifierBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AllowedPeer(
    id: id ?? this.id,
    peerUserId: peerUserId ?? this.peerUserId,
    label: label ?? this.label,
    verifierBase64: verifierBase64 ?? this.verifierBase64,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AllowedPeer copyWithCompanion(AllowedPeersCompanion data) {
    return AllowedPeer(
      id: data.id.present ? data.id.value : this.id,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      label: data.label.present ? data.label.value : this.label,
      verifierBase64: data.verifierBase64.present
          ? data.verifierBase64.value
          : this.verifierBase64,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllowedPeer(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('label: $label, ')
          ..write('verifierBase64: $verifierBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, peerUserId, label, verifierBase64, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllowedPeer &&
          other.id == this.id &&
          other.peerUserId == this.peerUserId &&
          other.label == this.label &&
          other.verifierBase64 == this.verifierBase64 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AllowedPeersCompanion extends UpdateCompanion<AllowedPeer> {
  final Value<int> id;
  final Value<String> peerUserId;
  final Value<String> label;
  final Value<String> verifierBase64;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AllowedPeersCompanion({
    this.id = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.label = const Value.absent(),
    this.verifierBase64 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AllowedPeersCompanion.insert({
    this.id = const Value.absent(),
    required String peerUserId,
    required String label,
    required String verifierBase64,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : peerUserId = Value(peerUserId),
       label = Value(label),
       verifierBase64 = Value(verifierBase64),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AllowedPeer> custom({
    Expression<int>? id,
    Expression<String>? peerUserId,
    Expression<String>? label,
    Expression<String>? verifierBase64,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (label != null) 'label': label,
      if (verifierBase64 != null) 'verifier_base64': verifierBase64,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AllowedPeersCompanion copyWith({
    Value<int>? id,
    Value<String>? peerUserId,
    Value<String>? label,
    Value<String>? verifierBase64,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AllowedPeersCompanion(
      id: id ?? this.id,
      peerUserId: peerUserId ?? this.peerUserId,
      label: label ?? this.label,
      verifierBase64: verifierBase64 ?? this.verifierBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<String>(peerUserId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (verifierBase64.present) {
      map['verifier_base64'] = Variable<String>(verifierBase64.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllowedPeersCompanion(')
          ..write('id: $id, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('label: $label, ')
          ..write('verifierBase64: $verifierBase64, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransferHistoryJobsTable extends TransferHistoryJobs
    with TableInfo<$TransferHistoryJobsTable, TransferHistoryJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerIdMeta = const VerificationMeta('peerId');
  @override
  late final GeneratedColumn<String> peerId = GeneratedColumn<String>(
    'peer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _peerDisplayNameMeta = const VerificationMeta(
    'peerDisplayName',
  );
  @override
  late final GeneratedColumn<String> peerDisplayName = GeneratedColumn<String>(
    'peer_display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCategoryMeta = const VerificationMeta(
    'failureCategory',
  );
  @override
  late final GeneratedColumn<String> failureCategory = GeneratedColumn<String>(
    'failure_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileCountMeta = const VerificationMeta(
    'fileCount',
  );
  @override
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesTransferredMeta = const VerificationMeta(
    'bytesTransferred',
  );
  @override
  late final GeneratedColumn<int> bytesTransferred = GeneratedColumn<int>(
    'bytes_transferred',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalChunksMeta = const VerificationMeta(
    'totalChunks',
  );
  @override
  late final GeneratedColumn<int> totalChunks = GeneratedColumn<int>(
    'total_chunks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedChunksMeta = const VerificationMeta(
    'completedChunks',
  );
  @override
  late final GeneratedColumn<int> completedChunks = GeneratedColumn<int>(
    'completed_chunks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lossRateMeta = const VerificationMeta(
    'lossRate',
  );
  @override
  late final GeneratedColumn<double> lossRate = GeneratedColumn<double>(
    'loss_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _throughputBytesPerSecMeta =
      const VerificationMeta('throughputBytesPerSec');
  @override
  late final GeneratedColumn<double> throughputBytesPerSec =
      GeneratedColumn<double>(
        'throughput_bytes_per_sec',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transferId,
    direction,
    peerId,
    peerDisplayName,
    status,
    failureCategory,
    failureCode,
    message,
    fileCount,
    totalBytes,
    bytesTransferred,
    totalChunks,
    completedChunks,
    retryCount,
    lossRate,
    throughputBytesPerSec,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferHistoryJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('peer_id')) {
      context.handle(
        _peerIdMeta,
        peerId.isAcceptableOrUnknown(data['peer_id']!, _peerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_peerIdMeta);
    }
    if (data.containsKey('peer_display_name')) {
      context.handle(
        _peerDisplayNameMeta,
        peerDisplayName.isAcceptableOrUnknown(
          data['peer_display_name']!,
          _peerDisplayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_peerDisplayNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('failure_category')) {
      context.handle(
        _failureCategoryMeta,
        failureCategory.isAcceptableOrUnknown(
          data['failure_category']!,
          _failureCategoryMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _fileCountMeta,
        fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('bytes_transferred')) {
      context.handle(
        _bytesTransferredMeta,
        bytesTransferred.isAcceptableOrUnknown(
          data['bytes_transferred']!,
          _bytesTransferredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bytesTransferredMeta);
    }
    if (data.containsKey('total_chunks')) {
      context.handle(
        _totalChunksMeta,
        totalChunks.isAcceptableOrUnknown(
          data['total_chunks']!,
          _totalChunksMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalChunksMeta);
    }
    if (data.containsKey('completed_chunks')) {
      context.handle(
        _completedChunksMeta,
        completedChunks.isAcceptableOrUnknown(
          data['completed_chunks']!,
          _completedChunksMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedChunksMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('loss_rate')) {
      context.handle(
        _lossRateMeta,
        lossRate.isAcceptableOrUnknown(data['loss_rate']!, _lossRateMeta),
      );
    }
    if (data.containsKey('throughput_bytes_per_sec')) {
      context.handle(
        _throughputBytesPerSecMeta,
        throughputBytesPerSec.isAcceptableOrUnknown(
          data['throughput_bytes_per_sec']!,
          _throughputBytesPerSecMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      peerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_id'],
      )!,
      peerDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_display_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      failureCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_category'],
      ),
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      fileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      bytesTransferred: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_transferred'],
      )!,
      totalChunks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chunks'],
      )!,
      completedChunks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_chunks'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lossRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}loss_rate'],
      )!,
      throughputBytesPerSec: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}throughput_bytes_per_sec'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransferHistoryJobsTable createAlias(String alias) {
    return $TransferHistoryJobsTable(attachedDatabase, alias);
  }
}

class TransferHistoryJob extends DataClass
    implements Insertable<TransferHistoryJob> {
  final String id;
  final String transferId;
  final String direction;
  final String peerId;
  final String peerDisplayName;
  final String status;
  final String? failureCategory;
  final String? failureCode;
  final String? message;
  final int fileCount;
  final int totalBytes;
  final int bytesTransferred;
  final int totalChunks;
  final int completedChunks;
  final int retryCount;
  final double lossRate;
  final double throughputBytesPerSec;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransferHistoryJob({
    required this.id,
    required this.transferId,
    required this.direction,
    required this.peerId,
    required this.peerDisplayName,
    required this.status,
    this.failureCategory,
    this.failureCode,
    this.message,
    required this.fileCount,
    required this.totalBytes,
    required this.bytesTransferred,
    required this.totalChunks,
    required this.completedChunks,
    required this.retryCount,
    required this.lossRate,
    required this.throughputBytesPerSec,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transfer_id'] = Variable<String>(transferId);
    map['direction'] = Variable<String>(direction);
    map['peer_id'] = Variable<String>(peerId);
    map['peer_display_name'] = Variable<String>(peerDisplayName);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || failureCategory != null) {
      map['failure_category'] = Variable<String>(failureCategory);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['file_count'] = Variable<int>(fileCount);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['bytes_transferred'] = Variable<int>(bytesTransferred);
    map['total_chunks'] = Variable<int>(totalChunks);
    map['completed_chunks'] = Variable<int>(completedChunks);
    map['retry_count'] = Variable<int>(retryCount);
    map['loss_rate'] = Variable<double>(lossRate);
    map['throughput_bytes_per_sec'] = Variable<double>(throughputBytesPerSec);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransferHistoryJobsCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryJobsCompanion(
      id: Value(id),
      transferId: Value(transferId),
      direction: Value(direction),
      peerId: Value(peerId),
      peerDisplayName: Value(peerDisplayName),
      status: Value(status),
      failureCategory: failureCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCategory),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      fileCount: Value(fileCount),
      totalBytes: Value(totalBytes),
      bytesTransferred: Value(bytesTransferred),
      totalChunks: Value(totalChunks),
      completedChunks: Value(completedChunks),
      retryCount: Value(retryCount),
      lossRate: Value(lossRate),
      throughputBytesPerSec: Value(throughputBytesPerSec),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransferHistoryJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryJob(
      id: serializer.fromJson<String>(json['id']),
      transferId: serializer.fromJson<String>(json['transferId']),
      direction: serializer.fromJson<String>(json['direction']),
      peerId: serializer.fromJson<String>(json['peerId']),
      peerDisplayName: serializer.fromJson<String>(json['peerDisplayName']),
      status: serializer.fromJson<String>(json['status']),
      failureCategory: serializer.fromJson<String?>(json['failureCategory']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      message: serializer.fromJson<String?>(json['message']),
      fileCount: serializer.fromJson<int>(json['fileCount']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      bytesTransferred: serializer.fromJson<int>(json['bytesTransferred']),
      totalChunks: serializer.fromJson<int>(json['totalChunks']),
      completedChunks: serializer.fromJson<int>(json['completedChunks']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lossRate: serializer.fromJson<double>(json['lossRate']),
      throughputBytesPerSec: serializer.fromJson<double>(
        json['throughputBytesPerSec'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transferId': serializer.toJson<String>(transferId),
      'direction': serializer.toJson<String>(direction),
      'peerId': serializer.toJson<String>(peerId),
      'peerDisplayName': serializer.toJson<String>(peerDisplayName),
      'status': serializer.toJson<String>(status),
      'failureCategory': serializer.toJson<String?>(failureCategory),
      'failureCode': serializer.toJson<String?>(failureCode),
      'message': serializer.toJson<String?>(message),
      'fileCount': serializer.toJson<int>(fileCount),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'bytesTransferred': serializer.toJson<int>(bytesTransferred),
      'totalChunks': serializer.toJson<int>(totalChunks),
      'completedChunks': serializer.toJson<int>(completedChunks),
      'retryCount': serializer.toJson<int>(retryCount),
      'lossRate': serializer.toJson<double>(lossRate),
      'throughputBytesPerSec': serializer.toJson<double>(throughputBytesPerSec),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransferHistoryJob copyWith({
    String? id,
    String? transferId,
    String? direction,
    String? peerId,
    String? peerDisplayName,
    String? status,
    Value<String?> failureCategory = const Value.absent(),
    Value<String?> failureCode = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? fileCount,
    int? totalBytes,
    int? bytesTransferred,
    int? totalChunks,
    int? completedChunks,
    int? retryCount,
    double? lossRate,
    double? throughputBytesPerSec,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransferHistoryJob(
    id: id ?? this.id,
    transferId: transferId ?? this.transferId,
    direction: direction ?? this.direction,
    peerId: peerId ?? this.peerId,
    peerDisplayName: peerDisplayName ?? this.peerDisplayName,
    status: status ?? this.status,
    failureCategory: failureCategory.present
        ? failureCategory.value
        : this.failureCategory,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    message: message.present ? message.value : this.message,
    fileCount: fileCount ?? this.fileCount,
    totalBytes: totalBytes ?? this.totalBytes,
    bytesTransferred: bytesTransferred ?? this.bytesTransferred,
    totalChunks: totalChunks ?? this.totalChunks,
    completedChunks: completedChunks ?? this.completedChunks,
    retryCount: retryCount ?? this.retryCount,
    lossRate: lossRate ?? this.lossRate,
    throughputBytesPerSec: throughputBytesPerSec ?? this.throughputBytesPerSec,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransferHistoryJob copyWithCompanion(TransferHistoryJobsCompanion data) {
    return TransferHistoryJob(
      id: data.id.present ? data.id.value : this.id,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      direction: data.direction.present ? data.direction.value : this.direction,
      peerId: data.peerId.present ? data.peerId.value : this.peerId,
      peerDisplayName: data.peerDisplayName.present
          ? data.peerDisplayName.value
          : this.peerDisplayName,
      status: data.status.present ? data.status.value : this.status,
      failureCategory: data.failureCategory.present
          ? data.failureCategory.value
          : this.failureCategory,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      message: data.message.present ? data.message.value : this.message,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      bytesTransferred: data.bytesTransferred.present
          ? data.bytesTransferred.value
          : this.bytesTransferred,
      totalChunks: data.totalChunks.present
          ? data.totalChunks.value
          : this.totalChunks,
      completedChunks: data.completedChunks.present
          ? data.completedChunks.value
          : this.completedChunks,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lossRate: data.lossRate.present ? data.lossRate.value : this.lossRate,
      throughputBytesPerSec: data.throughputBytesPerSec.present
          ? data.throughputBytesPerSec.value
          : this.throughputBytesPerSec,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryJob(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('direction: $direction, ')
          ..write('peerId: $peerId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('status: $status, ')
          ..write('failureCategory: $failureCategory, ')
          ..write('failureCode: $failureCode, ')
          ..write('message: $message, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('completedChunks: $completedChunks, ')
          ..write('retryCount: $retryCount, ')
          ..write('lossRate: $lossRate, ')
          ..write('throughputBytesPerSec: $throughputBytesPerSec, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transferId,
    direction,
    peerId,
    peerDisplayName,
    status,
    failureCategory,
    failureCode,
    message,
    fileCount,
    totalBytes,
    bytesTransferred,
    totalChunks,
    completedChunks,
    retryCount,
    lossRate,
    throughputBytesPerSec,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryJob &&
          other.id == this.id &&
          other.transferId == this.transferId &&
          other.direction == this.direction &&
          other.peerId == this.peerId &&
          other.peerDisplayName == this.peerDisplayName &&
          other.status == this.status &&
          other.failureCategory == this.failureCategory &&
          other.failureCode == this.failureCode &&
          other.message == this.message &&
          other.fileCount == this.fileCount &&
          other.totalBytes == this.totalBytes &&
          other.bytesTransferred == this.bytesTransferred &&
          other.totalChunks == this.totalChunks &&
          other.completedChunks == this.completedChunks &&
          other.retryCount == this.retryCount &&
          other.lossRate == this.lossRate &&
          other.throughputBytesPerSec == this.throughputBytesPerSec &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransferHistoryJobsCompanion extends UpdateCompanion<TransferHistoryJob> {
  final Value<String> id;
  final Value<String> transferId;
  final Value<String> direction;
  final Value<String> peerId;
  final Value<String> peerDisplayName;
  final Value<String> status;
  final Value<String?> failureCategory;
  final Value<String?> failureCode;
  final Value<String?> message;
  final Value<int> fileCount;
  final Value<int> totalBytes;
  final Value<int> bytesTransferred;
  final Value<int> totalChunks;
  final Value<int> completedChunks;
  final Value<int> retryCount;
  final Value<double> lossRate;
  final Value<double> throughputBytesPerSec;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransferHistoryJobsCompanion({
    this.id = const Value.absent(),
    this.transferId = const Value.absent(),
    this.direction = const Value.absent(),
    this.peerId = const Value.absent(),
    this.peerDisplayName = const Value.absent(),
    this.status = const Value.absent(),
    this.failureCategory = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.message = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.bytesTransferred = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.completedChunks = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lossRate = const Value.absent(),
    this.throughputBytesPerSec = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferHistoryJobsCompanion.insert({
    required String id,
    required String transferId,
    required String direction,
    required String peerId,
    required String peerDisplayName,
    required String status,
    this.failureCategory = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.message = const Value.absent(),
    this.fileCount = const Value.absent(),
    required int totalBytes,
    required int bytesTransferred,
    required int totalChunks,
    required int completedChunks,
    this.retryCount = const Value.absent(),
    this.lossRate = const Value.absent(),
    this.throughputBytesPerSec = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transferId = Value(transferId),
       direction = Value(direction),
       peerId = Value(peerId),
       peerDisplayName = Value(peerDisplayName),
       status = Value(status),
       totalBytes = Value(totalBytes),
       bytesTransferred = Value(bytesTransferred),
       totalChunks = Value(totalChunks),
       completedChunks = Value(completedChunks),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransferHistoryJob> custom({
    Expression<String>? id,
    Expression<String>? transferId,
    Expression<String>? direction,
    Expression<String>? peerId,
    Expression<String>? peerDisplayName,
    Expression<String>? status,
    Expression<String>? failureCategory,
    Expression<String>? failureCode,
    Expression<String>? message,
    Expression<int>? fileCount,
    Expression<int>? totalBytes,
    Expression<int>? bytesTransferred,
    Expression<int>? totalChunks,
    Expression<int>? completedChunks,
    Expression<int>? retryCount,
    Expression<double>? lossRate,
    Expression<double>? throughputBytesPerSec,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transferId != null) 'transfer_id': transferId,
      if (direction != null) 'direction': direction,
      if (peerId != null) 'peer_id': peerId,
      if (peerDisplayName != null) 'peer_display_name': peerDisplayName,
      if (status != null) 'status': status,
      if (failureCategory != null) 'failure_category': failureCategory,
      if (failureCode != null) 'failure_code': failureCode,
      if (message != null) 'message': message,
      if (fileCount != null) 'file_count': fileCount,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (bytesTransferred != null) 'bytes_transferred': bytesTransferred,
      if (totalChunks != null) 'total_chunks': totalChunks,
      if (completedChunks != null) 'completed_chunks': completedChunks,
      if (retryCount != null) 'retry_count': retryCount,
      if (lossRate != null) 'loss_rate': lossRate,
      if (throughputBytesPerSec != null)
        'throughput_bytes_per_sec': throughputBytesPerSec,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferHistoryJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? transferId,
    Value<String>? direction,
    Value<String>? peerId,
    Value<String>? peerDisplayName,
    Value<String>? status,
    Value<String?>? failureCategory,
    Value<String?>? failureCode,
    Value<String?>? message,
    Value<int>? fileCount,
    Value<int>? totalBytes,
    Value<int>? bytesTransferred,
    Value<int>? totalChunks,
    Value<int>? completedChunks,
    Value<int>? retryCount,
    Value<double>? lossRate,
    Value<double>? throughputBytesPerSec,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransferHistoryJobsCompanion(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      peerId: peerId ?? this.peerId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      status: status ?? this.status,
      failureCategory: failureCategory ?? this.failureCategory,
      failureCode: failureCode ?? this.failureCode,
      message: message ?? this.message,
      fileCount: fileCount ?? this.fileCount,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalChunks: totalChunks ?? this.totalChunks,
      completedChunks: completedChunks ?? this.completedChunks,
      retryCount: retryCount ?? this.retryCount,
      lossRate: lossRate ?? this.lossRate,
      throughputBytesPerSec:
          throughputBytesPerSec ?? this.throughputBytesPerSec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (peerId.present) {
      map['peer_id'] = Variable<String>(peerId.value);
    }
    if (peerDisplayName.present) {
      map['peer_display_name'] = Variable<String>(peerDisplayName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (failureCategory.present) {
      map['failure_category'] = Variable<String>(failureCategory.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (bytesTransferred.present) {
      map['bytes_transferred'] = Variable<int>(bytesTransferred.value);
    }
    if (totalChunks.present) {
      map['total_chunks'] = Variable<int>(totalChunks.value);
    }
    if (completedChunks.present) {
      map['completed_chunks'] = Variable<int>(completedChunks.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lossRate.present) {
      map['loss_rate'] = Variable<double>(lossRate.value);
    }
    if (throughputBytesPerSec.present) {
      map['throughput_bytes_per_sec'] = Variable<double>(
        throughputBytesPerSec.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryJobsCompanion(')
          ..write('id: $id, ')
          ..write('transferId: $transferId, ')
          ..write('direction: $direction, ')
          ..write('peerId: $peerId, ')
          ..write('peerDisplayName: $peerDisplayName, ')
          ..write('status: $status, ')
          ..write('failureCategory: $failureCategory, ')
          ..write('failureCode: $failureCode, ')
          ..write('message: $message, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('completedChunks: $completedChunks, ')
          ..write('retryCount: $retryCount, ')
          ..write('lossRate: $lossRate, ')
          ..write('throughputBytesPerSec: $throughputBytesPerSec, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransferHistoryFilesTable extends TransferHistoryFiles
    with TableInfo<$TransferHistoryFilesTable, TransferHistoryFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransferHistoryFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferIdMeta = const VerificationMeta(
    'transferId',
  );
  @override
  late final GeneratedColumn<String> transferId = GeneratedColumn<String>(
    'transfer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _destinationPathMeta = const VerificationMeta(
    'destinationPath',
  );
  @override
  late final GeneratedColumn<String> destinationPath = GeneratedColumn<String>(
    'destination_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    transferId,
    fileName,
    fileSize,
    localPath,
    destinationPath,
    sha256,
    status,
    message,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfer_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransferHistoryFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('transfer_id')) {
      context.handle(
        _transferIdMeta,
        transferId.isAcceptableOrUnknown(data['transfer_id']!, _transferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transferIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('destination_path')) {
      context.handle(
        _destinationPathMeta,
        destinationPath.isAcceptableOrUnknown(
          data['destination_path']!,
          _destinationPathMeta,
        ),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransferHistoryFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransferHistoryFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      transferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      destinationPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_path'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransferHistoryFilesTable createAlias(String alias) {
    return $TransferHistoryFilesTable(attachedDatabase, alias);
  }
}

class TransferHistoryFile extends DataClass
    implements Insertable<TransferHistoryFile> {
  final String id;
  final String jobId;
  final String transferId;
  final String fileName;
  final int fileSize;
  final String? localPath;
  final String? destinationPath;
  final String? sha256;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TransferHistoryFile({
    required this.id,
    required this.jobId,
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    this.localPath,
    this.destinationPath,
    this.sha256,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['transfer_id'] = Variable<String>(transferId);
    map['file_name'] = Variable<String>(fileName);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || destinationPath != null) {
      map['destination_path'] = Variable<String>(destinationPath);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransferHistoryFilesCompanion toCompanion(bool nullToAbsent) {
    return TransferHistoryFilesCompanion(
      id: Value(id),
      jobId: Value(jobId),
      transferId: Value(transferId),
      fileName: Value(fileName),
      fileSize: Value(fileSize),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      destinationPath: destinationPath == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationPath),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      status: Value(status),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TransferHistoryFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransferHistoryFile(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      transferId: serializer.fromJson<String>(json['transferId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      destinationPath: serializer.fromJson<String?>(json['destinationPath']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      status: serializer.fromJson<String>(json['status']),
      message: serializer.fromJson<String?>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'transferId': serializer.toJson<String>(transferId),
      'fileName': serializer.toJson<String>(fileName),
      'fileSize': serializer.toJson<int>(fileSize),
      'localPath': serializer.toJson<String?>(localPath),
      'destinationPath': serializer.toJson<String?>(destinationPath),
      'sha256': serializer.toJson<String?>(sha256),
      'status': serializer.toJson<String>(status),
      'message': serializer.toJson<String?>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TransferHistoryFile copyWith({
    String? id,
    String? jobId,
    String? transferId,
    String? fileName,
    int? fileSize,
    Value<String?> localPath = const Value.absent(),
    Value<String?> destinationPath = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    String? status,
    Value<String?> message = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TransferHistoryFile(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    transferId: transferId ?? this.transferId,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    localPath: localPath.present ? localPath.value : this.localPath,
    destinationPath: destinationPath.present
        ? destinationPath.value
        : this.destinationPath,
    sha256: sha256.present ? sha256.value : this.sha256,
    status: status ?? this.status,
    message: message.present ? message.value : this.message,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TransferHistoryFile copyWithCompanion(TransferHistoryFilesCompanion data) {
    return TransferHistoryFile(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      transferId: data.transferId.present
          ? data.transferId.value
          : this.transferId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      destinationPath: data.destinationPath.present
          ? data.destinationPath.value
          : this.destinationPath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      status: data.status.present ? data.status.value : this.status,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryFile(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('transferId: $transferId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('sha256: $sha256, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    transferId,
    fileName,
    fileSize,
    localPath,
    destinationPath,
    sha256,
    status,
    message,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransferHistoryFile &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.transferId == this.transferId &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.localPath == this.localPath &&
          other.destinationPath == this.destinationPath &&
          other.sha256 == this.sha256 &&
          other.status == this.status &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransferHistoryFilesCompanion
    extends UpdateCompanion<TransferHistoryFile> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> transferId;
  final Value<String> fileName;
  final Value<int> fileSize;
  final Value<String?> localPath;
  final Value<String?> destinationPath;
  final Value<String?> sha256;
  final Value<String> status;
  final Value<String?> message;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TransferHistoryFilesCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.transferId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.localPath = const Value.absent(),
    this.destinationPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.status = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransferHistoryFilesCompanion.insert({
    required String id,
    required String jobId,
    required String transferId,
    required String fileName,
    required int fileSize,
    this.localPath = const Value.absent(),
    this.destinationPath = const Value.absent(),
    this.sha256 = const Value.absent(),
    required String status,
    this.message = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jobId = Value(jobId),
       transferId = Value(transferId),
       fileName = Value(fileName),
       fileSize = Value(fileSize),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransferHistoryFile> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? transferId,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? localPath,
    Expression<String>? destinationPath,
    Expression<String>? sha256,
    Expression<String>? status,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (transferId != null) 'transfer_id': transferId,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (localPath != null) 'local_path': localPath,
      if (destinationPath != null) 'destination_path': destinationPath,
      if (sha256 != null) 'sha256': sha256,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransferHistoryFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? jobId,
    Value<String>? transferId,
    Value<String>? fileName,
    Value<int>? fileSize,
    Value<String?>? localPath,
    Value<String?>? destinationPath,
    Value<String?>? sha256,
    Value<String>? status,
    Value<String?>? message,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransferHistoryFilesCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      transferId: transferId ?? this.transferId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      localPath: localPath ?? this.localPath,
      destinationPath: destinationPath ?? this.destinationPath,
      sha256: sha256 ?? this.sha256,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (transferId.present) {
      map['transfer_id'] = Variable<String>(transferId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (destinationPath.present) {
      map['destination_path'] = Variable<String>(destinationPath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransferHistoryFilesCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('transferId: $transferId, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('localPath: $localPath, ')
          ..write('destinationPath: $destinationPath, ')
          ..write('sha256: $sha256, ')
          ..write('status: $status, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PeersTable peers = $PeersTable(this);
  late final $AllowedPeersTable allowedPeers = $AllowedPeersTable(this);
  late final $TransferHistoryJobsTable transferHistoryJobs =
      $TransferHistoryJobsTable(this);
  late final $TransferHistoryFilesTable transferHistoryFiles =
      $TransferHistoryFilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    settings,
    peers,
    allowedPeers,
    transferHistoryJobs,
    transferHistoryFiles,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String userId,
      required String displayName,
      required String deviceName,
      required String passwordHash,
      required String passwordSalt,
      required String hashAlgorithm,
      required String hashParams,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> displayName,
      Value<String> deviceName,
      Value<String> passwordHash,
      Value<String> passwordSalt,
      Value<String> hashAlgorithm,
      Value<String> hashParams,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashAlgorithm => $composableBuilder(
    column: $table.hashAlgorithm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashParams => $composableBuilder(
    column: $table.hashParams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashAlgorithm => $composableBuilder(
    column: $table.hashAlgorithm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashParams => $composableBuilder(
    column: $table.hashParams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hashAlgorithm => $composableBuilder(
    column: $table.hashAlgorithm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hashParams => $composableBuilder(
    column: $table.hashParams,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> passwordSalt = const Value.absent(),
                Value<String> hashAlgorithm = const Value.absent(),
                Value<String> hashParams = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                userId: userId,
                displayName: displayName,
                deviceName: deviceName,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                hashAlgorithm: hashAlgorithm,
                hashParams: hashParams,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String displayName,
                required String deviceName,
                required String passwordHash,
                required String passwordSalt,
                required String hashAlgorithm,
                required String hashParams,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => UsersCompanion.insert(
                id: id,
                userId: userId,
                displayName: displayName,
                deviceName: deviceName,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                hashAlgorithm: hashAlgorithm,
                hashParams: hashParams,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      required String defaultSavePath,
      Value<bool> autoReceiveEnabled,
      required String receivePolicy,
      required String logLevel,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String> defaultSavePath,
      Value<bool> autoReceiveEnabled,
      Value<String> receivePolicy,
      Value<String> logLevel,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSavePath => $composableBuilder(
    column: $table.defaultSavePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoReceiveEnabled => $composableBuilder(
    column: $table.autoReceiveEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receivePolicy => $composableBuilder(
    column: $table.receivePolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logLevel => $composableBuilder(
    column: $table.logLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSavePath => $composableBuilder(
    column: $table.defaultSavePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoReceiveEnabled => $composableBuilder(
    column: $table.autoReceiveEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receivePolicy => $composableBuilder(
    column: $table.receivePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logLevel => $composableBuilder(
    column: $table.logLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get defaultSavePath => $composableBuilder(
    column: $table.defaultSavePath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoReceiveEnabled => $composableBuilder(
    column: $table.autoReceiveEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receivePolicy => $composableBuilder(
    column: $table.receivePolicy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logLevel =>
      $composableBuilder(column: $table.logLevel, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> defaultSavePath = const Value.absent(),
                Value<bool> autoReceiveEnabled = const Value.absent(),
                Value<String> receivePolicy = const Value.absent(),
                Value<String> logLevel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                defaultSavePath: defaultSavePath,
                autoReceiveEnabled: autoReceiveEnabled,
                receivePolicy: receivePolicy,
                logLevel: logLevel,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String defaultSavePath,
                Value<bool> autoReceiveEnabled = const Value.absent(),
                required String receivePolicy,
                required String logLevel,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SettingsCompanion.insert(
                id: id,
                defaultSavePath: defaultSavePath,
                autoReceiveEnabled: autoReceiveEnabled,
                receivePolicy: receivePolicy,
                logLevel: logLevel,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$PeersTableCreateCompanionBuilder =
    PeersCompanion Function({
      Value<int> id,
      required String peerUserId,
      required String peerDeviceId,
      required String peerDisplayName,
      required String peerDeviceName,
      required String osType,
      required String lastIp,
      required int lastPort,
      required String protocolVersion,
      Value<bool> receiveAvailable,
      required DateTime lastSeenAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PeersTableUpdateCompanionBuilder =
    PeersCompanion Function({
      Value<int> id,
      Value<String> peerUserId,
      Value<String> peerDeviceId,
      Value<String> peerDisplayName,
      Value<String> peerDeviceName,
      Value<String> osType,
      Value<String> lastIp,
      Value<int> lastPort,
      Value<String> protocolVersion,
      Value<bool> receiveAvailable,
      Value<DateTime> lastSeenAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PeersTableFilterComposer extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDeviceName => $composableBuilder(
    column: $table.peerDeviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osType => $composableBuilder(
    column: $table.osType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastIp => $composableBuilder(
    column: $table.lastIp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPort => $composableBuilder(
    column: $table.lastPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get receiveAvailable => $composableBuilder(
    column: $table.receiveAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeersTableOrderingComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerDeviceName => $composableBuilder(
    column: $table.peerDeviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osType => $composableBuilder(
    column: $table.osType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastIp => $composableBuilder(
    column: $table.lastIp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPort => $composableBuilder(
    column: $table.lastPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get receiveAvailable => $composableBuilder(
    column: $table.receiveAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerDeviceId => $composableBuilder(
    column: $table.peerDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerDeviceName => $composableBuilder(
    column: $table.peerDeviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get osType =>
      $composableBuilder(column: $table.osType, builder: (column) => column);

  GeneratedColumn<String> get lastIp =>
      $composableBuilder(column: $table.lastIp, builder: (column) => column);

  GeneratedColumn<int> get lastPort =>
      $composableBuilder(column: $table.lastPort, builder: (column) => column);

  GeneratedColumn<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get receiveAvailable => $composableBuilder(
    column: $table.receiveAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PeersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeersTable,
          Peer,
          $$PeersTableFilterComposer,
          $$PeersTableOrderingComposer,
          $$PeersTableAnnotationComposer,
          $$PeersTableCreateCompanionBuilder,
          $$PeersTableUpdateCompanionBuilder,
          (Peer, BaseReferences<_$AppDatabase, $PeersTable, Peer>),
          Peer,
          PrefetchHooks Function()
        > {
  $$PeersTableTableManager(_$AppDatabase db, $PeersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> peerUserId = const Value.absent(),
                Value<String> peerDeviceId = const Value.absent(),
                Value<String> peerDisplayName = const Value.absent(),
                Value<String> peerDeviceName = const Value.absent(),
                Value<String> osType = const Value.absent(),
                Value<String> lastIp = const Value.absent(),
                Value<int> lastPort = const Value.absent(),
                Value<String> protocolVersion = const Value.absent(),
                Value<bool> receiveAvailable = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PeersCompanion(
                id: id,
                peerUserId: peerUserId,
                peerDeviceId: peerDeviceId,
                peerDisplayName: peerDisplayName,
                peerDeviceName: peerDeviceName,
                osType: osType,
                lastIp: lastIp,
                lastPort: lastPort,
                protocolVersion: protocolVersion,
                receiveAvailable: receiveAvailable,
                lastSeenAt: lastSeenAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String peerUserId,
                required String peerDeviceId,
                required String peerDisplayName,
                required String peerDeviceName,
                required String osType,
                required String lastIp,
                required int lastPort,
                required String protocolVersion,
                Value<bool> receiveAvailable = const Value.absent(),
                required DateTime lastSeenAt,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PeersCompanion.insert(
                id: id,
                peerUserId: peerUserId,
                peerDeviceId: peerDeviceId,
                peerDisplayName: peerDisplayName,
                peerDeviceName: peerDeviceName,
                osType: osType,
                lastIp: lastIp,
                lastPort: lastPort,
                protocolVersion: protocolVersion,
                receiveAvailable: receiveAvailable,
                lastSeenAt: lastSeenAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeersTable,
      Peer,
      $$PeersTableFilterComposer,
      $$PeersTableOrderingComposer,
      $$PeersTableAnnotationComposer,
      $$PeersTableCreateCompanionBuilder,
      $$PeersTableUpdateCompanionBuilder,
      (Peer, BaseReferences<_$AppDatabase, $PeersTable, Peer>),
      Peer,
      PrefetchHooks Function()
    >;
typedef $$AllowedPeersTableCreateCompanionBuilder =
    AllowedPeersCompanion Function({
      Value<int> id,
      required String peerUserId,
      required String label,
      required String verifierBase64,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$AllowedPeersTableUpdateCompanionBuilder =
    AllowedPeersCompanion Function({
      Value<int> id,
      Value<String> peerUserId,
      Value<String> label,
      Value<String> verifierBase64,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$AllowedPeersTableFilterComposer
    extends Composer<_$AppDatabase, $AllowedPeersTable> {
  $$AllowedPeersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifierBase64 => $composableBuilder(
    column: $table.verifierBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AllowedPeersTableOrderingComposer
    extends Composer<_$AppDatabase, $AllowedPeersTable> {
  $$AllowedPeersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifierBase64 => $composableBuilder(
    column: $table.verifierBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AllowedPeersTableAnnotationComposer
    extends Composer<_$AppDatabase, $AllowedPeersTable> {
  $$AllowedPeersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get verifierBase64 => $composableBuilder(
    column: $table.verifierBase64,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AllowedPeersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AllowedPeersTable,
          AllowedPeer,
          $$AllowedPeersTableFilterComposer,
          $$AllowedPeersTableOrderingComposer,
          $$AllowedPeersTableAnnotationComposer,
          $$AllowedPeersTableCreateCompanionBuilder,
          $$AllowedPeersTableUpdateCompanionBuilder,
          (
            AllowedPeer,
            BaseReferences<_$AppDatabase, $AllowedPeersTable, AllowedPeer>,
          ),
          AllowedPeer,
          PrefetchHooks Function()
        > {
  $$AllowedPeersTableTableManager(_$AppDatabase db, $AllowedPeersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AllowedPeersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AllowedPeersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AllowedPeersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> peerUserId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> verifierBase64 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AllowedPeersCompanion(
                id: id,
                peerUserId: peerUserId,
                label: label,
                verifierBase64: verifierBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String peerUserId,
                required String label,
                required String verifierBase64,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => AllowedPeersCompanion.insert(
                id: id,
                peerUserId: peerUserId,
                label: label,
                verifierBase64: verifierBase64,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AllowedPeersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AllowedPeersTable,
      AllowedPeer,
      $$AllowedPeersTableFilterComposer,
      $$AllowedPeersTableOrderingComposer,
      $$AllowedPeersTableAnnotationComposer,
      $$AllowedPeersTableCreateCompanionBuilder,
      $$AllowedPeersTableUpdateCompanionBuilder,
      (
        AllowedPeer,
        BaseReferences<_$AppDatabase, $AllowedPeersTable, AllowedPeer>,
      ),
      AllowedPeer,
      PrefetchHooks Function()
    >;
typedef $$TransferHistoryJobsTableCreateCompanionBuilder =
    TransferHistoryJobsCompanion Function({
      required String id,
      required String transferId,
      required String direction,
      required String peerId,
      required String peerDisplayName,
      required String status,
      Value<String?> failureCategory,
      Value<String?> failureCode,
      Value<String?> message,
      Value<int> fileCount,
      required int totalBytes,
      required int bytesTransferred,
      required int totalChunks,
      required int completedChunks,
      Value<int> retryCount,
      Value<double> lossRate,
      Value<double> throughputBytesPerSec,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TransferHistoryJobsTableUpdateCompanionBuilder =
    TransferHistoryJobsCompanion Function({
      Value<String> id,
      Value<String> transferId,
      Value<String> direction,
      Value<String> peerId,
      Value<String> peerDisplayName,
      Value<String> status,
      Value<String?> failureCategory,
      Value<String?> failureCode,
      Value<String?> message,
      Value<int> fileCount,
      Value<int> totalBytes,
      Value<int> bytesTransferred,
      Value<int> totalChunks,
      Value<int> completedChunks,
      Value<int> retryCount,
      Value<double> lossRate,
      Value<double> throughputBytesPerSec,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransferHistoryJobsTableFilterComposer
    extends Composer<_$AppDatabase, $TransferHistoryJobsTable> {
  $$TransferHistoryJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCategory => $composableBuilder(
    column: $table.failureCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedChunks => $composableBuilder(
    column: $table.completedChunks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lossRate => $composableBuilder(
    column: $table.lossRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get throughputBytesPerSec => $composableBuilder(
    column: $table.throughputBytesPerSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferHistoryJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferHistoryJobsTable> {
  $$TransferHistoryJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerId => $composableBuilder(
    column: $table.peerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCategory => $composableBuilder(
    column: $table.failureCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedChunks => $composableBuilder(
    column: $table.completedChunks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lossRate => $composableBuilder(
    column: $table.lossRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get throughputBytesPerSec => $composableBuilder(
    column: $table.throughputBytesPerSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferHistoryJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferHistoryJobsTable> {
  $$TransferHistoryJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get peerId =>
      $composableBuilder(column: $table.peerId, builder: (column) => column);

  GeneratedColumn<String> get peerDisplayName => $composableBuilder(
    column: $table.peerDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failureCategory => $composableBuilder(
    column: $table.failureCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedChunks => $composableBuilder(
    column: $table.completedChunks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lossRate =>
      $composableBuilder(column: $table.lossRate, builder: (column) => column);

  GeneratedColumn<double> get throughputBytesPerSec => $composableBuilder(
    column: $table.throughputBytesPerSec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransferHistoryJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferHistoryJobsTable,
          TransferHistoryJob,
          $$TransferHistoryJobsTableFilterComposer,
          $$TransferHistoryJobsTableOrderingComposer,
          $$TransferHistoryJobsTableAnnotationComposer,
          $$TransferHistoryJobsTableCreateCompanionBuilder,
          $$TransferHistoryJobsTableUpdateCompanionBuilder,
          (
            TransferHistoryJob,
            BaseReferences<
              _$AppDatabase,
              $TransferHistoryJobsTable,
              TransferHistoryJob
            >,
          ),
          TransferHistoryJob,
          PrefetchHooks Function()
        > {
  $$TransferHistoryJobsTableTableManager(
    _$AppDatabase db,
    $TransferHistoryJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferHistoryJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferHistoryJobsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransferHistoryJobsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transferId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> peerId = const Value.absent(),
                Value<String> peerDisplayName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> failureCategory = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> fileCount = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> bytesTransferred = const Value.absent(),
                Value<int> totalChunks = const Value.absent(),
                Value<int> completedChunks = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<double> lossRate = const Value.absent(),
                Value<double> throughputBytesPerSec = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferHistoryJobsCompanion(
                id: id,
                transferId: transferId,
                direction: direction,
                peerId: peerId,
                peerDisplayName: peerDisplayName,
                status: status,
                failureCategory: failureCategory,
                failureCode: failureCode,
                message: message,
                fileCount: fileCount,
                totalBytes: totalBytes,
                bytesTransferred: bytesTransferred,
                totalChunks: totalChunks,
                completedChunks: completedChunks,
                retryCount: retryCount,
                lossRate: lossRate,
                throughputBytesPerSec: throughputBytesPerSec,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transferId,
                required String direction,
                required String peerId,
                required String peerDisplayName,
                required String status,
                Value<String?> failureCategory = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> fileCount = const Value.absent(),
                required int totalBytes,
                required int bytesTransferred,
                required int totalChunks,
                required int completedChunks,
                Value<int> retryCount = const Value.absent(),
                Value<double> lossRate = const Value.absent(),
                Value<double> throughputBytesPerSec = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransferHistoryJobsCompanion.insert(
                id: id,
                transferId: transferId,
                direction: direction,
                peerId: peerId,
                peerDisplayName: peerDisplayName,
                status: status,
                failureCategory: failureCategory,
                failureCode: failureCode,
                message: message,
                fileCount: fileCount,
                totalBytes: totalBytes,
                bytesTransferred: bytesTransferred,
                totalChunks: totalChunks,
                completedChunks: completedChunks,
                retryCount: retryCount,
                lossRate: lossRate,
                throughputBytesPerSec: throughputBytesPerSec,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferHistoryJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferHistoryJobsTable,
      TransferHistoryJob,
      $$TransferHistoryJobsTableFilterComposer,
      $$TransferHistoryJobsTableOrderingComposer,
      $$TransferHistoryJobsTableAnnotationComposer,
      $$TransferHistoryJobsTableCreateCompanionBuilder,
      $$TransferHistoryJobsTableUpdateCompanionBuilder,
      (
        TransferHistoryJob,
        BaseReferences<
          _$AppDatabase,
          $TransferHistoryJobsTable,
          TransferHistoryJob
        >,
      ),
      TransferHistoryJob,
      PrefetchHooks Function()
    >;
typedef $$TransferHistoryFilesTableCreateCompanionBuilder =
    TransferHistoryFilesCompanion Function({
      required String id,
      required String jobId,
      required String transferId,
      required String fileName,
      required int fileSize,
      Value<String?> localPath,
      Value<String?> destinationPath,
      Value<String?> sha256,
      required String status,
      Value<String?> message,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TransferHistoryFilesTableUpdateCompanionBuilder =
    TransferHistoryFilesCompanion Function({
      Value<String> id,
      Value<String> jobId,
      Value<String> transferId,
      Value<String> fileName,
      Value<int> fileSize,
      Value<String?> localPath,
      Value<String?> destinationPath,
      Value<String?> sha256,
      Value<String> status,
      Value<String?> message,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TransferHistoryFilesTableFilterComposer
    extends Composer<_$AppDatabase, $TransferHistoryFilesTable> {
  $$TransferHistoryFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransferHistoryFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransferHistoryFilesTable> {
  $$TransferHistoryFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransferHistoryFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransferHistoryFilesTable> {
  $$TransferHistoryFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get transferId => $composableBuilder(
    column: $table.transferId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get destinationPath => $composableBuilder(
    column: $table.destinationPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransferHistoryFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransferHistoryFilesTable,
          TransferHistoryFile,
          $$TransferHistoryFilesTableFilterComposer,
          $$TransferHistoryFilesTableOrderingComposer,
          $$TransferHistoryFilesTableAnnotationComposer,
          $$TransferHistoryFilesTableCreateCompanionBuilder,
          $$TransferHistoryFilesTableUpdateCompanionBuilder,
          (
            TransferHistoryFile,
            BaseReferences<
              _$AppDatabase,
              $TransferHistoryFilesTable,
              TransferHistoryFile
            >,
          ),
          TransferHistoryFile,
          PrefetchHooks Function()
        > {
  $$TransferHistoryFilesTableTableManager(
    _$AppDatabase db,
    $TransferHistoryFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransferHistoryFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransferHistoryFilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransferHistoryFilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String> transferId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> destinationPath = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransferHistoryFilesCompanion(
                id: id,
                jobId: jobId,
                transferId: transferId,
                fileName: fileName,
                fileSize: fileSize,
                localPath: localPath,
                destinationPath: destinationPath,
                sha256: sha256,
                status: status,
                message: message,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String jobId,
                required String transferId,
                required String fileName,
                required int fileSize,
                Value<String?> localPath = const Value.absent(),
                Value<String?> destinationPath = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                required String status,
                Value<String?> message = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransferHistoryFilesCompanion.insert(
                id: id,
                jobId: jobId,
                transferId: transferId,
                fileName: fileName,
                fileSize: fileSize,
                localPath: localPath,
                destinationPath: destinationPath,
                sha256: sha256,
                status: status,
                message: message,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransferHistoryFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransferHistoryFilesTable,
      TransferHistoryFile,
      $$TransferHistoryFilesTableFilterComposer,
      $$TransferHistoryFilesTableOrderingComposer,
      $$TransferHistoryFilesTableAnnotationComposer,
      $$TransferHistoryFilesTableCreateCompanionBuilder,
      $$TransferHistoryFilesTableUpdateCompanionBuilder,
      (
        TransferHistoryFile,
        BaseReferences<
          _$AppDatabase,
          $TransferHistoryFilesTable,
          TransferHistoryFile
        >,
      ),
      TransferHistoryFile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PeersTableTableManager get peers =>
      $$PeersTableTableManager(_db, _db.peers);
  $$AllowedPeersTableTableManager get allowedPeers =>
      $$AllowedPeersTableTableManager(_db, _db.allowedPeers);
  $$TransferHistoryJobsTableTableManager get transferHistoryJobs =>
      $$TransferHistoryJobsTableTableManager(_db, _db.transferHistoryJobs);
  $$TransferHistoryFilesTableTableManager get transferHistoryFiles =>
      $$TransferHistoryFilesTableTableManager(_db, _db.transferHistoryFiles);
}
