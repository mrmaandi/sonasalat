import 'package:flutter/material.dart';
import 'dart:math' show sqrt;
import 'util/selection_line_painter.dart';
import 'util/animated_segment_painter.dart';
import 'puzzles.dart';

void main() {
  runApp(const MyApp());
}

class Puzzle {
  final String theme;
  final List<List<String>> grid;
  final List<String> words;

  const Puzzle({required this.theme, required this.grid, required this.words});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sõnasalat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MyHomePage(title: 'Sõnasalat'),
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
  // Track how many letters are revealed for each word
  Map<String, int> revealedLetters = {};
  // Controls trace line disappearance animation
  bool _animateTraceLineOut = false;
  // Track previous segment for reverse animation
  String? _prevSegmentStart;
  String? _prevSegmentEnd;
  // Track if the last action was a removal (for reverse animation)
  bool _lastActionWasRemove = false;
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

  // Track word positions for smart letter removal
  Map<String, List<String>> wordPositions = {}; // word -> list of positions "row,col"

  // puzzles are now imported from puzzles.dart

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
      // Reset revealed letters for all words
      revealedLetters = { for (var w in puzzle.words) w: 0 };
      // Initialize word positions by finding them in the grid
      _initializeWordPositions();
    });
    _startTimer();
  }

  String _posToKey(int row, int col) => '$row,$col';

  // Initialize word positions by finding all possible paths for each word
  void _initializeWordPositions() {
    wordPositions.clear();
    for (var word in puzzles[currentPuzzleIndex].words) {
      for (int startRow = 0; startRow < gridSize; startRow++) {
        for (int startCol = 0; startCol < gridSize; startCol++) {
          var paths = _findPossiblePaths(word, startRow, startCol, {});
          if (paths.isNotEmpty) {
            // Use the first valid path found for this word
            wordPositions[word] = paths.first;
            break;
          }
        }
        if (wordPositions.containsKey(word)) break;
      }
    }
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
    return selectedCellsOrder
        .map((pos) {
          final coords = pos.split(',').map(int.parse).toList();
          return letterGrid[coords[0]][coords[1]];
        })
        .join('');
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
      if (isClick &&
          selectedCellsOrder.isNotEmpty &&
          selectedCellsOrder[0] == pos) {
        setState(() {
          selectedCells.clear();
          selectedCellsOrder.clear();
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
        });
      } else if (selectedCellsOrder.length > 1 &&
          selectedCellsOrder[selectedCellsOrder.length - 2] == pos) {
        setState(() {
          // Store previous segment for reverse animation
          _prevSegmentStart = selectedCellsOrder[selectedCellsOrder.length - 2];
          _prevSegmentEnd = selectedCellsOrder.last;
          String lastPos = selectedCellsOrder.removeLast();
          selectedCells.remove(lastPos);
          _lastActionWasRemove = true;
        });
      } else if (isClick) {
        _lastActionWasRemove = false;
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
          _lastActionWasRemove = false;
        });
      } else if (isClick) {
        // If clicked cell is not adjacent, reset selection and start new
        setState(() {
          selectedCells.clear();
          selectedCellsOrder.clear();
          selectedCells.add(pos);
          selectedCellsOrder.add(pos);
          _lastActionWasRemove = false;
        });
      }
    }
  }

  // Finds all possible paths for a word starting from a given position
  List<List<String>> _findPossiblePaths(
    String word,
    int startRow,
    int startCol,
    Set<String> visited,
  ) {
    if (word.isEmpty) return [[]];

    List<List<String>> paths = [];
    String pos = _posToKey(startRow, startCol);

    if (letterGrid[startRow][startCol] != word[0] || visited.contains(pos)) {
      return paths;
    }

    if (word.length == 1) {
      return [
        [pos],
      ];
    }

    visited.add(pos);

    // Check all adjacent cells
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;

        int newRow = startRow + dr;
        int newCol = startCol + dc;

        if (newRow >= 0 &&
            newRow < gridSize &&
            newCol >= 0 &&
            newCol < gridSize) {
          var subPaths = _findPossiblePaths(
            word.substring(1),
            newRow,
            newCol,
            Set.from(visited),
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
        // Remove letters that are only used by this word
        _removeWordLetters(word);
        
        // Check if player has won
        print('Found words: ${foundWords.toList()}');
        print('Theme words: ${puzzles[currentPuzzleIndex].words}');
        // Check if all words are found
        bool allWordsFound = puzzles[currentPuzzleIndex].words.every(
          (word) => foundWords.contains(word),
        );
        if (allWordsFound) {
          print('All words found!');
          hasWon = true;
          finalTime = elapsedTime;
          showNextPuzzleButton = currentPuzzleIndex < puzzles.length - 1;
        }
        // Animate trace line out, then clear selection after animation
        _animateTraceLineOut = true;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        setState(() {
          selectedCells.clear();
          selectedCellsOrder.clear();
          _animateTraceLineOut = false;
        });
      });
    }
  }

  // Remove letters of a found word, but keep letters shared with remaining words
  void _removeWordLetters(String foundWord) {
    if (!wordPositions.containsKey(foundWord)) return;
    
    List<String> wordPath = wordPositions[foundWord]!;
    Set<String> remainingWords = puzzles[currentPuzzleIndex].words
        .where((word) => !foundWords.contains(word) && word != foundWord)
        .toSet();
    
    for (String position in wordPath) {
      bool isSharedWithOtherWord = false;
      
      // Check if this position is used by any remaining word
      for (String remainingWord in remainingWords) {
        if (wordPositions.containsKey(remainingWord) &&
            wordPositions[remainingWord]!.contains(position)) {
          isSharedWithOtherWord = true;
          break;
        }
      }
      
      // Only remove letter if it's not shared
      if (!isSharedWithOtherWord) {
        final coords = position.split(',').map(int.parse).toList();
        letterGrid[coords[0]][coords[1]] = ' ';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final puzzle = puzzles[currentPuzzleIndex];
    letterGrid = List.from(puzzle.grid.map((row) => List<String>.from(row)));
    theme = puzzle.theme;
    availableWords = puzzle.words.toList();
    _initializeWordPositions();
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
        title: Text(
          '${widget.title} - ${currentPuzzleIndex + 1}/${puzzles.length}',
        ),
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
                      'Teema: $theme',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Aeg: $elapsedTime',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCells.clear();
                      selectedCellsOrder.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Nulli sõna'),
                ),
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    selectedCells.isEmpty
                        ? 'Vali tähed, et moodustada sõna'
                        : _getCurrentWord(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 400,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellSize = constraints.maxWidth / gridSize;
                        return Column(
                          children: [
                            GestureDetector(
                              onPanStart: (details) {
                                isDragging = true;
                                _handleTouchSelection(
                                  details.localPosition,
                                  cellSize,
                                );
                              },
                              onPanUpdate: (details) {
                                if (!isDragging) return;
                                if (details.localPosition.dx >= 0 &&
                                    details.localPosition.dx <=
                                        cellSize * gridSize &&
                                    details.localPosition.dy >= 0 &&
                                    details.localPosition.dy <=
                                        cellSize * gridSize) {
                                  _handleTouchSelection(
                                    details.localPosition,
                                    cellSize,
                                  );
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
                                      ...List.generate(gridSize * gridSize, (
                                        index,
                                      ) {
                                        final row = index ~/ gridSize;
                                        final col = index % gridSize;
                                        final pos = _posToKey(row, col);
                                        final letter = letterGrid[row][col];
                                        final isVisible = letter.trim().isNotEmpty;
                                        return Positioned(
                                          left: col * cellSize,
                                          top: row * cellSize,
                                          width: cellSize,
                                          height: cellSize,
                                          child: AnimatedScale(
                                            scale: isVisible ? 1.0 : 0.0,
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
                                            curve: Curves.easeIn,
                                            child: GestureDetector(
                                              onTap: () {
                                                _handleCellSelection(
                                                  row,
                                                  col,
                                                  isClick: true,
                                                );
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback(
                                                      (_) => _checkWord(),
                                                    );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      // Middle layer: Selection lines (only latest segment animated)
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final segments =
                                              selectedCellsOrder.length;
                                          if (segments == 0)
                                            return const SizedBox.shrink();
                                          return AnimatedOpacity(
                                            opacity: _animateTraceLineOut
                                                ? 0.0
                                                : 1.0,
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
                                            child: Stack(
                                              children: [
                                                // Always draw static segments instantly, including after reverse animation
                                                CustomPaint(
                                                  key: ValueKey(
                                                    'static-segments-$segments-${selectedCellsOrder.join('-')}',
                                                  ),
                                                  size: Size(
                                                    constraints.maxWidth,
                                                    constraints.maxHeight,
                                                  ),
                                                  painter: SelectionLinePainter(
                                                    selectedCellsOrder: segments > 1
                                                        ? selectedCellsOrder
                                                              .sublist(
                                                                0,
                                                                segments - 1,
                                                              )
                                                        : selectedCellsOrder,
                                                    cellSize: cellSize,
                                                    gridSize: gridSize,
                                                  ),
                                                ),
                                                // Animate only the last segment (forward) or the segment being removed (reverse)
                                                if (segments > 1 &&
                                                    !_lastActionWasRemove)
                                                  KeyedSubtree(
                                                    key: ValueKey(
                                                      'animated-segment-${segments - 1}-${selectedCellsOrder.join('-')}-forward',
                                                    ),
                                                    child: TweenAnimationBuilder<double>(
                                                      tween: Tween<double>(
                                                        begin: 0,
                                                        end: 1,
                                                      ),
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      builder: (context, t, child) {
                                                        final current =
                                                            selectedCellsOrder[segments -
                                                                    2]
                                                                .split(',')
                                                                .map(int.parse)
                                                                .toList();
                                                        final next =
                                                            selectedCellsOrder[segments -
                                                                    1]
                                                                .split(',')
                                                                .map(int.parse)
                                                                .toList();
                                                        final startX =
                                                            (current[1] + 0.5) *
                                                            cellSize;
                                                        final startY =
                                                            (current[0] + 0.5) *
                                                            cellSize;
                                                        final endX =
                                                            (next[1] + 0.5) *
                                                            cellSize;
                                                        final endY =
                                                            (next[0] + 0.5) *
                                                            cellSize;
                                                        return CustomPaint(
                                                          size: Size(
                                                            constraints.maxWidth,
                                                            constraints.maxHeight,
                                                          ),
                                                          painter:
                                                              AnimatedSegmentPainter(
                                                                start: Offset(
                                                                  startX,
                                                                  startY,
                                                                ),
                                                                end: Offset(
                                                                  endX,
                                                                  endY,
                                                                ),
                                                                progress: t,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                // Animate the segment being removed in reverse
                                                if (_lastActionWasRemove &&
                                                    _prevSegmentStart != null &&
                                                    _prevSegmentEnd != null)
                                                  KeyedSubtree(
                                                    key: ValueKey(
                                                      'reverse-animated-segment-$segments-${selectedCellsOrder.join('-')}',
                                                    ),
                                                    child: TweenAnimationBuilder<double>(
                                                      tween: Tween<double>(
                                                        begin: 1,
                                                        end: 0,
                                                      ),
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      onEnd: () {
                                                        setState(() {
                                                          _lastActionWasRemove =
                                                              false;
                                                          _prevSegmentStart = null;
                                                          _prevSegmentEnd = null;
                                                        });
                                                      },
                                                      builder: (context, t, child) {
                                                        final current =
                                                            _prevSegmentStart!
                                                                .split(',')
                                                                .map(int.parse)
                                                                .toList();
                                                        final next =
                                                            _prevSegmentEnd!
                                                                .split(',')
                                                                .map(int.parse)
                                                                .toList();
                                                        final startX =
                                                            (current[1] + 0.5) *
                                                            cellSize;
                                                        final startY =
                                                            (current[0] + 0.5) *
                                                            cellSize;
                                                        final endX =
                                                            (next[1] + 0.5) *
                                                            cellSize;
                                                        final endY =
                                                            (next[0] + 0.5) *
                                                            cellSize;
                                                        return CustomPaint(
                                                          size: Size(
                                                            constraints.maxWidth,
                                                            constraints.maxHeight,
                                                          ),
                                                          painter:
                                                              AnimatedSegmentPainter(
                                                                start: Offset(
                                                                  startX,
                                                                  startY,
                                                                ),
                                                                end: Offset(
                                                                  endX,
                                                                  endY,
                                                                ),
                                                                progress: t,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      // Top layer: Letters
                                      ...List.generate(gridSize * gridSize, (
                                        index,
                                      ) {
                                        final row = index ~/ gridSize;
                                        final col = index % gridSize;
                                        final isSelected = selectedCells.contains(
                                          _posToKey(row, col),
                                        );

                                        return Positioned(
                                          left: col * cellSize,
                                          top: row * cellSize,
                                          width: cellSize,
                                          height: cellSize,
                                          child: Center(
                                            child: Text(
                                              letterGrid[row][col],
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
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
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leia sõnad:',
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
                          final revealCount = revealedLetters[word] ?? 0;
                          final displayChars = found
                              ? word.split('')
                              : List.generate(word.length, (i) => i < revealCount ? word[i] : '_');
                          return GestureDetector(
                            onTap: found
                                ? null
                                : () {
                                    setState(() {
                                      if (revealCount < word.length) {
                                        revealedLetters[word] = revealCount + 1;
                                      }
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: found
                                    ? Colors.green
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: displayChars
                                    .map((char) => Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Text(
                                            char,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: found ? Colors.white : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
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
                        '🎉 Palju õnne! 🎉',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Leidsid kõik sõnad!',
                        style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aeg: $finalTime',
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
                          label: const Text('Järgmine mõistatus'),
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
                          label: const Text('Mängi uuesti'),
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
