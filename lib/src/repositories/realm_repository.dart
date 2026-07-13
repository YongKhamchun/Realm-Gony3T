import 'dart:convert';
import 'dart:io';

import 'package:realm/realm.dart';

class RealmClassSummary {
  const RealmClassSummary({
    required this.name,
    required this.count,
    required this.fields,
  });

  final String name;
  final int count;
  final List<String> fields;
}

class RealmUserRepository {
  Realm? _realm;
  String? _openedSchemaName;

  String? get openedPath => _realm?.config.path;
  String? get openedSchemaName => _openedSchemaName;

  void close() {
    _realm?.close();
    _realm = null;
    _openedSchemaName = null;
  }

  List<Map<String, dynamic>> openAndReadUsers(
    String filePath, {
    String? encryptionKeyInput,
  }) {
    close();

    // Validate file exists and is readable
    final File realmFile = File(filePath);
    if (!realmFile.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    try {
      final FileStat stat = realmFile.statSync();
      if (stat.modeString().contains('w')) {
        throw Exception(
          'File is writable. Please ensure the file is read-only.',
        );
      }
    } catch (e) {
      throw Exception('Cannot access file: $filePath\n$e');
    }

    try {
      final List<int>? encryptionKey = _parseEncryptionKey(encryptionKeyInput);
      final Configuration config = Configuration.local(
        <SchemaObject>[],
        path: filePath,
        encryptionKey: encryptionKey,
        isReadOnly: true,
      );

      _realm = Realm(config);

      final SchemaObject? selectedSchema = _pickBestSchema(_realm!.schema);
      if (selectedSchema == null) {
        _openedSchemaName = null;
        return <Map<String, dynamic>>[];
      }

      _openedSchemaName = selectedSchema.name;

      final RealmResults<RealmObject> rows = _realm!.dynamic.all(
        selectedSchema.name,
      );

      return rows
          .map((RealmObject object) => _toMap(object))
          .toList(growable: false);
    } on Exception catch (e) {
      final String errorMsg = e.toString();

      if (errorMsg.contains('Platform.resolvedExecutable')) {
        throw Exception(
          'Realm library initialization failed. '
          'This is a known issue in macOS Flutter desktop.\n'
          'Solution: Run with "flutter run --release" or "flutter run --profile"',
        );
      }

      if (errorMsg.contains('RLM_ERR_FILE_PERMISSION_DENIED') ||
          errorMsg.contains('Operation not permitted')) {
        throw Exception(
          'No file permission for this Realm path.\n'
          'On macOS, allow the app to access Desktop/Documents/Downloads, '
          'or use file picker to grant access.',
        );
      }

      if (errorMsg.contains('file format') || errorMsg.contains('schema')) {
        throw Exception(
          'Invalid or incompatible .realm file.\n'
          'The file may be encrypted, corrupted, or from a different Realm version.',
        );
      }

      if (errorMsg.toLowerCase().contains('decrypt') ||
          errorMsg.toLowerCase().contains('encryption')) {
        throw Exception(
          'Cannot decrypt realm file. Check your encryption key and try again.',
        );
      }

      rethrow;
    }
  }

  List<RealmClassSummary> openAndListClasses(
    String filePath, {
    String? encryptionKeyInput,
  }) {
    close();

    final File realmFile = File(filePath);
    if (!realmFile.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    try {
      final List<int>? encryptionKey = _parseEncryptionKey(encryptionKeyInput);
      final Configuration config = Configuration.local(
        <SchemaObject>[],
        path: filePath,
        encryptionKey: encryptionKey,
        isReadOnly: true,
      );

      _realm = Realm(config);

      final List<SchemaObject> classSchemas =
          _realm!.schema
              .where((SchemaObject s) => s.baseType == ObjectType.realmObject)
              .toList(growable: false)
            ..sort(
              (SchemaObject a, SchemaObject b) => a.name.compareTo(b.name),
            );

      final List<RealmClassSummary> summaries = classSchemas
          .map(
            (SchemaObject schema) => RealmClassSummary(
              name: schema.name,
              count: _safeCount(schema.name),
              fields: schema
                  .map((SchemaProperty property) => property.mapTo)
                  .toList(growable: false),
            ),
          )
          .toList(growable: false);

      _openedSchemaName = summaries.isEmpty ? null : summaries.first.name;
      return summaries;
    } on Exception catch (e) {
      final String errorMsg = e.toString();

      if (errorMsg.contains('Platform.resolvedExecutable')) {
        throw Exception(
          'Realm library initialization failed. '
          'This is a known issue in macOS Flutter desktop.\n'
          'Solution: Run with "flutter run --release" or "flutter run --profile"',
        );
      }

      if (errorMsg.contains('RLM_ERR_FILE_PERMISSION_DENIED') ||
          errorMsg.contains('Operation not permitted')) {
        throw Exception(
          'No file permission for this Realm path.\n'
          'On macOS, allow the app to access Desktop/Documents/Downloads, '
          'or use file picker to grant access.',
        );
      }

      if (errorMsg.contains('file format') || errorMsg.contains('schema')) {
        throw Exception(
          'Invalid or incompatible .realm file.\n'
          'The file may be encrypted, corrupted, or from a different Realm version.',
        );
      }

      if (errorMsg.toLowerCase().contains('decrypt') ||
          errorMsg.toLowerCase().contains('encryption')) {
        throw Exception(
          'Cannot decrypt realm file. Check your encryption key and try again.',
        );
      }

      rethrow;
    }
  }

  List<Map<String, dynamic>> readClassDocuments(String className) {
    final Realm? realm = _realm;
    if (realm == null) {
      throw Exception('No realm file is currently opened.');
    }

    _openedSchemaName = className;
    final RealmResults<RealmObject> rows = realm.dynamic.all(className);
    return rows
        .map((RealmObject object) => _toMap(object))
        .toList(growable: false);
  }

  List<int>? _parseEncryptionKey(String? rawInput) {
    final String input = rawInput?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }

    try {
      final List<int> decoded = base64Decode(input);
      if (decoded.length == 64) {
        return decoded;
      }
    } catch (_) {
      // Ignore and continue to other key formats.
    }

    final RegExp hexPattern = RegExp(r'^[0-9a-fA-F]{128}$');
    if (hexPattern.hasMatch(input)) {
      return List<int>.generate(
        64,
        (int index) =>
            int.parse(input.substring(index * 2, index * 2 + 2), radix: 16),
        growable: false,
      );
    }

    final List<int> utf8Key = utf8.encode(input);
    if (utf8Key.length == 64) {
      return utf8Key;
    }

    throw Exception(
      'Invalid encryption key format.\n'
      'Use one of:\n'
      '- Base64 that decodes to 64 bytes\n'
      '- 128-character hex string\n'
      '- Plain text with exactly 64 characters',
    );
  }

  String? pickClassName(String filePath) {
    final Configuration config = Configuration.local(
      <SchemaObject>[],
      path: filePath,
      isReadOnly: true,
    );
    final Realm realm = Realm(config);
    try {
      final SchemaObject? schema = _pickBestSchema(realm.schema);
      return schema?.name;
    } finally {
      realm.close();
    }
  }

  SchemaObject? _pickBestSchema(RealmSchema schema) {
    final List<SchemaObject> candidates = schema
        .where((SchemaObject s) => s.baseType == ObjectType.realmObject)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((SchemaObject a, SchemaObject b) {
      return b.length.compareTo(a.length);
    });

    return candidates.first;
  }

  int _safeCount(String className) {
    try {
      return _realm!.dynamic.all(className).length;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> _toMap(RealmObject object) {
    final Map<String, dynamic> output = <String, dynamic>{};
    for (final SchemaProperty prop in object.objectSchema) {
      try {
        final String fieldName = prop.mapTo;
        final dynamic value = _readValue(object, prop);
        output[fieldName] = value;
      } catch (e) {
        // Gracefully skip fields that cannot be read
        output[prop.name] = null;
      }
    }
    if (!output.containsKey('_id')) {
      output['_id'] = '(no primary key)';
    }
    return output;
  }

  dynamic _readValue(RealmObject object, SchemaProperty prop) {
    try {
      switch (prop.collectionType) {
        case RealmCollectionType.none:
          final dynamic val = object.dynamic.get<Object?>(prop.name);
          return _normalizeValue(val);
        case RealmCollectionType.list:
          try {
            return object.dynamic
                .getList<Object?>(prop.name)
                .map((Object? e) => _normalizeValue(e))
                .toList(growable: false);
          } catch (_) {
            return <dynamic>[];
          }
        case RealmCollectionType.map:
          try {
            return object.dynamic
                .getMap<Object?>(prop.name)
                .map(
                  (String key, Object? value) =>
                      MapEntry<String, dynamic>(key, _normalizeValue(value)),
                )
                .cast<String, dynamic>();
          } catch (_) {
            return <String, dynamic>{};
          }
        case RealmCollectionType.set:
          try {
            return object.dynamic
                .getSet<Object?>(prop.name)
                .map((Object? e) => _normalizeValue(e))
                .toList(growable: false);
          } catch (_) {
            return <dynamic>[];
          }
        default:
          return _normalizeValue(object.dynamic.get<Object?>(prop.name));
      }
    } catch (_) {
      return null;
    }
  }

  dynamic _normalizeValue(Object? value) {
    if (value is RealmObject) {
      return _toMap(value);
    }
    if (value is EmbeddedObject) {
      final Map<String, dynamic> output = <String, dynamic>{};
      for (final SchemaProperty prop in value.objectSchema) {
        try {
          output[prop.mapTo] = _normalizeValue(
            value.dynamic.get<Object?>(prop.name),
          );
        } catch (_) {
          output[prop.name] = null;
        }
      }
      return output;
    }
    return value;
  }
}
