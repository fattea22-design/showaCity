import 'dart:async';
import 'dart:io';

import '../domain/game_save.dart';

class GameSaveRepository {
  GameSaveRepository(this.file);

  final File file;

  Future<GameSave> load() async {
    try {
      return GameSave.safeDecode(await file.readAsString());
    } on FileSystemException {
      return const GameSave();
    }
  }

  Future<void> save(GameSave save) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(save.encode(), flush: true);
  }
}
