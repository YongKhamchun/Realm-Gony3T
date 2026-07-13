import 'dart:io';

import 'package:realm/realm.dart';

class RealmUserRepository {
  Realm? _realm;

  String? get openedPath => _realm?.config.path;

  void close() {
    _realm?.close();
    _realm = null;
  }

  List<Map<String, dynamic>> openAndReadUsers(String filePath) {
    close();

    // Validate file exists and is readable
    final File realmFile = File(filePath);
    if (!realmFile.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    try {
      final FileStat stat = realmFile.statSync();
      print('[Realm] File size: ${stat.size} bytes');
    } catch (e) {
      print('[Realm] Cannot stat file: $e');
    }

    try {
      final Configuration config = Configuration.local(
        <SchemaObject>[],
        path: filePath,
      );

      print('[Realm] Creating Realm instance...');
      _realm = Realm(config);
      print('[Realm] ✓ Opened: $filePath');
      print('[Realm] ✓ Schema classes: ${_realm!.schema.length}');

      final SchemaObject? selectedSchema = _pickBestSchema(_realm!.schema);
      if (selectedSchema == null) {
        print('[Realm] ✗ No suitable schema found');
        return <Map<String, dynamic>>[];
      }

      print(
        '[Realm] ✓ Selected: ${selectedSchema.name} (${selectedSchema.length} fields)',
      );

      final RealmResults<RealmObject> rows = _realm!.dynamic.all(
        selectedSchema.name,
      );

      print('[Realm] ✓ Found ${rows.length} objects');

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

      if (errorMsg.contains('file format') || errorMsg.contains('schema')) {
        throw Exception(
          'Invalid or incompatible .realm file.\n'
          'The file may be encrypted, corrupted, or from a different Realm version.',
        );
      }

      rethrow;
    }
  }

  String? pickClassName(String filePath) {
    final Configuration config = Configuration.local(
      <SchemaObject>[],
      path: filePath,
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
          return val;
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
          return object.dynamic.get<Object?>(prop.name);
      }
    } catch (_) {
      return null;
    }
  }

  dynamic _normalizeValue(Object? value) {
    if (value is RealmObject) {
      return _toMap(value);
    }
    return value;
  }
}
