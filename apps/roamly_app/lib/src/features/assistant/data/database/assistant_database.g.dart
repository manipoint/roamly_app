// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_database.dart';

// ignore_for_file: type=lint
class $AssistantConversationsTable extends AssistantConversations
    with TableInfo<$AssistantConversationsTable, AssistantConversationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssistantConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtEpochMsMeta = const VerificationMeta(
    'createdAtEpochMs',
  );
  @override
  late final GeneratedColumn<int> createdAtEpochMs = GeneratedColumn<int>(
    'created_at_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMsMeta = const VerificationMeta(
    'updatedAtEpochMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpochMs = GeneratedColumn<int>(
    'updated_at_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    localId,
    remoteId,
    title,
    createdAtEpochMs,
    updatedAtEpochMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assistant_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssistantConversationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at_epoch_ms')) {
      context.handle(
        _createdAtEpochMsMeta,
        createdAtEpochMs.isAcceptableOrUnknown(
          data['created_at_epoch_ms']!,
          _createdAtEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMsMeta);
    }
    if (data.containsKey('updated_at_epoch_ms')) {
      context.handle(
        _updatedAtEpochMsMeta,
        updatedAtEpochMs.isAcceptableOrUnknown(
          data['updated_at_epoch_ms']!,
          _updatedAtEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  AssistantConversationRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssistantConversationRecord(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      createdAtEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch_ms'],
      )!,
      updatedAtEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch_ms'],
      )!,
    );
  }

  @override
  $AssistantConversationsTable createAlias(String alias) {
    return $AssistantConversationsTable(attachedDatabase, alias);
  }
}

