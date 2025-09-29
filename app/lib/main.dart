import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page 2'),
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
  static const int minWordLength = 4; // As per game design
  late List<List<String>> letterGrid;
  final String theme = 'Fruits';

  // Track selected cells and found words
  Set<String> selectedCells = {};
  Set<String> foundWords = {};
  List<String> availableWords = [];
  bool isDragging = false;
  
  // Timer tracking
  DateTime? startTime;
  String elapsedTime = '00:00';

  // Convert grid position to string key
  String _posToKey(int row, int col) => '$row,$col';
  
  // Convert key back to position
  (int, int) _keyToPos(String key) {
    final parts = key.split(',').map(int.parse).toList();
    return (parts[0], parts[1]);
  }

  // Get all possible positions for a word
  List<List<String>> _findWordPlacements(String word, Set<String> usedCells) {
    List<List<String>> placements = [];
    
    // Try placing word starting from each cell
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        // Try each direction
        for (var direction in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]) {
          var positions = <String>[];
          bool valid = true;
          
          // Check if word fits in this direction
          for (int i = 0; i < word.length; i++) {
            int newRow = row + (direction.$1 * i);
            int newCol = col + (direction.$2 * i);
            
            if (newRow < 0 || newRow >= gridSize || newCol < 0 || newCol >= gridSize) {
              valid = false;
              break;
            }
            
            String pos = _posToKey(newRow, newCol);
            if (usedCells.contains(pos)) {
              valid = false;
              break;
            }
            
            positions.add(pos);
          }
          
          if (valid) {
            placements.add(positions);
          }
        }
      }
    }
    
    return placements;
  }

  // Get all cells used by remaining words
  Set<String> _getCellsInRemainingWords() {
    Set<String> cells = {};
    for (var word in availableWords) {
      if (!foundWords.contains(word)) {
        // Find all positions where this word exists in the grid
        for (int row = 0; row < gridSize; row++) {
          for (int col = 0; col < gridSize; col++) {
            if (letterGrid[row][col] == word[0]) {
              // Check all directions for the complete word
              for (var dir in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]) {
                var found = true;
                var positions = <String>[];
                
                for (int i = 0; i < word.length; i++) {
                  int newRow = row + (dir.$1 * i);
                  int newCol = col + (dir.$2 * i);
                  
                  if (newRow < 0 || newRow >= gridSize || 
                      newCol < 0 || newCol >= gridSize ||
                      letterGrid[newRow][newCol] != word[i]) {
                    found = false;
                    break;
                  }
                  positions.add(_posToKey(newRow, newCol));
                }
                
                if (found) {
                  cells.addAll(positions);
                }
              }
            }
          }
        }
      }
    }
    return cells;
  }

  // Remove letters that aren't part of any remaining words
  void _removeUnusedLetters() {
    final usedCells = _getCellsInRemainingWords();
    setState(() {
      for (int row = 0; row < gridSize; row++) {
        for (int col = 0; col < gridSize; col++) {
          if (!usedCells.contains(_posToKey(row, col))) {
            letterGrid[row][col] = ' ';
          }
        }
      }
    });
  }

  // Handle touch position and convert to grid position
  void _handleTouchSelection(Offset localPosition, double cellSize) {
    final row = (localPosition.dy / cellSize).floor();
    final col = (localPosition.dx / cellSize).floor();
    
    if (row >= 0 && row < gridSize && col >= 0 && col < gridSize) {
      _handleCellSelection(row, col);
    }
  }

  // Check if two cells are adjacent (including diagonally)
  bool _areAdjacent(String pos1, String pos2) {
    final p1 = pos1.split(',').map(int.parse).toList();
    final p2 = pos2.split(',').map(int.parse).toList();
    return (p1[0] - p2[0]).abs() <= 1 && (p1[1] - p2[1]).abs() <= 1;
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        final diff = DateTime.now().difference(startTime!);
        final minutes = diff.inMinutes.toString().padLeft(2, '0');
        final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
        elapsedTime = '$minutes:$seconds';
      });
      
      return foundWords.length < availableWords.length;
    });
  }

  // Get the currently selected word
  String _getCurrentWord() {
    final List<String> sortedCells = selectedCells.toList()..sort();
    return sortedCells.map((pos) {
      final coords = pos.split(',').map(int.parse).toList();
      return letterGrid[coords[0]][coords[1]];
    }).join('');
  }

  // Check if the selected cells form a valid word
  void _checkWord() {
    if (selectedCells.isEmpty) return;
    
    final word = _getCurrentWord();
    if (word.length >= minWordLength && 
        themeWords.contains(word) && 
        !foundWords.contains(word)) {
      setState(() {
        foundWords.add(word);
        // Remove letters that aren't used in remaining words
        _removeUnusedLetters();
      });
    }
    setState(() {
      selectedCells.clear();
    });
  }

  // Handle cell selection
  void _handleCellSelection(int row, int col) {
    final pos = _posToKey(row, col);
    
    if (!isDragging) {
      setState(() {
        selectedCells.clear();
        selectedCells.add(pos);
      });
      return;
    }

    if (selectedCells.isEmpty) {
      setState(() {
        selectedCells.add(pos);
      });
    } else if (!selectedCells.contains(pos)) {
      // Check if the new cell is adjacent to the last selected cell
      final lastCell = selectedCells.last;
      if (_areAdjacent(lastCell, pos)) {
        setState(() {
          selectedCells.add(pos);
        });
      }
    }
  }
  final List<String> themeWords = [
    'PEAR',
    'LIME',
    'PLUM',
    'KIWI',
    'APPLE',
    'MANGO',
    'GRAPE',
    'MELON',
  ]; // Words that can fit in grid

  @override
  void initState() {
    super.initState();
    letterGrid = _generateThemedGrid();
    availableWords = themeWords.where((w) => w.length >= minWordLength).toList();
    startTime = DateTime.now();
    _startTimer();
  }

  List<List<String>> _generateThemedGrid() {
    int maxAttempts = 100;
    while (maxAttempts > 0) {
      List<List<String>> grid = List.generate(gridSize, (i) => List.filled(gridSize, ''));
      Set<String> usedCells = {};
      List<String> placedWords = [];
      
      // Filter and prepare words that can fit in the grid
      final wordsToPlace = themeWords
        .where((w) => w.length >= minWordLength && w.length <= gridSize * 2)
        .map((w) => w.toUpperCase())
        .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      
      // Try to place each word
      for (String word in wordsToPlace) {
        var placements = _findWordPlacements(word, usedCells);
        if (placements.isNotEmpty) {
          placements.shuffle();
          var placement = placements.first;
          
          // Place the word
          for (int i = 0; i < word.length; i++) {
            var (row, col) = _keyToPos(placement[i]);
            grid[row][col] = word[i];
            usedCells.add(placement[i]);
          }
          placedWords.add(word);
        }
      }
      
      // Only use grid if we placed enough words
      if (placedWords.length >= 4) {
        // Fill remaining cells with letters from the words
        String availableLetters = placedWords.join();
        for (int row = 0; row < gridSize; row++) {
          for (int col = 0; col < gridSize; col++) {
            if (grid[row][col].isEmpty) {
              grid[row][col] = availableLetters[
                (row * gridSize + col + DateTime.now().millisecondsSinceEpoch) % 
                availableLetters.length
              ];
            }
          }
        }
        
        // Update available words to only include placed words
        availableWords = placedWords;
        return grid;
      }
      
      maxAttempts--;
    }
    
    // Fallback grid if placement fails
    return List.generate(
      gridSize,
      (i) => List.generate(
        gridSize,
        (j) => themeWords[0][((i * gridSize + j) % themeWords[0].length)]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Theme: $theme'),
                Text('Time: $elapsedTime'),
              ],
            ),
            Text(
              'Found ${foundWords.length}/${availableWords.length} words',
              style: const TextStyle(fontSize: 16),
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
                    _handleTouchSelection(details.localPosition, cellSize);
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
                        children: List.generate(gridSize * gridSize, (index) {
                          final row = index ~/ gridSize;
                          final col = index % gridSize;
                          final isSelected = selectedCells.contains(_posToKey(row, col));
                          
                          return Positioned(
                            left: col * cellSize,
                            top: row * cellSize,
                            width: cellSize,
                            height: cellSize,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(4),
                                color: isSelected ? Colors.lightBlue.withOpacity(0.3) : null,
                              ),
                              child: Center(
                                child: Text(
                                  letterGrid[row][col],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: availableWords.map((word) {
                final found = foundWords.contains(word);
                return Text(
                  word,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: found ? TextDecoration.lineThrough : null,
                    color: found ? Colors.grey : Colors.black,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
