import 'package:flutter/material.dart';
import 'dart:math' show sqrt;

void main() {
  runApp(const MyApp());
}

class Puzzle {
  final String theme;
  final List<List<String>> grid;
  final List<String> words;

  const Puzzle({
    required this.theme,
    required this.grid,
    required this.words,
  });
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

  Color _interpolateColor(Color a, Color b, double t) {
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * t).round(),
      (a.red + (b.red - a.red) * t).round(),
      (a.green + (b.green - a.green) * t).round(),
      (a.blue + (b.blue - b.blue) * t).round(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedCellsOrder.isEmpty) return;

    const maxWordLength = 16;
    final startColor = Colors.green;
    final endColor = Colors.purple;
    
    final paint = Paint()
      ..strokeWidth = 75.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw background paths first
    final backgroundPaint = Paint()
      ..strokeWidth = 75.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = Colors.white;  // White background for contrast

    if (selectedCellsOrder.length == 1) {
      // For a single selected letter, draw a circle
      final current = selectedCellsOrder[0].split(',').map(int.parse).toList();
      final centerX = (current[1] + 0.5) * cellSize;
      final centerY = (current[0] + 0.5) * cellSize;
      
      // Draw white background circle first
      canvas.drawCircle(
        Offset(centerX, centerY),
        5.0, // Small radius for the dot
        backgroundPaint,
      );
      
      // Draw colored circle
      paint.color = startColor;
      canvas.drawCircle(
        Offset(centerX, centerY),
        5.0, // Small radius for the dot
        paint,
      );
      return;
    }

    // For multiple selected letters, draw lines
    for (int i = 0; i < selectedCellsOrder.length - 1; i++) {
      final current = selectedCellsOrder[i].split(',').map(int.parse).toList();
      final next = selectedCellsOrder[i + 1].split(',').map(int.parse).toList();

      final startX = (current[1] + 0.5) * cellSize;
      final startY = (current[0] + 0.5) * cellSize;
      final endX = (next[1] + 0.5) * cellSize;
      final endY = (next[0] + 0.5) * cellSize;

      // Draw white background line first
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        backgroundPaint,
      );

      // Always progress the color regardless of direction
      final progress = i / (maxWordLength - 1);
      paint.color = _interpolateColor(startColor, endColor, progress);

      // Draw the colored line
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
  late String theme;
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

  // Current puzzle tracking
  int currentPuzzleIndex = 0;
  bool showNextPuzzleButton = false;

  final List<Puzzle> puzzles = [
    Puzzle(
      theme: 'Venomous creatures',
      grid: [
        ['V', 'U', 'D', 'W'],
        ['Q', 'I', 'A', 'E'],
        ['O', 'S', 'P', 'R'],
        ['N', 'C', 'O', 'B'],
      ],
      words: ['COBRA', 'SCORPION', 'SPIDER', 'SQUID', 'VIPER', 'WASP'],
    ),
    Puzzle(
      theme: 'Värvid',
      grid: [
        ['K', 'S', 'I', 'L'],
        ['P', 'O', 'L', 'N'],
        ['U', 'E', 'I', 'L'],
        ['N', 'A', 'N', 'A'],
      ],
      words: ['SININE', 'KOLLANE', 'PUNANE', 'LILLA'],
    ),
  ];

  void _resetGame([int? puzzleIndex]) {
    setState(() {
      if (puzzleIndex != null) {
        currentPuzzleIndex = puzzleIndex;
      }
      final puzzle = puzzles[currentPuzzleIndex];
      letterGrid = List.from(puzzle.grid.map((row) => List<String>.from(row)));
      theme = puzzle.theme;
      availableWords = puzzle.words.toList();
      foundWords.clear();
      selectedCells.clear();
      selectedCellsOrder.clear();
      hasWon = false;
      showNextPuzzleButton = false;
      startTime = DateTime.now();
      elapsedTime = '00:00';
    });
    _startTimer();
  }