class AssistantConversationRecord extends DataClass
    implements Insertable<AssistantConversationRecord> {
  final String ownerId;
  final String localId;
  final String? remoteId;
  final String? title;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;
  const AssistantConversationRecord({
    required this.ownerId,
    required this.localId,
    this.remoteId,
    this.title,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs);
    map['updated_at_epoch_ms'] = Variable<int>(updatedAtEpochMs);
    return map;
  }

  AssistantConversationsCompanion toCompanion(bool nullToAbsent) {
    return AssistantConversationsCompanion(
      ownerId: Value(ownerId),
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      createdAtEpochMs: Value(createdAtEpochMs),
      updatedAtEpochMs: Value(updatedAtEpochMs),
    );
  }

  factory AssistantConversationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssistantConversationRecord(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      title: serializer.fromJson<String?>(json['title']),
      createdAtEpochMs: serializer.fromJson<int>(json['createdAtEpochMs']),
      updatedAtEpochMs: serializer.fromJson<int>(json['updatedAtEpochMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'title': serializer.toJson<String?>(title),
      'createdAtEpochMs': serializer.toJson<int>(createdAtEpochMs),
      'updatedAtEpochMs': serializer.toJson<int>(updatedAtEpochMs),
    };
  }

  AssistantConversationRecord copyWith({
    String? ownerId,
    String? localId,
    Value<String?> remoteId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) => AssistantConversationRecord(
    ownerId: ownerId ?? this.ownerId,
    localId: localId ?? this.localId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    title: title.present ? title.value : this.title,
    createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
    updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
  );
  AssistantConversationRecord copyWithCompanion(
    AssistantConversationsCompanion data,
  ) {
    return AssistantConversationRecord(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      title: data.title.present ? data.title.value : this.title,
      createdAtEpochMs: data.createdAtEpochMs.present
          ? data.createdAtEpochMs.value
          : this.createdAtEpochMs,
      updatedAtEpochMs: data.updatedAtEpochMs.present
          ? data.updatedAtEpochMs.value
          : this.updatedAtEpochMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssistantConversationRecord(')
          ..write('ownerId: $ownerId, ')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('createdAtEpochMs: $createdAtEpochMs, ')
          ..write('updatedAtEpochMs: $updatedAtEpochMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    localId,
    remoteId,
    title,
    createdAtEpochMs,
    updatedAtEpochMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistantConversationRecord &&
          other.ownerId == this.ownerId &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.title == this.title &&
          other.createdAtEpochMs == this.createdAtEpochMs &&
          other.updatedAtEpochMs == this.updatedAtEpochMs);
}

class AssistantConversationsCompanion
    extends UpdateCompanion<AssistantConversationRecord> {
  final Value<String> ownerId;
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String?> title;
  final Value<int> createdAtEpochMs;
  final Value<int> updatedAtEpochMs;
  final Value<int> rowid;
  const AssistantConversationsCompanion({
    this.ownerId = const Value.absent(),
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAtEpochMs = const Value.absent(),
    this.updatedAtEpochMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssistantConversationsCompanion.insert({
    required String ownerId,
    required String localId,
    this.remoteId = const Value.absent(),
    this.title = const Value.absent(),
    required int createdAtEpochMs,
    required int updatedAtEpochMs,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       localId = Value(localId),
       createdAtEpochMs = Value(createdAtEpochMs),
       updatedAtEpochMs = Value(updatedAtEpochMs);
  static Insertable<AssistantConversationRecord> custom({
    Expression<String>? ownerId,
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? title,
    Expression<int>? createdAtEpochMs,
    Expression<int>? updatedAtEpochMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (title != null) 'title': title,
      if (createdAtEpochMs != null) 'created_at_epoch_ms': createdAtEpochMs,
      if (updatedAtEpochMs != null) 'updated_at_epoch_ms': updatedAtEpochMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssistantConversationsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? localId,
    Value<String?>? remoteId,
    Value<String?>? title,
    Value<int>? createdAtEpochMs,
    Value<int>? updatedAtEpochMs,
    Value<int>? rowid,
  }) {
    return AssistantConversationsCompanion(
      ownerId: ownerId ?? this.ownerId,
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      title: title ?? this.title,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAtEpochMs.present) {
      map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs.value);
    }
    if (updatedAtEpochMs.present) {
      map['updated_at_epoch_ms'] = Variable<int>(updatedAtEpochMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssistantConversationsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('title: $title, ')
          ..write('createdAtEpochMs: $createdAtEpochMs, ')
          ..write('updatedAtEpochMs: $updatedAtEpochMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssistantMessagesTable extends AssistantMessages
    with TableInfo<$AssistantMessagesTable, AssistantMessageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssistantMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationLocalIdMeta =
      const VerificationMeta('conversationLocalId');
  @override
  late final GeneratedColumn<String> conversationLocalId =
      GeneratedColumn<String>(
        'conversation_local_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES assistant_conversations (local_id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _clientMessageIdMeta = const VerificationMeta(
    'clientMessageId',
  );
  @override
  late final GeneratedColumn<String> clientMessageId = GeneratedColumn<String>(
    'client_message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assistantMessageIdMeta =
      const VerificationMeta('assistantMessageId');
  @override
  late final GeneratedColumn<String> assistantMessageId =
      GeneratedColumn<String>(
        'assistant_message_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _itineraryIdMeta = const VerificationMeta(
    'itineraryId',
  );
  @override
  late final GeneratedColumn<String> itineraryId = GeneratedColumn<String>(
    'itinerary_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AssistantMessageAuthor, String>
  author =
      GeneratedColumn<String>(
        'author',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AssistantMessageAuthor>(
        $AssistantMessagesTable.$converterauthor,
      );
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
  @override
  late final GeneratedColumnWithTypeConverter<
    AssistantMessageDeliveryState,
    String
  >
  deliveryState =
      GeneratedColumn<String>(
        'delivery_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AssistantMessageDeliveryState>(
        $AssistantMessagesTable.$converterdeliveryState,
      );
  static const VerificationMeta _createdAtEpochMsMeta = const VerificationMeta(
    'createdAtEpochMs',
  );
  @override
  late final GeneratedColumn<int> createdAtEpochMs = GeneratedColumn<int>(
    'created_at_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMsMeta = const VerificationMeta(
    'updatedAtEpochMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpochMs = GeneratedColumn<int>(
    'updated_at_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    id,
    conversationLocalId,
    clientMessageId,
    assistantMessageId,
    itineraryId,
    author,
    content,
    deliveryState,
    createdAtEpochMs,
    updatedAtEpochMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assistant_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssistantMessageRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_local_id')) {
      context.handle(
        _conversationLocalIdMeta,
        conversationLocalId.isAcceptableOrUnknown(
          data['conversation_local_id']!,
          _conversationLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationLocalIdMeta);
    }
    if (data.containsKey('client_message_id')) {
      context.handle(
        _clientMessageIdMeta,
        clientMessageId.isAcceptableOrUnknown(
          data['client_message_id']!,
          _clientMessageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMessageIdMeta);
    }
    if (data.containsKey('assistant_message_id')) {
      context.handle(
        _assistantMessageIdMeta,
        assistantMessageId.isAcceptableOrUnknown(
          data['assistant_message_id']!,
          _assistantMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('itinerary_id')) {
      context.handle(
        _itineraryIdMeta,
        itineraryId.isAcceptableOrUnknown(
          data['itinerary_id']!,
          _itineraryIdMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at_epoch_ms')) {
      context.handle(
        _createdAtEpochMsMeta,
        createdAtEpochMs.isAcceptableOrUnknown(
          data['created_at_epoch_ms']!,
          _createdAtEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMsMeta);
    }
    if (data.containsKey('updated_at_epoch_ms')) {
      context.handle(
        _updatedAtEpochMsMeta,
        updatedAtEpochMs.isAcceptableOrUnknown(
          data['updated_at_epoch_ms']!,
          _updatedAtEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssistantMessageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssistantMessageRecord(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_local_id'],
      )!,
      clientMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_message_id'],
      )!,
      assistantMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assistant_message_id'],
      ),
      itineraryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}itinerary_id'],
      ),
      author: $AssistantMessagesTable.$converterauthor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}author'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      deliveryState: $AssistantMessagesTable.$converterdeliveryState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}delivery_state'],
        )!,
      ),
      createdAtEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch_ms'],
      )!,
      updatedAtEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch_ms'],
      )!,
    );
  }

  @override
  $AssistantMessagesTable createAlias(String alias) {
    return $AssistantMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssistantMessageAuthor, String, String>
  $converterauthor = const EnumNameConverter<AssistantMessageAuthor>(
    AssistantMessageAuthor.values,
  );
  static JsonTypeConverter2<AssistantMessageDeliveryState, String, String>
  $converterdeliveryState =
      const EnumNameConverter<AssistantMessageDeliveryState>(
        AssistantMessageDeliveryState.values,
      );
}

class AssistantMessageRecord extends DataClass
    implements Insertable<AssistantMessageRecord> {
  final String ownerId;
  final String id;
  final String conversationLocalId;
  final String clientMessageId;
  final String? assistantMessageId;
  final String? itineraryId;
  final AssistantMessageAuthor author;
  final String content;
  final AssistantMessageDeliveryState deliveryState;
  final int createdAtEpochMs;
  final int updatedAtEpochMs;
  const AssistantMessageRecord({
    required this.ownerId,
    required this.id,
    required this.conversationLocalId,
    required this.clientMessageId,
    this.assistantMessageId,
    this.itineraryId,
    required this.author,
    required this.content,
    required this.deliveryState,
    required this.createdAtEpochMs,
    required this.updatedAtEpochMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['id'] = Variable<String>(id);
    map['conversation_local_id'] = Variable<String>(conversationLocalId);
    map['client_message_id'] = Variable<String>(clientMessageId);
    if (!nullToAbsent || assistantMessageId != null) {
      map['assistant_message_id'] = Variable<String>(assistantMessageId);
    }
    if (!nullToAbsent || itineraryId != null) {
      map['itinerary_id'] = Variable<String>(itineraryId);
    }
    {
      map['author'] = Variable<String>(
        $AssistantMessagesTable.$converterauthor.toSql(author),
      );
    }
    map['content'] = Variable<String>(content);
    {
      map['delivery_state'] = Variable<String>(
        $AssistantMessagesTable.$converterdeliveryState.toSql(deliveryState),
      );
    }
    map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs);
    map['updated_at_epoch_ms'] = Variable<int>(updatedAtEpochMs);
    return map;
  }

  AssistantMessagesCompanion toCompanion(bool nullToAbsent) {
    return AssistantMessagesCompanion(
      ownerId: Value(ownerId),
      id: Value(id),
      conversationLocalId: Value(conversationLocalId),
      clientMessageId: Value(clientMessageId),
      assistantMessageId: assistantMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(assistantMessageId),
      itineraryId: itineraryId == null && nullToAbsent
          ? const Value.absent()
          : Value(itineraryId),
      author: Value(author),
      content: Value(content),
      deliveryState: Value(deliveryState),
      createdAtEpochMs: Value(createdAtEpochMs),
      updatedAtEpochMs: Value(updatedAtEpochMs),
    );
  }

  factory AssistantMessageRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssistantMessageRecord(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      id: serializer.fromJson<String>(json['id']),
      conversationLocalId: serializer.fromJson<String>(
        json['conversationLocalId'],
      ),
      clientMessageId: serializer.fromJson<String>(json['clientMessageId']),
      assistantMessageId: serializer.fromJson<String?>(
        json['assistantMessageId'],
      ),
      itineraryId: serializer.fromJson<String?>(json['itineraryId']),
      author: $AssistantMessagesTable.$converterauthor.fromJson(
        serializer.fromJson<String>(json['author']),
      ),
      content: serializer.fromJson<String>(json['content']),
      deliveryState: $AssistantMessagesTable.$converterdeliveryState.fromJson(
        serializer.fromJson<String>(json['deliveryState']),
      ),
      createdAtEpochMs: serializer.fromJson<int>(json['createdAtEpochMs']),
      updatedAtEpochMs: serializer.fromJson<int>(json['updatedAtEpochMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'id': serializer.toJson<String>(id),
      'conversationLocalId': serializer.toJson<String>(conversationLocalId),
      'clientMessageId': serializer.toJson<String>(clientMessageId),
      'assistantMessageId': serializer.toJson<String?>(assistantMessageId),
      'itineraryId': serializer.toJson<String?>(itineraryId),
      'author': serializer.toJson<String>(
        $AssistantMessagesTable.$converterauthor.toJson(author),
      ),
      'content': serializer.toJson<String>(content),
      'deliveryState': serializer.toJson<String>(
        $AssistantMessagesTable.$converterdeliveryState.toJson(deliveryState),
      ),
      'createdAtEpochMs': serializer.toJson<int>(createdAtEpochMs),
      'updatedAtEpochMs': serializer.toJson<int>(updatedAtEpochMs),
    };
  }

  AssistantMessageRecord copyWith({
    String? ownerId,
    String? id,
    String? conversationLocalId,
    String? clientMessageId,
    Value<String?> assistantMessageId = const Value.absent(),
    Value<String?> itineraryId = const Value.absent(),
    AssistantMessageAuthor? author,
    String? content,
    AssistantMessageDeliveryState? deliveryState,
    int? createdAtEpochMs,
    int? updatedAtEpochMs,
  }) => AssistantMessageRecord(
    ownerId: ownerId ?? this.ownerId,
    id: id ?? this.id,
    conversationLocalId: conversationLocalId ?? this.conversationLocalId,
    clientMessageId: clientMessageId ?? this.clientMessageId,
    assistantMessageId: assistantMessageId.present
        ? assistantMessageId.value
        : this.assistantMessageId,
    itineraryId: itineraryId.present ? itineraryId.value : this.itineraryId,
    author: author ?? this.author,
    content: content ?? this.content,
    deliveryState: deliveryState ?? this.deliveryState,
    createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
    updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
  );
  AssistantMessageRecord copyWithCompanion(AssistantMessagesCompanion data) {
    return AssistantMessageRecord(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      id: data.id.present ? data.id.value : this.id,
      conversationLocalId: data.conversationLocalId.present
          ? data.conversationLocalId.value
          : this.conversationLocalId,
      clientMessageId: data.clientMessageId.present
          ? data.clientMessageId.value
          : this.clientMessageId,
      assistantMessageId: data.assistantMessageId.present
          ? data.assistantMessageId.value
          : this.assistantMessageId,
      itineraryId: data.itineraryId.present
          ? data.itineraryId.value
          : this.itineraryId,
      author: data.author.present ? data.author.value : this.author,
      content: data.content.present ? data.content.value : this.content,
      deliveryState: data.deliveryState.present
          ? data.deliveryState.value
          : this.deliveryState,
      createdAtEpochMs: data.createdAtEpochMs.present
          ? data.createdAtEpochMs.value
          : this.createdAtEpochMs,
      updatedAtEpochMs: data.updatedAtEpochMs.present
          ? data.updatedAtEpochMs.value
          : this.updatedAtEpochMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssistantMessageRecord(')
          ..write('ownerId: $ownerId, ')
          ..write('id: $id, ')
          ..write('conversationLocalId: $conversationLocalId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('assistantMessageId: $assistantMessageId, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('author: $author, ')
          ..write('content: $content, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('createdAtEpochMs: $createdAtEpochMs, ')
          ..write('updatedAtEpochMs: $updatedAtEpochMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    id,
    conversationLocalId,
    clientMessageId,
    assistantMessageId,
    itineraryId,
    author,
    content,
    deliveryState,
    createdAtEpochMs,
    updatedAtEpochMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistantMessageRecord &&
          other.ownerId == this.ownerId &&
          other.id == this.id &&
          other.conversationLocalId == this.conversationLocalId &&
          other.clientMessageId == this.clientMessageId &&
          other.assistantMessageId == this.assistantMessageId &&
          other.itineraryId == this.itineraryId &&
          other.author == this.author &&
          other.content == this.content &&
          other.deliveryState == this.deliveryState &&
          other.createdAtEpochMs == this.createdAtEpochMs &&
          other.updatedAtEpochMs == this.updatedAtEpochMs);
}

class AssistantMessagesCompanion
    extends UpdateCompanion<AssistantMessageRecord> {
  final Value<String> ownerId;
  final Value<String> id;
  final Value<String> conversationLocalId;
  final Value<String> clientMessageId;
  final Value<String?> assistantMessageId;
  final Value<String?> itineraryId;
  final Value<AssistantMessageAuthor> author;
  final Value<String> content;
  final Value<AssistantMessageDeliveryState> deliveryState;
  final Value<int> createdAtEpochMs;
  final Value<int> updatedAtEpochMs;
  final Value<int> rowid;
  const AssistantMessagesCompanion({
    this.ownerId = const Value.absent(),
    this.id = const Value.absent(),
    this.conversationLocalId = const Value.absent(),
    this.clientMessageId = const Value.absent(),
    this.assistantMessageId = const Value.absent(),
    this.itineraryId = const Value.absent(),
    this.author = const Value.absent(),
    this.content = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.createdAtEpochMs = const Value.absent(),
    this.updatedAtEpochMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssistantMessagesCompanion.insert({
    required String ownerId,
    required String id,
    required String conversationLocalId,
    required String clientMessageId,
    this.assistantMessageId = const Value.absent(),
    this.itineraryId = const Value.absent(),
    required AssistantMessageAuthor author,
    required String content,
    required AssistantMessageDeliveryState deliveryState,
    required int createdAtEpochMs,
    required int updatedAtEpochMs,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       id = Value(id),
       conversationLocalId = Value(conversationLocalId),
       clientMessageId = Value(clientMessageId),
       author = Value(author),
       content = Value(content),
       deliveryState = Value(deliveryState),
       createdAtEpochMs = Value(createdAtEpochMs),
       updatedAtEpochMs = Value(updatedAtEpochMs);
  static Insertable<AssistantMessageRecord> custom({
    Expression<String>? ownerId,
    Expression<String>? id,
    Expression<String>? conversationLocalId,
    Expression<String>? clientMessageId,
    Expression<String>? assistantMessageId,
    Expression<String>? itineraryId,
    Expression<String>? author,
    Expression<String>? content,
    Expression<String>? deliveryState,
    Expression<int>? createdAtEpochMs,
    Expression<int>? updatedAtEpochMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (id != null) 'id': id,
      if (conversationLocalId != null)
        'conversation_local_id': conversationLocalId,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      if (assistantMessageId != null)
        'assistant_message_id': assistantMessageId,
      if (itineraryId != null) 'itinerary_id': itineraryId,
      if (author != null) 'author': author,
      if (content != null) 'content': content,
      if (deliveryState != null) 'delivery_state': deliveryState,
      if (createdAtEpochMs != null) 'created_at_epoch_ms': createdAtEpochMs,
      if (updatedAtEpochMs != null) 'updated_at_epoch_ms': updatedAtEpochMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssistantMessagesCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? id,
    Value<String>? conversationLocalId,
    Value<String>? clientMessageId,
    Value<String?>? assistantMessageId,
    Value<String?>? itineraryId,
    Value<AssistantMessageAuthor>? author,
    Value<String>? content,
    Value<AssistantMessageDeliveryState>? deliveryState,
    Value<int>? createdAtEpochMs,
    Value<int>? updatedAtEpochMs,
    Value<int>? rowid,
  }) {
    return AssistantMessagesCompanion(
      ownerId: ownerId ?? this.ownerId,
      id: id ?? this.id,
      conversationLocalId: conversationLocalId ?? this.conversationLocalId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      assistantMessageId: assistantMessageId ?? this.assistantMessageId,
      itineraryId: itineraryId ?? this.itineraryId,
      author: author ?? this.author,
      content: content ?? this.content,
      deliveryState: deliveryState ?? this.deliveryState,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      updatedAtEpochMs: updatedAtEpochMs ?? this.updatedAtEpochMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationLocalId.present) {
      map['conversation_local_id'] = Variable<String>(
        conversationLocalId.value,
      );
    }
    if (clientMessageId.present) {
      map['client_message_id'] = Variable<String>(clientMessageId.value);
    }
    if (assistantMessageId.present) {
      map['assistant_message_id'] = Variable<String>(assistantMessageId.value);
    }
    if (itineraryId.present) {
      map['itinerary_id'] = Variable<String>(itineraryId.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(
        $AssistantMessagesTable.$converterauthor.toSql(author.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (deliveryState.present) {
      map['delivery_state'] = Variable<String>(
        $AssistantMessagesTable.$converterdeliveryState.toSql(
          deliveryState.value,
        ),
      );
    }
    if (createdAtEpochMs.present) {
      map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs.value);
    }
    if (updatedAtEpochMs.present) {
      map['updated_at_epoch_ms'] = Variable<int>(updatedAtEpochMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssistantMessagesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('id: $id, ')
          ..write('conversationLocalId: $conversationLocalId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('assistantMessageId: $assistantMessageId, ')
          ..write('itineraryId: $itineraryId, ')
          ..write('author: $author, ')
          ..write('content: $content, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('createdAtEpochMs: $createdAtEpochMs, ')
          ..write('updatedAtEpochMs: $updatedAtEpochMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssistantPendingRequestsTable extends AssistantPendingRequests
    with
        TableInfo<
          $AssistantPendingRequestsTable,
          AssistantPendingRequestRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssistantPendingRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMessageIdMeta = const VerificationMeta(
    'clientMessageId',
  );
  @override
  late final GeneratedColumn<String> clientMessageId = GeneratedColumn<String>(
    'client_message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationLocalIdMeta =
      const VerificationMeta('conversationLocalId');
  @override
  late final GeneratedColumn<String> conversationLocalId =
      GeneratedColumn<String>(
        'conversation_local_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES assistant_conversations (local_id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtEpochMsMeta = const VerificationMeta(
    'createdAtEpochMs',
  );
  @override
  late final GeneratedColumn<int> createdAtEpochMs = GeneratedColumn<int>(
    'created_at_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    clientMessageId,
    conversationLocalId,
    conversationId,
    tripId,
    message,
    locale,
    createdAtEpochMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assistant_pending_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssistantPendingRequestRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('client_message_id')) {
      context.handle(
        _clientMessageIdMeta,
        clientMessageId.isAcceptableOrUnknown(
          data['client_message_id']!,
          _clientMessageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMessageIdMeta);
    }
    if (data.containsKey('conversation_local_id')) {
      context.handle(
        _conversationLocalIdMeta,
        conversationLocalId.isAcceptableOrUnknown(
          data['conversation_local_id']!,
          _conversationLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationLocalIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('created_at_epoch_ms')) {
      context.handle(
        _createdAtEpochMsMeta,
        createdAtEpochMs.isAcceptableOrUnknown(
          data['created_at_epoch_ms']!,
          _createdAtEpochMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, clientMessageId};
  @override
  AssistantPendingRequestRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssistantPendingRequestRecord(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      clientMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_message_id'],
      )!,
      conversationLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_local_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      ),
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      createdAtEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch_ms'],
      )!,
    );
  }

  @override
  $AssistantPendingRequestsTable createAlias(String alias) {
    return $AssistantPendingRequestsTable(attachedDatabase, alias);
  }
}

class AssistantPendingRequestRecord extends DataClass
    implements Insertable<AssistantPendingRequestRecord> {
  final String ownerId;
  final String clientMessageId;
  final String conversationLocalId;
  final String? conversationId;
  final String? tripId;
  final String message;
  final String locale;
  final int createdAtEpochMs;
  const AssistantPendingRequestRecord({
    required this.ownerId,
    required this.clientMessageId,
    required this.conversationLocalId,
    this.conversationId,
    this.tripId,
    required this.message,
    required this.locale,
    required this.createdAtEpochMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['client_message_id'] = Variable<String>(clientMessageId);
    map['conversation_local_id'] = Variable<String>(conversationLocalId);
    if (!nullToAbsent || conversationId != null) {
      map['conversation_id'] = Variable<String>(conversationId);
    }
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['message'] = Variable<String>(message);
    map['locale'] = Variable<String>(locale);
    map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs);
    return map;
  }

  AssistantPendingRequestsCompanion toCompanion(bool nullToAbsent) {
    return AssistantPendingRequestsCompanion(
      ownerId: Value(ownerId),
      clientMessageId: Value(clientMessageId),
      conversationLocalId: Value(conversationLocalId),
      conversationId: conversationId == null && nullToAbsent
          ? const Value.absent()
          : Value(conversationId),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      message: Value(message),
      locale: Value(locale),
      createdAtEpochMs: Value(createdAtEpochMs),
    );
  }

  factory AssistantPendingRequestRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssistantPendingRequestRecord(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      clientMessageId: serializer.fromJson<String>(json['clientMessageId']),
      conversationLocalId: serializer.fromJson<String>(
        json['conversationLocalId'],
      ),
      conversationId: serializer.fromJson<String?>(json['conversationId']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      message: serializer.fromJson<String>(json['message']),
      locale: serializer.fromJson<String>(json['locale']),
      createdAtEpochMs: serializer.fromJson<int>(json['createdAtEpochMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'clientMessageId': serializer.toJson<String>(clientMessageId),
      'conversationLocalId': serializer.toJson<String>(conversationLocalId),
      'conversationId': serializer.toJson<String?>(conversationId),
      'tripId': serializer.toJson<String?>(tripId),
      'message': serializer.toJson<String>(message),
      'locale': serializer.toJson<String>(locale),
      'createdAtEpochMs': serializer.toJson<int>(createdAtEpochMs),
    };
  }

  AssistantPendingRequestRecord copyWith({
    String? ownerId,
    String? clientMessageId,
    String? conversationLocalId,
    Value<String?> conversationId = const Value.absent(),
    Value<String?> tripId = const Value.absent(),
    String? message,
    String? locale,
    int? createdAtEpochMs,
  }) => AssistantPendingRequestRecord(
    ownerId: ownerId ?? this.ownerId,
    clientMessageId: clientMessageId ?? this.clientMessageId,
    conversationLocalId: conversationLocalId ?? this.conversationLocalId,
    conversationId: conversationId.present
        ? conversationId.value
        : this.conversationId,
    tripId: tripId.present ? tripId.value : this.tripId,
    message: message ?? this.message,
    locale: locale ?? this.locale,
    createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
  );
  AssistantPendingRequestRecord copyWithCompanion(
    AssistantPendingRequestsCompanion data,
  ) {
    return AssistantPendingRequestRecord(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      clientMessageId: data.clientMessageId.present
          ? data.clientMessageId.value
          : this.clientMessageId,
      conversationLocalId: data.conversationLocalId.present
          ? data.conversationLocalId.value
          : this.conversationLocalId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      message: data.message.present ? data.message.value : this.message,
      locale: data.locale.present ? data.locale.value : this.locale,
      createdAtEpochMs: data.createdAtEpochMs.present
          ? data.createdAtEpochMs.value
          : this.createdAtEpochMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssistantPendingRequestRecord(')
          ..write('ownerId: $ownerId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('conversationLocalId: $conversationLocalId, ')
          ..write('conversationId: $conversationId, ')
          ..write('tripId: $tripId, ')
          ..write('message: $message, ')
          ..write('locale: $locale, ')
          ..write('createdAtEpochMs: $createdAtEpochMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    clientMessageId,
    conversationLocalId,
    conversationId,
    tripId,
    message,
    locale,
    createdAtEpochMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistantPendingRequestRecord &&
          other.ownerId == this.ownerId &&
          other.clientMessageId == this.clientMessageId &&
          other.conversationLocalId == this.conversationLocalId &&
          other.conversationId == this.conversationId &&
          other.tripId == this.tripId &&
          other.message == this.message &&
          other.locale == this.locale &&
          other.createdAtEpochMs == this.createdAtEpochMs);
}

class AssistantPendingRequestsCompanion
    extends UpdateCompanion<AssistantPendingRequestRecord> {
  final Value<String> ownerId;
  final Value<String> clientMessageId;
  final Value<String> conversationLocalId;
  final Value<String?> conversationId;
  final Value<String?> tripId;
  final Value<String> message;
  final Value<String> locale;
  final Value<int> createdAtEpochMs;
  final Value<int> rowid;
  const AssistantPendingRequestsCompanion({
    this.ownerId = const Value.absent(),
    this.clientMessageId = const Value.absent(),
    this.conversationLocalId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.message = const Value.absent(),
    this.locale = const Value.absent(),
    this.createdAtEpochMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssistantPendingRequestsCompanion.insert({
    required String ownerId,
    required String clientMessageId,
    required String conversationLocalId,
    this.conversationId = const Value.absent(),
    this.tripId = const Value.absent(),
    required String message,
    required String locale,
    required int createdAtEpochMs,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       clientMessageId = Value(clientMessageId),
       conversationLocalId = Value(conversationLocalId),
       message = Value(message),
       locale = Value(locale),
       createdAtEpochMs = Value(createdAtEpochMs);
  static Insertable<AssistantPendingRequestRecord> custom({
    Expression<String>? ownerId,
    Expression<String>? clientMessageId,
    Expression<String>? conversationLocalId,
    Expression<String>? conversationId,
    Expression<String>? tripId,
    Expression<String>? message,
    Expression<String>? locale,
    Expression<int>? createdAtEpochMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (clientMessageId != null) 'client_message_id': clientMessageId,
      if (conversationLocalId != null)
        'conversation_local_id': conversationLocalId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (tripId != null) 'trip_id': tripId,
      if (message != null) 'message': message,
      if (locale != null) 'locale': locale,
      if (createdAtEpochMs != null) 'created_at_epoch_ms': createdAtEpochMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssistantPendingRequestsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? clientMessageId,
    Value<String>? conversationLocalId,
    Value<String?>? conversationId,
    Value<String?>? tripId,
    Value<String>? message,
    Value<String>? locale,
    Value<int>? createdAtEpochMs,
    Value<int>? rowid,
  }) {
    return AssistantPendingRequestsCompanion(
      ownerId: ownerId ?? this.ownerId,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      conversationLocalId: conversationLocalId ?? this.conversationLocalId,
      conversationId: conversationId ?? this.conversationId,
      tripId: tripId ?? this.tripId,
      message: message ?? this.message,
      locale: locale ?? this.locale,
      createdAtEpochMs: createdAtEpochMs ?? this.createdAtEpochMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (clientMessageId.present) {
      map['client_message_id'] = Variable<String>(clientMessageId.value);
    }
    if (conversationLocalId.present) {
      map['conversation_local_id'] = Variable<String>(
        conversationLocalId.value,
      );
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (createdAtEpochMs.present) {
      map['created_at_epoch_ms'] = Variable<int>(createdAtEpochMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssistantPendingRequestsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('clientMessageId: $clientMessageId, ')
          ..write('conversationLocalId: $conversationLocalId, ')
          ..write('conversationId: $conversationId, ')
          ..write('tripId: $tripId, ')
          ..write('message: $message, ')
          ..write('locale: $locale, ')
          ..write('createdAtEpochMs: $createdAtEpochMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AssistantDatabase extends GeneratedDatabase {
  _$AssistantDatabase(QueryExecutor e) : super(e);
  $AssistantDatabaseManager get managers => $AssistantDatabaseManager(this);
  late final $AssistantConversationsTable assistantConversations =
      $AssistantConversationsTable(this);
  late final $AssistantMessagesTable assistantMessages =
      $AssistantMessagesTable(this);
  late final $AssistantPendingRequestsTable assistantPendingRequests =
      $AssistantPendingRequestsTable(this);
  late final Index assistantConversationsOwnerUpdatedAt = Index(
    'assistant_conversations_owner_updated_at',
    'CREATE INDEX assistant_conversations_owner_updated_at ON assistant_conversations (owner_id, updated_at_epoch_ms)',
  );
  late final Index assistantConversationsOwnerRemoteId = Index(
    'assistant_conversations_owner_remote_id',
    'CREATE UNIQUE INDEX assistant_conversations_owner_remote_id ON assistant_conversations (owner_id, remote_id)',
  );
  late final Index assistantMessagesOwnerConversationCreatedAt = Index(
    'assistant_messages_owner_conversation_created_at',
    'CREATE INDEX assistant_messages_owner_conversation_created_at ON assistant_messages (owner_id, conversation_local_id, created_at_epoch_ms, id)',
  );
  late final Index assistantMessagesOwnerClientMessageId = Index(
    'assistant_messages_owner_client_message_id',
    'CREATE INDEX assistant_messages_owner_client_message_id ON assistant_messages (owner_id, client_message_id)',
  );
  late final Index assistantMessagesOwnerAssistantMessageId = Index(
    'assistant_messages_owner_assistant_message_id',
    'CREATE UNIQUE INDEX assistant_messages_owner_assistant_message_id ON assistant_messages (owner_id, assistant_message_id)',
  );
  late final Index assistantPendingRequestsOwnerCreatedAt = Index(
    'assistant_pending_requests_owner_created_at',
    'CREATE INDEX assistant_pending_requests_owner_created_at ON assistant_pending_requests (owner_id, created_at_epoch_ms, client_message_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    assistantConversations,
    assistantMessages,
    assistantPendingRequests,
    assistantConversationsOwnerUpdatedAt,
    assistantConversationsOwnerRemoteId,
    assistantMessagesOwnerConversationCreatedAt,
    assistantMessagesOwnerClientMessageId,
    assistantMessagesOwnerAssistantMessageId,
    assistantPendingRequestsOwnerCreatedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'assistant_conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('assistant_messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'assistant_conversations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('assistant_pending_requests', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$AssistantConversationsTableCreateCompanionBuilder =
    AssistantConversationsCompanion Function({
      required String ownerId,
      required String localId,
      Value<String?> remoteId,
      Value<String?> title,
      required int createdAtEpochMs,
      required int updatedAtEpochMs,
      Value<int> rowid,
    });
typedef $$AssistantConversationsTableUpdateCompanionBuilder =
    AssistantConversationsCompanion Function({
      Value<String> ownerId,
      Value<String> localId,
      Value<String?> remoteId,
      Value<String?> title,
      Value<int> createdAtEpochMs,
      Value<int> updatedAtEpochMs,
      Value<int> rowid,
    });

final class $$AssistantConversationsTableReferences
    extends
        BaseReferences<
          _$AssistantDatabase,
          $AssistantConversationsTable,
          AssistantConversationRecord
        > {
  $$AssistantConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $AssistantMessagesTable,
    List<AssistantMessageRecord>
  >
  _assistantMessagesRefsTable(
    _$AssistantDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assistantMessages,
    aliasName:
        'assistant_conversations__local_id__assistant_messages__conversation_local_id',
  );

  $$AssistantMessagesTableProcessedTableManager get assistantMessagesRefs {
    final manager =
        $$AssistantMessagesTableTableManager(
          $_db,
          $_db.assistantMessages,
        ).filter(
          (f) => f.conversationLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _assistantMessagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AssistantPendingRequestsTable,
    List<AssistantPendingRequestRecord>
  >
  _assistantPendingRequestsRefsTable(
    _$AssistantDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assistantPendingRequests,
    aliasName:
        'assistant_conversations__local_id__assistant_pending_requests__conversation_local_id',
  );

  $$AssistantPendingRequestsTableProcessedTableManager
  get assistantPendingRequestsRefs {
    final manager =
        $$AssistantPendingRequestsTableTableManager(
          $_db,
          $_db.assistantPendingRequests,
        ).filter(
          (f) => f.conversationLocalId.localId.sqlEquals(
            $_itemColumn<String>('local_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _assistantPendingRequestsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssistantConversationsTableFilterComposer
    extends Composer<_$AssistantDatabase, $AssistantConversationsTable> {
  $$AssistantConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> assistantMessagesRefs(
    Expression<bool> Function($$AssistantMessagesTableFilterComposer f) f,
  ) {
    final $$AssistantMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localId,
      referencedTable: $db.assistantMessages,
      getReferencedColumn: (t) => t.conversationLocalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssistantMessagesTableFilterComposer(
            $db: $db,
            $table: $db.assistantMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assistantPendingRequestsRefs(
    Expression<bool> Function($$AssistantPendingRequestsTableFilterComposer f)
    f,
  ) {
    final $$AssistantPendingRequestsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.assistantPendingRequests,
          getReferencedColumn: (t) => t.conversationLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantPendingRequestsTableFilterComposer(
                $db: $db,
                $table: $db.assistantPendingRequests,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssistantConversationsTableOrderingComposer
    extends Composer<_$AssistantDatabase, $AssistantConversationsTable> {
  $$AssistantConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssistantConversationsTableAnnotationComposer
    extends Composer<_$AssistantDatabase, $AssistantConversationsTable> {
  $$AssistantConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => column,
  );

  Expression<T> assistantMessagesRefs<T extends Object>(
    Expression<T> Function($$AssistantMessagesTableAnnotationComposer a) f,
  ) {
    final $$AssistantMessagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.assistantMessages,
          getReferencedColumn: (t) => t.conversationLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantMessagesTableAnnotationComposer(
                $db: $db,
                $table: $db.assistantMessages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> assistantPendingRequestsRefs<T extends Object>(
    Expression<T> Function($$AssistantPendingRequestsTableAnnotationComposer a)
    f,
  ) {
    final $$AssistantPendingRequestsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.localId,
          referencedTable: $db.assistantPendingRequests,
          getReferencedColumn: (t) => t.conversationLocalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantPendingRequestsTableAnnotationComposer(
                $db: $db,
                $table: $db.assistantPendingRequests,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssistantConversationsTableTableManager
    extends
        RootTableManager<
          _$AssistantDatabase,
          $AssistantConversationsTable,
          AssistantConversationRecord,
          $$AssistantConversationsTableFilterComposer,
          $$AssistantConversationsTableOrderingComposer,
          $$AssistantConversationsTableAnnotationComposer,
          $$AssistantConversationsTableCreateCompanionBuilder,
          $$AssistantConversationsTableUpdateCompanionBuilder,
          (
            AssistantConversationRecord,
            $$AssistantConversationsTableReferences,
          ),
          AssistantConversationRecord,
          PrefetchHooks Function({
            bool assistantMessagesRefs,
            bool assistantPendingRequestsRefs,
          })
        > {
  $$AssistantConversationsTableTableManager(
    _$AssistantDatabase db,
    $AssistantConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssistantConversationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AssistantConversationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AssistantConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> createdAtEpochMs = const Value.absent(),
                Value<int> updatedAtEpochMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssistantConversationsCompanion(
                ownerId: ownerId,
                localId: localId,
                remoteId: remoteId,
                title: title,
                createdAtEpochMs: createdAtEpochMs,
                updatedAtEpochMs: updatedAtEpochMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String localId,
                Value<String?> remoteId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required int createdAtEpochMs,
                required int updatedAtEpochMs,
                Value<int> rowid = const Value.absent(),
              }) => AssistantConversationsCompanion.insert(
                ownerId: ownerId,
                localId: localId,
                remoteId: remoteId,
                title: title,
                createdAtEpochMs: createdAtEpochMs,
                updatedAtEpochMs: updatedAtEpochMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssistantConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assistantMessagesRefs = false,
                assistantPendingRequestsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assistantMessagesRefs) db.assistantMessages,
                    if (assistantPendingRequestsRefs)
                      db.assistantPendingRequests,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assistantMessagesRefs)
                        await $_getPrefetchedData<
                          AssistantConversationRecord,
                          $AssistantConversationsTable,
                          AssistantMessageRecord
                        >(
                          currentTable: table,
                          referencedTable:
                              $$AssistantConversationsTableReferences
                                  ._assistantMessagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssistantConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).assistantMessagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                      if (assistantPendingRequestsRefs)
                        await $_getPrefetchedData<
                          AssistantConversationRecord,
                          $AssistantConversationsTable,
                          AssistantPendingRequestRecord
                        >(
                          currentTable: table,
                          referencedTable:
                              $$AssistantConversationsTableReferences
                                  ._assistantPendingRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssistantConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).assistantPendingRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationLocalId == item.localId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssistantConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssistantDatabase,
      $AssistantConversationsTable,
      AssistantConversationRecord,
      $$AssistantConversationsTableFilterComposer,
      $$AssistantConversationsTableOrderingComposer,
      $$AssistantConversationsTableAnnotationComposer,
      $$AssistantConversationsTableCreateCompanionBuilder,
      $$AssistantConversationsTableUpdateCompanionBuilder,
      (AssistantConversationRecord, $$AssistantConversationsTableReferences),
      AssistantConversationRecord,
      PrefetchHooks Function({
        bool assistantMessagesRefs,
        bool assistantPendingRequestsRefs,
      })
    >;
typedef $$AssistantMessagesTableCreateCompanionBuilder =
    AssistantMessagesCompanion Function({
      required String ownerId,
      required String id,
      required String conversationLocalId,
      required String clientMessageId,
      Value<String?> assistantMessageId,
      Value<String?> itineraryId,
      required AssistantMessageAuthor author,
      required String content,
      required AssistantMessageDeliveryState deliveryState,
      required int createdAtEpochMs,
      required int updatedAtEpochMs,
      Value<int> rowid,
    });
typedef $$AssistantMessagesTableUpdateCompanionBuilder =
    AssistantMessagesCompanion Function({
      Value<String> ownerId,
      Value<String> id,
      Value<String> conversationLocalId,
      Value<String> clientMessageId,
      Value<String?> assistantMessageId,
      Value<String?> itineraryId,
      Value<AssistantMessageAuthor> author,
      Value<String> content,
      Value<AssistantMessageDeliveryState> deliveryState,
      Value<int> createdAtEpochMs,
      Value<int> updatedAtEpochMs,
      Value<int> rowid,
    });

final class $$AssistantMessagesTableReferences
    extends
        BaseReferences<
          _$AssistantDatabase,
          $AssistantMessagesTable,
          AssistantMessageRecord
        > {
  $$AssistantMessagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssistantConversationsTable _conversationLocalIdTable(
    _$AssistantDatabase db,
  ) => db.assistantConversations.createAlias(
    'assistant_messages__conversation_local_id__assistant_conversations__local_id',
  );

  $$AssistantConversationsTableProcessedTableManager get conversationLocalId {
    final $_column = $_itemColumn<String>('conversation_local_id')!;

    final manager = $$AssistantConversationsTableTableManager(
      $_db,
      $_db.assistantConversations,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssistantMessagesTableFilterComposer
    extends Composer<_$AssistantDatabase, $AssistantMessagesTable> {
  $$AssistantMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assistantMessageId => $composableBuilder(
    column: $table.assistantMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AssistantMessageAuthor,
    AssistantMessageAuthor,
    String
  >
  get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AssistantMessageDeliveryState,
    AssistantMessageDeliveryState,
    String
  >
  get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  $$AssistantConversationsTableFilterComposer get conversationLocalId {
    final $$AssistantConversationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableFilterComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantMessagesTableOrderingComposer
    extends Composer<_$AssistantDatabase, $AssistantMessagesTable> {
  $$AssistantMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assistantMessageId => $composableBuilder(
    column: $table.assistantMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssistantConversationsTableOrderingComposer get conversationLocalId {
    final $$AssistantConversationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableOrderingComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantMessagesTableAnnotationComposer
    extends Composer<_$AssistantDatabase, $AssistantMessagesTable> {
  $$AssistantMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assistantMessageId => $composableBuilder(
    column: $table.assistantMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itineraryId => $composableBuilder(
    column: $table.itineraryId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AssistantMessageAuthor, String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssistantMessageDeliveryState, String>
  get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpochMs => $composableBuilder(
    column: $table.updatedAtEpochMs,
    builder: (column) => column,
  );

  $$AssistantConversationsTableAnnotationComposer get conversationLocalId {
    final $$AssistantConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableAnnotationComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantMessagesTableTableManager
    extends
        RootTableManager<
          _$AssistantDatabase,
          $AssistantMessagesTable,
          AssistantMessageRecord,
          $$AssistantMessagesTableFilterComposer,
          $$AssistantMessagesTableOrderingComposer,
          $$AssistantMessagesTableAnnotationComposer,
          $$AssistantMessagesTableCreateCompanionBuilder,
          $$AssistantMessagesTableUpdateCompanionBuilder,
          (AssistantMessageRecord, $$AssistantMessagesTableReferences),
          AssistantMessageRecord,
          PrefetchHooks Function({bool conversationLocalId})
        > {
  $$AssistantMessagesTableTableManager(
    _$AssistantDatabase db,
    $AssistantMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssistantMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssistantMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssistantMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> conversationLocalId = const Value.absent(),
                Value<String> clientMessageId = const Value.absent(),
                Value<String?> assistantMessageId = const Value.absent(),
                Value<String?> itineraryId = const Value.absent(),
                Value<AssistantMessageAuthor> author = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<AssistantMessageDeliveryState> deliveryState =
                    const Value.absent(),
                Value<int> createdAtEpochMs = const Value.absent(),
                Value<int> updatedAtEpochMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssistantMessagesCompanion(
                ownerId: ownerId,
                id: id,
                conversationLocalId: conversationLocalId,
                clientMessageId: clientMessageId,
                assistantMessageId: assistantMessageId,
                itineraryId: itineraryId,
                author: author,
                content: content,
                deliveryState: deliveryState,
                createdAtEpochMs: createdAtEpochMs,
                updatedAtEpochMs: updatedAtEpochMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String id,
                required String conversationLocalId,
                required String clientMessageId,
                Value<String?> assistantMessageId = const Value.absent(),
                Value<String?> itineraryId = const Value.absent(),
                required AssistantMessageAuthor author,
                required String content,
                required AssistantMessageDeliveryState deliveryState,
                required int createdAtEpochMs,
                required int updatedAtEpochMs,
                Value<int> rowid = const Value.absent(),
              }) => AssistantMessagesCompanion.insert(
                ownerId: ownerId,
                id: id,
                conversationLocalId: conversationLocalId,
                clientMessageId: clientMessageId,
                assistantMessageId: assistantMessageId,
                itineraryId: itineraryId,
                author: author,
                content: content,
                deliveryState: deliveryState,
                createdAtEpochMs: createdAtEpochMs,
                updatedAtEpochMs: updatedAtEpochMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssistantMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationLocalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationLocalId,
                                referencedTable:
                                    $$AssistantMessagesTableReferences
                                        ._conversationLocalIdTable(db),
                                referencedColumn:
                                    $$AssistantMessagesTableReferences
                                        ._conversationLocalIdTable(db)
                                        .localId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssistantMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AssistantDatabase,
      $AssistantMessagesTable,
      AssistantMessageRecord,
      $$AssistantMessagesTableFilterComposer,
      $$AssistantMessagesTableOrderingComposer,
      $$AssistantMessagesTableAnnotationComposer,
      $$AssistantMessagesTableCreateCompanionBuilder,
      $$AssistantMessagesTableUpdateCompanionBuilder,
      (AssistantMessageRecord, $$AssistantMessagesTableReferences),
      AssistantMessageRecord,
      PrefetchHooks Function({bool conversationLocalId})
    >;
typedef $$AssistantPendingRequestsTableCreateCompanionBuilder =
    AssistantPendingRequestsCompanion Function({
      required String ownerId,
      required String clientMessageId,
      required String conversationLocalId,
      Value<String?> conversationId,
      Value<String?> tripId,
      required String message,
      required String locale,
      required int createdAtEpochMs,
      Value<int> rowid,
    });
typedef $$AssistantPendingRequestsTableUpdateCompanionBuilder =
    AssistantPendingRequestsCompanion Function({
      Value<String> ownerId,
      Value<String> clientMessageId,
      Value<String> conversationLocalId,
      Value<String?> conversationId,
      Value<String?> tripId,
      Value<String> message,
      Value<String> locale,
      Value<int> createdAtEpochMs,
      Value<int> rowid,
    });

final class $$AssistantPendingRequestsTableReferences
    extends
        BaseReferences<
          _$AssistantDatabase,
          $AssistantPendingRequestsTable,
          AssistantPendingRequestRecord
        > {
  $$AssistantPendingRequestsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssistantConversationsTable _conversationLocalIdTable(
    _$AssistantDatabase db,
  ) => db.assistantConversations.createAlias(
    'assistant_pending_requests__conversation_local_id__assistant_conversations__local_id',
  );

  $$AssistantConversationsTableProcessedTableManager get conversationLocalId {
    final $_column = $_itemColumn<String>('conversation_local_id')!;

    final manager = $$AssistantConversationsTableTableManager(
      $_db,
      $_db.assistantConversations,
    ).filter((f) => f.localId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationLocalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssistantPendingRequestsTableFilterComposer
    extends Composer<_$AssistantDatabase, $AssistantPendingRequestsTable> {
  $$AssistantPendingRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  $$AssistantConversationsTableFilterComposer get conversationLocalId {
    final $$AssistantConversationsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableFilterComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantPendingRequestsTableOrderingComposer
    extends Composer<_$AssistantDatabase, $AssistantPendingRequestsTable> {
  $$AssistantPendingRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssistantConversationsTableOrderingComposer get conversationLocalId {
    final $$AssistantConversationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableOrderingComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantPendingRequestsTableAnnotationComposer
    extends Composer<_$AssistantDatabase, $AssistantPendingRequestsTable> {
  $$AssistantPendingRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get clientMessageId => $composableBuilder(
    column: $table.clientMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<int> get createdAtEpochMs => $composableBuilder(
    column: $table.createdAtEpochMs,
    builder: (column) => column,
  );

  $$AssistantConversationsTableAnnotationComposer get conversationLocalId {
    final $$AssistantConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationLocalId,
          referencedTable: $db.assistantConversations,
          getReferencedColumn: (t) => t.localId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssistantConversationsTableAnnotationComposer(
                $db: $db,
                $table: $db.assistantConversations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AssistantPendingRequestsTableTableManager
    extends
        RootTableManager<
          _$AssistantDatabase,
          $AssistantPendingRequestsTable,
          AssistantPendingRequestRecord,
          $$AssistantPendingRequestsTableFilterComposer,
          $$AssistantPendingRequestsTableOrderingComposer,
          $$AssistantPendingRequestsTableAnnotationComposer,
          $$AssistantPendingRequestsTableCreateCompanionBuilder,
          $$AssistantPendingRequestsTableUpdateCompanionBuilder,
          (
            AssistantPendingRequestRecord,
            $$AssistantPendingRequestsTableReferences,
          ),
          AssistantPendingRequestRecord,
          PrefetchHooks Function({bool conversationLocalId})
        > {
  $$AssistantPendingRequestsTableTableManager(
    _$AssistantDatabase db,
    $AssistantPendingRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssistantPendingRequestsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AssistantPendingRequestsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AssistantPendingRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> clientMessageId = const Value.absent(),
                Value<String> conversationLocalId = const Value.absent(),
                Value<String?> conversationId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> createdAtEpochMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssistantPendingRequestsCompanion(
                ownerId: ownerId,
                clientMessageId: clientMessageId,
                conversationLocalId: conversationLocalId,
                conversationId: conversationId,
                tripId: tripId,
                message: message,
                locale: locale,
                createdAtEpochMs: createdAtEpochMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String clientMessageId,
                required String conversationLocalId,
                Value<String?> conversationId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                required String message,
                required String locale,
                required int createdAtEpochMs,
                Value<int> rowid = const Value.absent(),
              }) => AssistantPendingRequestsCompanion.insert(
                ownerId: ownerId,
                clientMessageId: clientMessageId,
                conversationLocalId: conversationLocalId,
                conversationId: conversationId,
                tripId: tripId,
                message: message,
                locale: locale,
                createdAtEpochMs: createdAtEpochMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssistantPendingRequestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationLocalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (conversationLocalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.conversationLocalId,
                                referencedTable:
                                    $$AssistantPendingRequestsTableReferences
                                        ._conversationLocalIdTable(db),
                                referencedColumn:
                                    $$AssistantPendingRequestsTableReferences
                                        ._conversationLocalIdTable(db)
                                        .localId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssistantPendingRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AssistantDatabase,
      $AssistantPendingRequestsTable,
      AssistantPendingRequestRecord,
      $$AssistantPendingRequestsTableFilterComposer,
      $$AssistantPendingRequestsTableOrderingComposer,
      $$AssistantPendingRequestsTableAnnotationComposer,
      $$AssistantPendingRequestsTableCreateCompanionBuilder,
      $$AssistantPendingRequestsTableUpdateCompanionBuilder,
      (
        AssistantPendingRequestRecord,
        $$AssistantPendingRequestsTableReferences,
      ),
      AssistantPendingRequestRecord,
      PrefetchHooks Function({bool conversationLocalId})
    >;

class $AssistantDatabaseManager {
  final _$AssistantDatabase _db;
  $AssistantDatabaseManager(this._db);
  $$AssistantConversationsTableTableManager get assistantConversations =>
      $$AssistantConversationsTableTableManager(
        _db,
        _db.assistantConversations,
      );
  $$AssistantMessagesTableTableManager get assistantMessages =>
      $$AssistantMessagesTableTableManager(_db, _db.assistantMessages);
  $$AssistantPendingRequestsTableTableManager get assistantPendingRequests =>
      $$AssistantPendingRequestsTableTableManager(
        _db,
        _db.assistantPendingRequests,
      );
}
