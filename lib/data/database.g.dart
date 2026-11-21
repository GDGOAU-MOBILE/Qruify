// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QrCodesTable extends QrCodes with TableInfo<$QrCodesTable, QrCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QrCodesTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<QrType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<QrType>($QrCodesTable.$convertertype);
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _foregroundColorMeta = const VerificationMeta(
    'foregroundColor',
  );
  @override
  late final GeneratedColumn<int> foregroundColor = GeneratedColumn<int>(
    'foreground_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF000000),
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<int> backgroundColor = GeneratedColumn<int>(
    'background_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFFFFFFFF),
  );
  @override
  late final GeneratedColumnWithTypeConverter<QrErrorLevel, int> errorLevel =
      GeneratedColumn<int>(
        'error_level',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<QrErrorLevel>($QrCodesTable.$convertererrorLevel);
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<Uint8List> logo = GeneratedColumn<Uint8List>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    content,
    title,
    foregroundColor,
    backgroundColor,
    errorLevel,
    logo,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qr_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<QrCode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('foreground_color')) {
      context.handle(
        _foregroundColorMeta,
        foregroundColor.isAcceptableOrUnknown(
          data['foreground_color']!,
          _foregroundColorMeta,
        ),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QrCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QrCode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $QrCodesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      foregroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foreground_color'],
      )!,
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}background_color'],
      )!,
      errorLevel: $QrCodesTable.$convertererrorLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}error_level'],
        )!,
      ),
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}logo'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QrCodesTable createAlias(String alias) {
    return $QrCodesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<QrType, String, String> $convertertype =
      const EnumNameConverter<QrType>(QrType.values);
  static TypeConverter<QrErrorLevel, int> $convertererrorLevel =
      const _ErrorLevelConverter();
}

class QrCode extends DataClass implements Insertable<QrCode> {
  final int id;
  final QrType type;

  /// The exact string encoded in the QR code.
  final String content;

  /// Short label shown in the history list.
  final String title;

  /// Style options as ARGB ints, so a code can be redrawn the same way.
  final int foregroundColor;
  final int backgroundColor;
  final QrErrorLevel errorLevel;