  String _posToKey(int row, int col) => '$row,$col';

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
          _handleCellSelection(row, col, isClick: false);
          return;
        }
      }
    }
  }

  void _handleCellSelection(int row, int col, {bool isClick = false}) {
    // Don't select empty cells
    if (letterGrid[row][col].trim().isEmpty) {
      return;
    }

    final pos = _posToKey(row, col);
    
    // Only clear selection if starting a new drag, not on click
    if (!isDragging && selectedCells.isEmpty) {
      setState(() {
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
      // If clicking the first selected letter, clear and start new selection from it
      if (isClick && selectedCellsOrder.isNotEmpty && selectedCellsOrder[0] == pos) {
        setState(() {
          selectedCells.clear();
          selectedCellsOrder.clear();
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
        });
      } else if (selectedCellsOrder.length > 1 && selectedCellsOrder[selectedCellsOrder.length - 2] == pos) {
        setState(() {
          String lastPos = selectedCellsOrder.removeLast();
          selectedCells.remove(lastPos);
        });
      } else if (isClick) {
        // If clicked cell is not adjacent to last, reset selection and start new
        final lastCell = selectedCellsOrder.last;
        if (!_areAdjacent(lastCell, pos)) {
          setState(() {
            selectedCells.clear();
            selectedCellsOrder.clear();
            selectedCells.add(pos);
            selectedCellsOrder.add(pos);
          });
        }
      }
    } else if (!selectedCells.contains(pos)) {
      final lastCell = selectedCellsOrder.last;
      if (_areAdjacent(lastCell, pos)) {
        setState(() {
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
        });
      } else if (isClick) {
        // If clicked cell is not adjacent, reset selection and start new
        setState(() {
          selectedCells.clear();
          selectedCellsOrder.clear();
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
        });
      }
    }
  }

  // Finds all possible paths for a word starting from a given position
  List<List<String>> _findPossiblePaths(String word, int startRow, int startCol, Set<String> visited) {
    if (word.isEmpty) return [[]];
    
    List<List<String>> paths = [];
    String pos = _posToKey(startRow, startCol);
    
    if (letterGrid[startRow][startCol] != word[0] || visited.contains(pos)) {
      return paths;
    }
    
    if (word.length == 1) {
      return [[pos]];
    }
    
    visited.add(pos);
    
    // Check all adjacent cells
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        
        int newRow = startRow + dr;
        int newCol = startCol + dc;
        
        if (newRow >= 0 && newRow < gridSize && 
            newCol >= 0 && newCol < gridSize) {
          var subPaths = _findPossiblePaths(
            word.substring(1),
            newRow,
            newCol,
            Set.from(visited)
          );
          
          for (var subPath in subPaths) {
            paths.add([pos, ...subPath]);
          }
        }
      }
    }
    
    return paths;
  }

  // Check if a letter at a specific position is needed for remaining words
  bool _isPositionNeededForRemainingWords(int row, int col) {
    String pos = _posToKey(row, col);
    
    // Check each remaining unfound word
    for (var word in puzzles[currentPuzzleIndex].words) {
      if (!foundWords.contains(word)) {
        // Check if any valid path for this word uses this position
        for (int startRow = 0; startRow < gridSize; startRow++) {
          for (int startCol = 0; startCol < gridSize; startCol++) {
            var paths = _findPossiblePaths(word, startRow, startCol, {});
            for (var path in paths) {
              if (path.contains(pos)) {
                return true; // This position is needed for a valid path
              }
            }
          }
        }
      }
    }
    return false;
  }

  void _checkWord() {
    final word = _getCurrentWord();
    if (word.length >= minWordLength && 
        puzzles[currentPuzzleIndex].words.contains(word) && 
        !foundWords.contains(word)) {
      setState(() {
        foundWords.add(word);
        // Clear letters only if they're not needed for remaining words
        for (String pos in selectedCellsOrder) {
          final coords = pos.split(',').map(int.parse).toList();
          if (!_isPositionNeededForRemainingWords(coords[0], coords[1])) {
            letterGrid[coords[0]][coords[1]] = ' ';
          }
        }
        // Check if player has won
        print('Found words: ${foundWords.toList()}');
        print('Theme words: ${puzzles[currentPuzzleIndex].words}');
        // Check if all words are found
        bool allWordsFound = puzzles[currentPuzzleIndex].words.every((word) => foundWords.contains(word));
        if (allWordsFound) {
          print('All words found!');
          hasWon = true;
          finalTime = elapsedTime;
          showNextPuzzleButton = currentPuzzleIndex < puzzles.length - 1;
        }
        // Only clear selection if a valid word was found
        selectedCells.clear();
        selectedCellsOrder.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final puzzle = puzzles[currentPuzzleIndex];
    letterGrid = List.from(puzzle.grid.map((row) => List<String>.from(row)));
    theme = puzzle.theme;
    availableWords = puzzle.words.toList();
    startTime = DateTime.now();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: currentPuzzleIndex > 0
              ? () => _resetGame(currentPuzzleIndex - 1)
              : null,
        ),
        title: Text('${widget.title} - ${currentPuzzleIndex + 1}/${puzzles.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentPuzzleIndex < puzzles.length - 1
                ? () => _resetGame(currentPuzzleIndex + 1)
                : null,
          ),
        ],
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
                    Text(
                      'Theme: $theme',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Time: $elapsedTime',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Found ${foundWords.length}/${puzzles[currentPuzzleIndex].words.length} words',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCells.clear();
                      selectedCellsOrder.clear();
                    });
                  },
                  child: const Text('Reset Word'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
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
                    return Column(
                      children: [
                        GestureDetector(
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
                            // No outer border for the grid
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                children: [
                                  // Bottom layer: Grid cell circles
                                  ...List.generate(gridSize * gridSize, (index) {
                                    final row = index ~/ gridSize;
                                    final col = index % gridSize;
                                    final pos = _posToKey(row, col);
                                    return Positioned(
                                      left: col * cellSize,
                                      top: row * cellSize,
                                      width: cellSize,
                                      height: cellSize,
                                      child: GestureDetector(
                                        onTap: () {
                                          _handleCellSelection(row, col, isClick: true);
                                          WidgetsBinding.instance.addPostFrameCallback((_) => _checkWord());
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8), // Small radius for boxy look
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 2,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  // Middle layer: Selection lines
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
                                  // Top layer: Letters
                                  ...List.generate(gridSize * gridSize, (index) {
                                    final row = index ~/ gridSize;
                                    final col = index % gridSize;
                                    final isSelected = selectedCells.contains(_posToKey(row, col));
                                    
                                    return Positioned(
                                      left: col * cellSize,
                                      top: row * cellSize,
                                      width: cellSize,
                                      height: cellSize,
                                      child: Center(
                                        child: Text(
                                          letterGrid[row][col],
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Removed Submit Word button
                      ],
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
                        children: puzzles[currentPuzzleIndex].words.map((word) {
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
                      if (showNextPuzzleButton)
                        ElevatedButton.icon(
                          onPressed: () => _resetGame(currentPuzzleIndex + 1),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next Puzzle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _resetGame(0),
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