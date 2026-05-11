<<<<<<< HEAD
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
=======
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
>>>>>>> upstream/main

const String logTable = 'logs';
const String idColumn = '_id';
const String levelColumn = 'level';
const String messageColumn = 'message';
const String timestampColumn = 'timestamp';
const String dbPath = 'logs.db';

enum LogLevels { debug, info, warning, error }

class Log {
  int? id;
  late LogLevels level;
  late String message;
  DateTime timestamp = DateTime.now();

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      idColumn: id,
      levelColumn: level.index,
      messageColumn: message,
      timestampColumn: timestamp.millisecondsSinceEpoch,
    };
    return map;
  }

  Log(this.message, this.level);

  Log.fromMap(Map<String, Object?> map) {
    id = map[idColumn] as int;
<<<<<<< HEAD
    final levelIndex = (map[levelColumn] as int).clamp(
      0,
      LogLevels.values.length - 1,
    );
    level = LogLevels.values.elementAt(levelIndex);
=======
    level = LogLevels.values.elementAt(map[levelColumn] as int);
>>>>>>> upstream/main
    message = map[messageColumn] as String;
    timestamp = DateTime.fromMillisecondsSinceEpoch(
      map[timestampColumn] as int,
    );
  }

  @override
  String toString() {
    return '${timestamp.toString()}: ${level.name}: $message';
  }
}

class LogsProvider {
  LogsProvider({bool runDefaultClear = true}) {
<<<<<<< HEAD
    unawaited(clear(before: DateTime.now().subtract(const Duration(days: 7))));
=======
    clear(before: DateTime.now().subtract(const Duration(days: 7)));
>>>>>>> upstream/main
  }

  Database? db;

  Future<Database> getDB() async {
    db ??= await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
create table if not exists $logTable ( 
  $idColumn integer primary key autoincrement, 
  $levelColumn integer not null,
  $messageColumn text not null,
  $timestampColumn integer not null)
''');
      },
    );
    return db!;
  }

  Future<Log> add(String message, {LogLevels level = LogLevels.info}) async {
    Log l = Log(message, level);
    l.id = await (await getDB()).insert(logTable, l.toMap());
<<<<<<< HEAD

    // Add Sentry breadcrumb
    SentryLevel sentryLevel;
    switch (level) {
      case LogLevels.debug:
        sentryLevel = SentryLevel.debug;
        break;
      case LogLevels.info:
        sentryLevel = SentryLevel.info;
        break;
      case LogLevels.warning:
        sentryLevel = SentryLevel.warning;
        break;
      case LogLevels.error:
        sentryLevel = SentryLevel.error;
        break;
    }
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: sentryLevel, timestamp: l.timestamp),
    );

=======
>>>>>>> upstream/main
    if (kDebugMode) {
      print(l);
    }
    return l;
  }

<<<<<<< HEAD
  Future<Log> logEvent(
    String event,
    Map<String, dynamic> params, {
    LogLevels level = LogLevels.info,
  }) async {
    String message =
        'EVENT: $event | ${params.entries.map((e) => '${e.key}=${e.value}').join(', ')}';
    return add(message, level: level);
  }

=======
>>>>>>> upstream/main
  Future<List<Log>> get({DateTime? before, DateTime? after}) async {
    var where = getWhereDates(before: before, after: after);
    return (await (await getDB()).query(
      logTable,
      where: where.key,
      whereArgs: where.value,
    )).map((e) => Log.fromMap(e)).toList();
  }

  Future<int> clear({DateTime? before, DateTime? after}) async {
    var where = getWhereDates(before: before, after: after);
    var res = await (await getDB()).delete(
      logTable,
      where: where.key,
      whereArgs: where.value,
    );
    if (res > 0) {
<<<<<<< HEAD
      unawaited(
        add(
          plural(
            'clearedNLogsBeforeXAfterY',
            res,
            namedArgs: {'before': before.toString(), 'after': after.toString()},
            name: 'n',
          ),
=======
      add(
        plural(
          'clearedNLogsBeforeXAfterY',
          res,
          namedArgs: {'before': before.toString(), 'after': after.toString()},
          name: 'n',
>>>>>>> upstream/main
        ),
      );
    }
    return res;
  }
}

MapEntry<String?, List<int>?> getWhereDates({
  DateTime? before,
  DateTime? after,
}) {
  List<String> where = [];
  List<int> whereArgs = [];
  if (before != null) {
    where.add('$timestampColumn < ?');
    whereArgs.add(before.millisecondsSinceEpoch);
  }
  if (after != null) {
    where.add('$timestampColumn > ?');
    whereArgs.add(after.millisecondsSinceEpoch);
  }
  return whereArgs.isEmpty
      ? const MapEntry(null, null)
      : MapEntry(where.join(' and '), whereArgs);
}
