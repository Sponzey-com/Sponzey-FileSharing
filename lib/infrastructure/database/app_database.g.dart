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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PeersTable peers = $PeersTable(this);
  late final $AllowedPeersTable allowedPeers = $AllowedPeersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    settings,
    peers,
    allowedPeers,
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
}
