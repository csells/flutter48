import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: '2048',
        home: GameBoard(),
      );
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  static const int size = 4;
  var _board = List.generate(size, (_) => List.filled(size, 0));
  var _score = 0;
  var _bestScore = 0;
  final _random = Random();
  var _gameOver = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadGameState());
  }

  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load board state
      final boardRows = prefs.getStringList('boardState');
      if (boardRows != null) {
        _board = boardRows
            .map((row) => row.split(',').map(int.parse).toList())
            .toList();
      } else {
        _startGame();
      }

      // Load score
      _score = prefs.getInt('currentScore') ?? 0;
      _bestScore = prefs.getInt('bestScore') ?? 0;
      _gameOver = prefs.getBool('gameOver') ?? false;
    });
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    // Save board state as list of comma-separated strings
    await prefs.setStringList(
        'boardState', _board.map((row) => row.join(',')).toList());
    await prefs.setInt('currentScore', _score);
    await prefs.setInt('bestScore', _bestScore);
    await prefs.setBool('gameOver', _gameOver);
  }

  void _startGame() {
    _board = List.generate(size, (_) => List.filled(size, 0));
    _score = 0;
    _gameOver = false;
    _addNewTile();
    _addNewTile();
  }

  void _addNewTile() {
    final emptyTiles = <Point<int>>[];
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        if (_board[i][j] == 0) {
          emptyTiles.add(Point(i, j));
        }
      }
    }

    if (emptyTiles.isEmpty) return;

    final newTilePosition = emptyTiles[_random.nextInt(emptyTiles.length)];
    _board[newTilePosition.x][newTilePosition.y] =
        _random.nextDouble() < 0.9 ? 2 : 4;
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bestScore', _bestScore);
  }

  bool _canMove() {
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        if (_board[i][j] == 0) return true;
        if (i < size - 1 && _board[i][j] == _board[i + 1][j]) return true;
        if (j < size - 1 && _board[i][j] == _board[i][j + 1]) return true;
      }
    }
    return false;
  }

  void _move(DragEndDetails details) {
    if (_gameOver) return;

    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _moveRight();
      } else {
        _moveLeft();
      }
    } else {
      if (dy > 0) {
        _moveDown();
      } else {
        _moveUp();
      }
    }

    if (_score > _bestScore) {
      _bestScore = _score;
      unawaited(_saveBestScore());
    }

    if (!_canMove()) {
      _gameOver = true;
    }
  }

  void _moveLeft() {
    var moved = false;
    for (var i = 0; i < size; i++) {
      var row = <int>[];
      for (var j = 0; j < size; j++) {
        if (_board[i][j] != 0) row.add(_board[i][j]);
      }

      while (row.length < size) {
        row.add(0);
      }

      for (var j = 0; j < row.length - 1; j++) {
        if (row[j] != 0 && row[j] == row[j + 1]) {
          row[j] *= 2;
          row[j + 1] = 0;
          _score += row[j];
          if (_score > _bestScore) {
            _bestScore = _score;
          }
        }
      }

      row = row.where((x) => x != 0).toList();
      while (row.length < size) {
        row.add(0);
      }

      if (row != _board[i]) moved = true;
      _board[i] = row;
    }

    if (moved) {
      _addNewTile();
      unawaited(_saveGameState());
      setState(() {});
    }
  }

  void _moveRight() {
    var moved = false;
    for (var i = 0; i < size; i++) {
      var row = <int>[];
      for (var j = size - 1; j >= 0; j--) {
        if (_board[i][j] != 0) row.add(_board[i][j]);
      }

      while (row.length < size) {
        row.add(0);
      }

      for (var j = 0; j < row.length - 1; j++) {
        if (row[j] != 0 && row[j] == row[j + 1]) {
          row[j] *= 2;
          row[j + 1] = 0;
          _score += row[j];
          if (_score > _bestScore) {
            _bestScore = _score;
          }
        }
      }

      row = row.where((x) => x != 0).toList();
      while (row.length < size) {
        row.add(0);
      }
      row = row.reversed.toList();

      if (row != _board[i]) moved = true;
      _board[i] = row;
    }

    if (moved) {
      _addNewTile();
      unawaited(_saveGameState());
      setState(() {});
    }
  }

  void _moveUp() {
    var moved = false;
    for (var j = 0; j < size; j++) {
      var column = <int>[];
      for (var i = 0; i < size; i++) {
        if (_board[i][j] != 0) column.add(_board[i][j]);
      }

      while (column.length < size) {
        column.add(0);
      }

      for (var i = 0; i < column.length - 1; i++) {
        if (column[i] != 0 && column[i] == column[i + 1]) {
          column[i] *= 2;
          column[i + 1] = 0;
          _score += column[i];
          if (_score > _bestScore) {
            _bestScore = _score;
          }
        }
      }

      column = column.where((x) => x != 0).toList();
      while (column.length < size) {
        column.add(0);
      }

      for (var i = 0; i < size; i++) {
        if (_board[i][j] != column[i]) moved = true;
        _board[i][j] = column[i];
      }
    }

    if (moved) {
      _addNewTile();
      unawaited(_saveGameState());
      setState(() {});
    }
  }

  void _moveDown() {
    var moved = false;
    for (var j = 0; j < size; j++) {
      var column = <int>[];
      for (var i = size - 1; i >= 0; i--) {
        if (_board[i][j] != 0) column.add(_board[i][j]);
      }

      while (column.length < size) {
        column.add(0);
      }

      for (var i = 0; i < column.length - 1; i++) {
        if (column[i] != 0 && column[i] == column[i + 1]) {
          column[i] *= 2;
          column[i + 1] = 0;
          _score += column[i];
          if (_score > _bestScore) {
            _bestScore = _score;
          }
        }
      }

      column = column.where((x) => x != 0).toList();
      while (column.length < size) {
        column.add(0);
      }
      column = column.reversed.toList();

      for (var i = 0; i < size; i++) {
        if (_board[i][j] != column[i]) moved = true;
        _board[i][j] = column[i];
      }
    }

    if (moved) {
      _addNewTile();
      unawaited(_saveGameState());
      setState(() {});
    }
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      default:
        return const Color(0xFFCDC1B4);
    }
  }

  Color _getTileTextColor(int value) =>
      value <= 4 ? const Color(0xFF776E65) : Colors.white;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _moveLeft();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _moveRight();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _moveUp();
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _moveDown();
              }
            }
            return KeyEventResult.handled;
          },
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '2048',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF776E65),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Score: $_score',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Best: $_bestScore',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onPanEnd: _move,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBADA0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        size,
                        (i) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            size,
                            (j) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 70,
                              height: 70,
                              margin: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _board[i][j] == 0
                                    ? const Color(0xFFCDC1B4)
                                    : _getTileColor(_board[i][j]),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: _board[i][j] == 0
                                    ? null
                                    : Text(
                                        _board[i][j].toString(),
                                        style: TextStyle(
                                          fontSize:
                                              _board[i][j] > 512 ? 24 : 32,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _getTileTextColor(_board[i][j]),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(_startGame);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F7A66),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('New Game'),
                ),
                if (_gameOver) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Game Over!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF776E65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