  /// The logo drawn in the middle of the code, as PNG bytes. Null for none.
  final Uint8List? logo;
  final DateTime createdAt;
  const QrCode({
    required this.id,
    required this.type,
    required this.content,
    required this.title,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.errorLevel,
    this.logo,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>($QrCodesTable.$convertertype.toSql(type));
    }
    map['content'] = Variable<String>(content);
    map['title'] = Variable<String>(title);
    map['foreground_color'] = Variable<int>(foregroundColor);
    map['background_color'] = Variable<int>(backgroundColor);
    {
      map['error_level'] = Variable<int>(
        $QrCodesTable.$convertererrorLevel.toSql(errorLevel),
      );
    }
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<Uint8List>(logo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QrCodesCompanion toCompanion(bool nullToAbsent) {
    return QrCodesCompanion(
      id: Value(id),
      type: Value(type),
      content: Value(content),
      title: Value(title),
      foregroundColor: Value(foregroundColor),
      backgroundColor: Value(backgroundColor),
      errorLevel: Value(errorLevel),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      createdAt: Value(createdAt),
    );
  }

  factory QrCode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QrCode(
      id: serializer.fromJson<int>(json['id']),
      type: $QrCodesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      content: serializer.fromJson<String>(json['content']),
      title: serializer.fromJson<String>(json['title']),
      foregroundColor: serializer.fromJson<int>(json['foregroundColor']),
      backgroundColor: serializer.fromJson<int>(json['backgroundColor']),
      errorLevel: serializer.fromJson<QrErrorLevel>(json['errorLevel']),
      logo: serializer.fromJson<Uint8List?>(json['logo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $QrCodesTable.$convertertype.toJson(type),
      ),
      'content': serializer.toJson<String>(content),
      'title': serializer.toJson<String>(title),
      'foregroundColor': serializer.toJson<int>(foregroundColor),
      'backgroundColor': serializer.toJson<int>(backgroundColor),
      'errorLevel': serializer.toJson<QrErrorLevel>(errorLevel),
      'logo': serializer.toJson<Uint8List?>(logo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QrCode copyWith({
    int? id,
    QrType? type,
    String? content,
    String? title,
    int? foregroundColor,
    int? backgroundColor,
    QrErrorLevel? errorLevel,
    Value<Uint8List?> logo = const Value.absent(),
    DateTime? createdAt,
  }) => QrCode(
    id: id ?? this.id,
    type: type ?? this.type,
    content: content ?? this.content,
    title: title ?? this.title,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    errorLevel: errorLevel ?? this.errorLevel,
    logo: logo.present ? logo.value : this.logo,
    createdAt: createdAt ?? this.createdAt,
  );
  QrCode copyWithCompanion(QrCodesCompanion data) {
    return QrCode(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      title: data.title.present ? data.title.value : this.title,
      foregroundColor: data.foregroundColor.present
          ? data.foregroundColor.value
          : this.foregroundColor,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      errorLevel: data.errorLevel.present
          ? data.errorLevel.value
          : this.errorLevel,
      logo: data.logo.present ? data.logo.value : this.logo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QrCode(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('title: $title, ')
          ..write('foregroundColor: $foregroundColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('errorLevel: $errorLevel, ')
          ..write('logo: $logo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    content,
    title,
    foregroundColor,
    backgroundColor,
    errorLevel,
    $driftBlobEquality.hash(logo),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCode &&
          other.id == this.id &&
          other.type == this.type &&
          other.content == this.content &&
          other.title == this.title &&
          other.foregroundColor == this.foregroundColor &&
          other.backgroundColor == this.backgroundColor &&
          other.errorLevel == this.errorLevel &&
          $driftBlobEquality.equals(other.logo, this.logo) &&
          other.createdAt == this.createdAt);
}

class QrCodesCompanion extends UpdateCompanion<QrCode> {
  final Value<int> id;
  final Value<QrType> type;
  final Value<String> content;
  final Value<String> title;
  final Value<int> foregroundColor;
  final Value<int> backgroundColor;
  final Value<QrErrorLevel> errorLevel;
  final Value<Uint8List?> logo;
  final Value<DateTime> createdAt;
  const QrCodesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.title = const Value.absent(),
    this.foregroundColor = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.errorLevel = const Value.absent(),
    this.logo = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QrCodesCompanion.insert({
    this.id = const Value.absent(),
    required QrType type,
    required String content,
    this.title = const Value.absent(),
    this.foregroundColor = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.errorLevel = const Value.absent(),
    this.logo = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : type = Value(type),
       content = Value(content);
  static Insertable<QrCode> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? title,
    Expression<int>? foregroundColor,
    Expression<int>? backgroundColor,
    Expression<int>? errorLevel,
    Expression<Uint8List>? logo,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (title != null) 'title': title,
      if (foregroundColor != null) 'foreground_color': foregroundColor,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (errorLevel != null) 'error_level': errorLevel,
      if (logo != null) 'logo': logo,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QrCodesCompanion copyWith({
    Value<int>? id,
    Value<QrType>? type,
    Value<String>? content,
    Value<String>? title,
    Value<int>? foregroundColor,
    Value<int>? backgroundColor,
    Value<QrErrorLevel>? errorLevel,
    Value<Uint8List?>? logo,
    Value<DateTime>? createdAt,
  }) {
    return QrCodesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      errorLevel: errorLevel ?? this.errorLevel,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $QrCodesTable.$convertertype.toSql(type.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (foregroundColor.present) {
      map['foreground_color'] = Variable<int>(foregroundColor.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<int>(backgroundColor.value);
    }
    if (errorLevel.present) {
      map['error_level'] = Variable<int>(
        $QrCodesTable.$convertererrorLevel.toSql(errorLevel.value),
      );
    }
    if (logo.present) {
      map['logo'] = Variable<Uint8List>(logo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QrCodesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('title: $title, ')
          ..write('foregroundColor: $foregroundColor, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('errorLevel: $errorLevel, ')
          ..write('logo: $logo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GuestEntriesTable extends GuestEntries
    with TableInfo<$GuestEntriesTable, GuestEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuestEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCheckedInMeta = const VerificationMeta(
    'isCheckedIn',
  );
  @override
  late final GeneratedColumn<bool> isCheckedIn = GeneratedColumn<bool>(
    'is_checked_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _checkedInAtMeta = const VerificationMeta(
    'checkedInAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedInAt = GeneratedColumn<DateTime>(
    'checked_in_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    extra,
    isCheckedIn,
    checkedInAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guest_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<GuestEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('is_checked_in')) {
      context.handle(
        _isCheckedInMeta,
        isCheckedIn.isAcceptableOrUnknown(
          data['is_checked_in']!,
          _isCheckedInMeta,
        ),
      );
    }
    if (data.containsKey('checked_in_at')) {
      context.handle(
        _checkedInAtMeta,
        checkedInAt.isAcceptableOrUnknown(
          data['checked_in_at']!,
          _checkedInAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuestEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuestEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      )!,
      isCheckedIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked_in'],
      )!,
      checkedInAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_in_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GuestEntriesTable createAlias(String alias) {
    return $GuestEntriesTable(attachedDatabase, alias);
  }
}

class GuestEntry extends DataClass implements Insertable<GuestEntry> {
  final int id;

  /// The exact value to match when scanning the QR code.
  final String code;

  /// Name or label of the guest or ticket.
  final String name;

  /// Any extra details from the CSV (e.g. email, category, role).
  final String extra;

  /// Whether this entry has been approved / checked in.
  final bool isCheckedIn;

  /// The timestamp when the code was approved.
  final DateTime? checkedInAt;
  final DateTime createdAt;
  const GuestEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.extra,
    required this.isCheckedIn,
    this.checkedInAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['extra'] = Variable<String>(extra);
    map['is_checked_in'] = Variable<bool>(isCheckedIn);
    if (!nullToAbsent || checkedInAt != null) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GuestEntriesCompanion toCompanion(bool nullToAbsent) {
    return GuestEntriesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      extra: Value(extra),
      isCheckedIn: Value(isCheckedIn),
      checkedInAt: checkedInAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedInAt),
      createdAt: Value(createdAt),
    );
  }

  factory GuestEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuestEntry(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      extra: serializer.fromJson<String>(json['extra']),
      isCheckedIn: serializer.fromJson<bool>(json['isCheckedIn']),
      checkedInAt: serializer.fromJson<DateTime?>(json['checkedInAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'extra': serializer.toJson<String>(extra),
      'isCheckedIn': serializer.toJson<bool>(isCheckedIn),
      'checkedInAt': serializer.toJson<DateTime?>(checkedInAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GuestEntry copyWith({
    int? id,
    String? code,
    String? name,
    String? extra,
    bool? isCheckedIn,
    Value<DateTime?> checkedInAt = const Value.absent(),
    DateTime? createdAt,
  }) => GuestEntry(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    extra: extra ?? this.extra,
    isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    checkedInAt: checkedInAt.present ? checkedInAt.value : this.checkedInAt,
    createdAt: createdAt ?? this.createdAt,
  );
  GuestEntry copyWithCompanion(GuestEntriesCompanion data) {
    return GuestEntry(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      extra: data.extra.present ? data.extra.value : this.extra,
      isCheckedIn: data.isCheckedIn.present
          ? data.isCheckedIn.value
          : this.isCheckedIn,
      checkedInAt: data.checkedInAt.present
          ? data.checkedInAt.value
          : this.checkedInAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuestEntry(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('extra: $extra, ')
          ..write('isCheckedIn: $isCheckedIn, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, extra, isCheckedIn, checkedInAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuestEntry &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.extra == this.extra &&
          other.isCheckedIn == this.isCheckedIn &&
          other.checkedInAt == this.checkedInAt &&
          other.createdAt == this.createdAt);
}

class GuestEntriesCompanion extends UpdateCompanion<GuestEntry> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> extra;
  final Value<bool> isCheckedIn;
  final Value<DateTime?> checkedInAt;
  final Value<DateTime> createdAt;
  const GuestEntriesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.extra = const Value.absent(),
    this.isCheckedIn = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GuestEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    this.name = const Value.absent(),
    this.extra = const Value.absent(),
    this.isCheckedIn = const Value.absent(),
    this.checkedInAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : code = Value(code);
  static Insertable<GuestEntry> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? extra,
    Expression<bool>? isCheckedIn,
    Expression<DateTime>? checkedInAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (extra != null) 'extra': extra,
      if (isCheckedIn != null) 'is_checked_in': isCheckedIn,
      if (checkedInAt != null) 'checked_in_at': checkedInAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GuestEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? extra,
    Value<bool>? isCheckedIn,
    Value<DateTime?>? checkedInAt,
    Value<DateTime>? createdAt,
  }) {
    return GuestEntriesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      extra: extra ?? this.extra,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (isCheckedIn.present) {
      map['is_checked_in'] = Variable<bool>(isCheckedIn.value);
    }
    if (checkedInAt.present) {
      map['checked_in_at'] = Variable<DateTime>(checkedInAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuestEntriesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('extra: $extra, ')
          ..write('isCheckedIn: $isCheckedIn, ')
          ..write('checkedInAt: $checkedInAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QrCodesTable qrCodes = $QrCodesTable(this);
  late final $GuestEntriesTable guestEntries = $GuestEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [qrCodes, guestEntries];
}

typedef $$QrCodesTableCreateCompanionBuilder =
    QrCodesCompanion Function({
      Value<int> id,
      required QrType type,
      required String content,
      Value<String> title,
      Value<int> foregroundColor,
      Value<int> backgroundColor,
      Value<QrErrorLevel> errorLevel,
      Value<Uint8List?> logo,
      Value<DateTime> createdAt,
    });
typedef $$QrCodesTableUpdateCompanionBuilder =
    QrCodesCompanion Function({
      Value<int> id,
      Value<QrType> type,
      Value<String> content,
      Value<String> title,
      Value<int> foregroundColor,
      Value<int> backgroundColor,
      Value<QrErrorLevel> errorLevel,
      Value<Uint8List?> logo,
      Value<DateTime> createdAt,
    });

class $$QrCodesTableFilterComposer
    extends Composer<_$AppDatabase, $QrCodesTable> {
  $$QrCodesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<QrType, QrType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foregroundColor => $composableBuilder(
    column: $table.foregroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QrErrorLevel, QrErrorLevel, int>
  get errorLevel => $composableBuilder(
    column: $table.errorLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QrCodesTableOrderingComposer
    extends Composer<_$AppDatabase, $QrCodesTable> {
  $$QrCodesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foregroundColor => $composableBuilder(
    column: $table.foregroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errorLevel => $composableBuilder(
    column: $table.errorLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QrCodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QrCodesTable> {
  $$QrCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QrType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get foregroundColor => $composableBuilder(
    column: $table.foregroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<QrErrorLevel, int> get errorLevel =>
      $composableBuilder(
        column: $table.errorLevel,
        builder: (column) => column,
      );

  GeneratedColumn<Uint8List> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QrCodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QrCodesTable,
          QrCode,
          $$QrCodesTableFilterComposer,
          $$QrCodesTableOrderingComposer,
          $$QrCodesTableAnnotationComposer,
          $$QrCodesTableCreateCompanionBuilder,
          $$QrCodesTableUpdateCompanionBuilder,
          (QrCode, BaseReferences<_$AppDatabase, $QrCodesTable, QrCode>),
          QrCode,
          PrefetchHooks Function()
        > {
  $$QrCodesTableTableManager(_$AppDatabase db, $QrCodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QrCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QrCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QrCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<QrType> type = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> foregroundColor = const Value.absent(),
                Value<int> backgroundColor = const Value.absent(),
                Value<QrErrorLevel> errorLevel = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QrCodesCompanion(
                id: id,
                type: type,
                content: content,
                title: title,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                errorLevel: errorLevel,
                logo: logo,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required QrType type,
                required String content,
                Value<String> title = const Value.absent(),
                Value<int> foregroundColor = const Value.absent(),
                Value<int> backgroundColor = const Value.absent(),
                Value<QrErrorLevel> errorLevel = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QrCodesCompanion.insert(
                id: id,
                type: type,
                content: content,
                title: title,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                errorLevel: errorLevel,
                logo: logo,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QrCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QrCodesTable,
      QrCode,
      $$QrCodesTableFilterComposer,
      $$QrCodesTableOrderingComposer,
      $$QrCodesTableAnnotationComposer,
      $$QrCodesTableCreateCompanionBuilder,
      $$QrCodesTableUpdateCompanionBuilder,
      (QrCode, BaseReferences<_$AppDatabase, $QrCodesTable, QrCode>),
      QrCode,
      PrefetchHooks Function()
    >;
typedef $$GuestEntriesTableCreateCompanionBuilder =
    GuestEntriesCompanion Function({
      Value<int> id,
      required String code,
      Value<String> name,
      Value<String> extra,
      Value<bool> isCheckedIn,
      Value<DateTime?> checkedInAt,
      Value<DateTime> createdAt,
    });
typedef $$GuestEntriesTableUpdateCompanionBuilder =
    GuestEntriesCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String> extra,
      Value<bool> isCheckedIn,
      Value<DateTime?> checkedInAt,
      Value<DateTime> createdAt,
    });

class $$GuestEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $GuestEntriesTable> {
  $$GuestEntriesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCheckedIn => $composableBuilder(
    column: $table.isCheckedIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GuestEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $GuestEntriesTable> {
  $$GuestEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCheckedIn => $composableBuilder(
    column: $table.isCheckedIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GuestEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuestEntriesTable> {
  $$GuestEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<bool> get isCheckedIn => $composableBuilder(
    column: $table.isCheckedIn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkedInAt => $composableBuilder(
    column: $table.checkedInAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GuestEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GuestEntriesTable,
          GuestEntry,
          $$GuestEntriesTableFilterComposer,
          $$GuestEntriesTableOrderingComposer,
          $$GuestEntriesTableAnnotationComposer,
          $$GuestEntriesTableCreateCompanionBuilder,
          $$GuestEntriesTableUpdateCompanionBuilder,
          (
            GuestEntry,
            BaseReferences<_$AppDatabase, $GuestEntriesTable, GuestEntry>,
          ),
          GuestEntry,
          PrefetchHooks Function()
        > {
  $$GuestEntriesTableTableManager(_$AppDatabase db, $GuestEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuestEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuestEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuestEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> extra = const Value.absent(),
                Value<bool> isCheckedIn = const Value.absent(),
                Value<DateTime?> checkedInAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuestEntriesCompanion(
                id: id,
                code: code,
                name: name,
                extra: extra,
                isCheckedIn: isCheckedIn,
                checkedInAt: checkedInAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                Value<String> name = const Value.absent(),
                Value<String> extra = const Value.absent(),
                Value<bool> isCheckedIn = const Value.absent(),
                Value<DateTime?> checkedInAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GuestEntriesCompanion.insert(
                id: id,
                code: code,
                name: name,
                extra: extra,
                isCheckedIn: isCheckedIn,
                checkedInAt: checkedInAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GuestEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GuestEntriesTable,
      GuestEntry,
      $$GuestEntriesTableFilterComposer,
      $$GuestEntriesTableOrderingComposer,
      $$GuestEntriesTableAnnotationComposer,
      $$GuestEntriesTableCreateCompanionBuilder,
      $$GuestEntriesTableUpdateCompanionBuilder,
      (
        GuestEntry,
        BaseReferences<_$AppDatabase, $GuestEntriesTable, GuestEntry>,
      ),
      GuestEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QrCodesTableTableManager get qrCodes =>
      $$QrCodesTableTableManager(_db, _db.qrCodes);
  $$GuestEntriesTableTableManager get guestEntries =>
      $$GuestEntriesTableTableManager(_db, _db.guestEntries);
}
