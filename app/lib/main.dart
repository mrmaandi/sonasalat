import 'package:flutter/material.dart';
import 'dart:math' show sqrt;

void main() {
  runApp(const MyApp());
}

class SelectionLinePainter extends CustomPainter {
  final List<String> selectedCellsOrder;
  final double cellSize;
  final int gridSize;

  SelectionLinePainter({
    required this.selectedCellsOrder,
    required this.cellSize,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedCellsOrder.length < 2) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < selectedCellsOrder.length - 1; i++) {
      final current = selectedCellsOrder[i].split(',').map(int.parse).toList();
      final next = selectedCellsOrder[i + 1].split(',').map(int.parse).toList();

      final startX = (current[1] + 0.5) * cellSize;
      final startY = (current[0] + 0.5) * cellSize;
      final endX = (next[1] + 0.5) * cellSize;
      final endY = (next[0] + 0.5) * cellSize;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SelectionLinePainter oldDelegate) {
    return oldDelegate.selectedCellsOrder != selectedCellsOrder;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Search Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Word Search Game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int gridSize = 4;
  static const int minWordLength = 4;
  late List<List<String>> letterGrid;
  final String theme = 'Venomous creatures';
  bool hasWon = false;
  String finalTime = '';

  // Track selected cells and found words
  Set<String> selectedCells = {};
  List<String> selectedCellsOrder = [];
  Set<String> foundWords = {};
  List<String> availableWords = [];
  bool isDragging = false;
  
  // Timer tracking
  DateTime? startTime;
  String elapsedTime = '00:00';

  final List<String> themeWords = [
    'COBRA',
    'SCORPION',
    'SPIDER',
    'SQUID',
    'VIPER',
    'WASP',
  ];

  void _resetGame() {
    setState(() {
      letterGrid = _generateThemedGrid();
      availableWords = themeWords.toList();
      foundWords.clear();
      selectedCells.clear();
      selectedCellsOrder.clear();
      hasWon = false;
      startTime = DateTime.now();
      elapsedTime = '00:00';
    });
    _startTimer();
  }

  String _posToKey(int row, int col) => '$row,$col';
  
  bool _isLetterInRemainingWords(String letter) {
    for (var word in themeWords) {
      if (!foundWords.contains(word) && word.contains(letter)) {
        return true;
      }
    }
    return false;
  }

  void _removeUnusedLetters() {
    List<List<String>> newGrid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => letterGrid[i][j])
    );

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (!_isLetterInRemainingWords(letterGrid[i][j])) {
          newGrid[i][j] = ' ';
        }
      }
    }

    setState(() {
      letterGrid = newGrid;
    });
  }

  List<List<String>> _generateThemedGrid() {
    // Return the exact example grid
    return [
      ['V', 'U', 'D', 'W'],
      ['Q', 'I', 'A', 'E'],
      ['O', 'S', 'P', 'R'],
      ['N', 'C', 'O', 'B'],
    ];
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || hasWon) return false;
      
      setState(() {
        final diff = DateTime.now().difference(startTime!);
        final minutes = diff.inMinutes.toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        elapsedTime = '$minutes:$seconds';
      });
      
      return true;
    });
  }

  String _getCurrentWord() {
    return selectedCellsOrder.map((pos) {
      final coords = pos.split(',').map(int.parse).toList();
      return letterGrid[coords[0]][coords[1]];
    }).join('');
  }

  bool _areAdjacent(String pos1, String pos2) {
    final p1 = pos1.split(',').map(int.parse).toList();
    final p2 = pos2.split(',').map(int.parse).toList();
    return (p1[0] - p2[0]).abs() <= 1 && (p1[1] - p2[1]).abs() <= 1;
  }

  void _handleTouchSelection(Offset localPosition, double cellSize) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final centerX = (col + 0.5) * cellSize;
        final centerY = (row + 0.5) * cellSize;
        
        final dx = localPosition.dx - centerX;
        final dy = localPosition.dy - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        
        final radius = cellSize * 0.4;
        
        if (distance <= radius) {
          _handleCellSelection(row, col);
          return;
        }
      }
    }
  }

  void _handleCellSelection(int row, int col) {
    // Don't select empty cells
    if (letterGrid[row][col].trim().isEmpty) {
      return;
    }

    final pos = _posToKey(row, col);
    
    if (!isDragging) {
      setState(() {
        selectedCells.clear();
        selectedCellsOrder.clear();
        selectedCells.add(pos);
        selectedCellsOrder.add(pos);
      });
      return;
    }

    if (selectedCells.isEmpty) {
      setState(() {
        selectedCells.add(pos);
        selectedCellsOrder.add(pos);
      });
    } else if (selectedCells.contains(pos)) {
      // If we're swiping back to the last-but-one selected cell, remove the last cell
      if (selectedCellsOrder.length > 1 && 
          selectedCellsOrder[selectedCellsOrder.length - 2] == pos) {
        setState(() {
          String lastPos = selectedCellsOrder.removeLast();
          selectedCells.remove(lastPos);
        });
      }
    } else if (!selectedCells.contains(pos)) {
      final lastCell = selectedCellsOrder.last;
      if (_areAdjacent(lastCell, pos)) {
        setState(() {
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
        });
      }
    }
  }

  void _checkWord() {
    final word = _getCurrentWord();
    if (word.length >= minWordLength && 
        themeWords.contains(word) && 
        !foundWords.contains(word)) {
      setState(() {
        foundWords.add(word);
        _removeUnusedLetters();
        
        // Check if player has won
        print('Found words: ${foundWords.toList()}');
        print('Theme words: $themeWords');
        
        // Check if all theme words are found
        bool allWordsFound = themeWords.every((word) => foundWords.contains(word));
        if (allWordsFound) {
          print('All words found! Setting hasWon to true');
          hasWon = true;
          finalTime = elapsedTime;
        }
      });
    }
    setState(() {
      selectedCells.clear();
      selectedCellsOrder.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    letterGrid = _generateThemedGrid();
    availableWords = themeWords.toList();
    startTime = DateTime.now();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Theme: $theme'),
                    Text('Time: $elapsedTime'),
                  ],
                ),
                Text(
                  'Found ${foundWords.length}/${themeWords.length} words',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    selectedCells.isEmpty ? 'Select letters to form a word' : _getCurrentWord(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = constraints.maxWidth / gridSize;
                    return GestureDetector(
                      onPanStart: (details) {
                        isDragging = true;
                        _handleTouchSelection(details.localPosition, cellSize);
                      },
                      onPanUpdate: (details) {
                        if (!isDragging) return;
                        if (details.localPosition.dx >= 0 && 
                            details.localPosition.dx <= cellSize * gridSize &&
                            details.localPosition.dy >= 0 && 
                            details.localPosition.dy <= cellSize * gridSize) {
                          _handleTouchSelection(details.localPosition, cellSize);
                        }
                      },
                      onPanEnd: (_) {
                        isDragging = false;
                        _checkWord();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              // Custom paint for drawing lines
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return CustomPaint(
                                    size: Size(constraints.maxWidth, constraints.maxHeight),
                                    painter: SelectionLinePainter(
                                      selectedCellsOrder: selectedCellsOrder,
                                      cellSize: cellSize,
                                      gridSize: gridSize,
                                    ),
                                  );
                                },
                              ),
                              // Grid cells
                              ...List.generate(gridSize * gridSize, (index) {
                                final row = index ~/ gridSize;
                                final col = index % gridSize;
                                final isSelected = selectedCells.contains(_posToKey(row, col));
                                
                                return Positioned(
                                left: col * cellSize,
                                top: row * cellSize,
                                width: cellSize,
                                height: cellSize,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(width: 2),
                                    color: isSelected && letterGrid[row][col].trim().isNotEmpty 
                                      ? Colors.lightBlue.withOpacity(0.3) 
                                      : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      letterGrid[row][col],
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                  ]),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Words to find:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: themeWords.map((word) {
                          final found = foundWords.contains(word);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: found ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: found ? Colors.green : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (found)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                if (found)
                                  const SizedBox(width: 4),
                                Text(
                                  word,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: found ? Colors.green : Colors.black,
                                    fontWeight: found ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasWon)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎉 Congratulations! 🎉',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You found all the words!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time: $finalTime',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _resetGame,
                        icon: const Icon(Icons.replay),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}