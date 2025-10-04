import 'dart:math' show Random;

class GameLogic {
  static const int gridSize = 4;
  static const int minWordLength = 4;
  final String theme;
  final List<String> words;
  late List<List<String>> grid;
  late List<WordPlacement> _wordPlacements;

  GameLogic({required this.theme, required this.words}) {
    grid = List.generate(gridSize, (i) => List.filled(gridSize, ''));
    _wordPlacements = [];
  }

  List<List<String>> generateGrid() {
    int maxAttempts = 100;
    List<List<String>> bestGrid = [];
    List<WordPlacement> bestPlacements = [];
    int maxPlacedWords = 0;
    int maxDirections = 0;
    
    while (maxAttempts > 0) {
      grid = List.generate(gridSize, (i) => List.filled(gridSize, ''));
      _wordPlacements = [];
      
      // Filter and prepare words that can fit in the grid
      final wordsToPlace = words
        .where((w) => w.length >= minWordLength && w.length <= gridSize * 2)
        .map((w) => w.toUpperCase())
        .toList()
        ..shuffle(); // Randomize word order
      
      if (_tryPlaceWords(wordsToPlace)) {
        _fillEmptyCells();
        return grid;/*  */
      } else {
        // Track the best attempt
        var directions = _wordPlacements.map((wp) => wp.direction).toSet();
        if (_wordPlacements.length > maxPlacedWords || 
            (directions.length > maxDirections && _wordPlacements.length >= maxPlacedWords)) {
          maxPlacedWords = _wordPlacements.length;
          maxDirections = directions.length;
          bestGrid = List<List<String>>.from(
            grid.map((row) => List<String>.from(row))
          );
          bestPlacements = List.from(_wordPlacements);
        }
      }
      
      maxAttempts--;
    }
    
    // Use the best attempt if we couldn't meet all requirements
    if (bestGrid.isNotEmpty) {
      grid = bestGrid;
      _wordPlacements = bestPlacements;
      _fillEmptyCells();
      return grid;
    }
    
    // Ultimate fallback
    return List.generate(
      gridSize,
      (i) => List.generate(
        gridSize,
        (j) => words[0][(i * gridSize + j) % words[0].length]
      )
    );
  
  }

  bool _tryPlaceWords(List<String> wordsToPlace) {
    Set<String> usedCells = {};
    List<String> placedWords = [];
    Set<Direction> usedDirections = {};
    final random = Random();

    // Try each word in each direction until we have enough words and directions
    for (var word in wordsToPlace) {
      List<WordPlacement> allPlacements = [];
      
      // Collect all possible placements for this word
      for (var dir in Direction.values) {
        var dirPlacements = _findWordPlacements(word, usedCells)
            .where((p) => p.direction == dir)
            .toList();
        allPlacements.addAll(dirPlacements);
      }
      
      if (allPlacements.isEmpty) continue;
      
      // Prioritize placements in unused directions
      allPlacements.sort((a, b) {
        bool aUsed = usedDirections.contains(a.direction);
        bool bUsed = usedDirections.contains(b.direction);
        if (aUsed == bUsed) return random.nextBool() ? 1 : -1;
        return aUsed ? 1 : -1;
      });
      
      // Try to place the word
      var placement = allPlacements.first;
      _placeWord(word, placement, usedCells);
      placedWords.add(word);
      _wordPlacements.add(placement);
      usedDirections.add(placement.direction);
      
      // Check if we have enough words and directions
      if (placedWords.length >= 4 && usedDirections.length >= 2) {
        return true;
      }
    }
    
    return placedWords.length >= 4 && usedDirections.length >= 2;
  }

  void _placeWord(String word, WordPlacement placement, Set<String> usedCells) {
    for (int i = 0; i < word.length; i++) {
      var (row, col) = _keyToPos(placement.positions[i]);
      grid[row][col] = word[i];
      usedCells.add(placement.positions[i]);
    }
  }

  void _fillEmptyCells() {
    String availableLetters = _wordPlacements
        .map((wp) => wp.word)
        .join();
        
    final random = Random();
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (grid[row][col].isEmpty) {
          grid[row][col] = availableLetters[
            random.nextInt(availableLetters.length)
          ];
        }
      }
    }
  }

  List<WordPlacement> _findWordPlacements(String word, Set<String> usedCells) {
    List<WordPlacement> placements = [];
    
    // Try starting from each position
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        var startPos = _posToKey(row, col);
        if (usedCells.contains(startPos) && 
            grid[row][col] != word[0]) continue;
        
        // Try to find snake-like patterns using DFS
        var visited = {startPos};
        _findWordPattern(word, 0, row, col, visited, usedCells, [], placements);
      }
    }
    
    return placements;
  }

  void _findWordPattern(
    String word,
    int letterIndex,
    int row,
    int col,
    Set<String> visited,
    Set<String> usedCells,
    List<String> currentPath,
    List<WordPlacement> results
  ) {
    final pos = _posToKey(row, col);
    currentPath.add(pos);

    // If we've found a complete word
    if (letterIndex == word.length - 1) {
      // Determine main direction based on start and end positions
      var startPos = currentPath.first.split(',').map(int.parse).toList();
      var endPos = currentPath.last.split(',').map(int.parse).toList();
      var direction = _determineMainDirection(startPos[0], startPos[1], endPos[0], endPos[1]);
      
      results.add(WordPlacement(word, List.from(currentPath), direction));
      currentPath.removeLast();
      return;
    }

    // Try all adjacent cells for the next letter
    for (var dir in Direction.values) {
      int nextRow = row + dir.rowDelta;
      int nextCol = col + dir.colDelta;
      var nextPos = _posToKey(nextRow, nextCol);

      if (_isValidPosition(nextRow, nextCol) && 
          !visited.contains(nextPos) &&
          (!usedCells.contains(nextPos) || grid[nextRow][nextCol] == word[letterIndex + 1])) {
        visited.add(nextPos);
        _findWordPattern(
          word,
          letterIndex + 1,
          nextRow,
          nextCol,
          visited,
          usedCells,
          currentPath,
          results
        );
        visited.remove(nextPos);
      }
    }

    currentPath.removeLast();
  }

  Direction _determineMainDirection(int startRow, int startCol, int endRow, int endCol) {
    int rowDiff = endRow - startRow;
    int colDiff = endCol - startCol;
    
    if (rowDiff.abs() > colDiff.abs()) {
      return rowDiff > 0 ? Direction.vertical : Direction.vertical;
    } else if (colDiff.abs() > rowDiff.abs()) {
      return Direction.horizontal;
    } else if (rowDiff > 0) {
      return Direction.diagonalDown;
    } else {
      return Direction.diagonalUp;
    }
  }

  List<String> findPlacedWords() {
    return _wordPlacements.map((wp) => wp.word).toList();
  }

  List<WordPlacement> getWordPlacements() {
    return List.from(_wordPlacements);
  }

  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }

  String _posToKey(int row, int col) => '$row,$col';
  
  (int, int) _keyToPos(String key) {
    final parts = key.split(',').map(int.parse).toList();
    return (parts[0], parts[1]);
  }
}

enum Direction {
  horizontal(0, 1),
  vertical(1, 0),
  diagonalDown(1, 1),
  diagonalUp(-1, 1);

  final int rowDelta;
  final int colDelta;
  
  const Direction(this.rowDelta, this.colDelta);
}

class WordPlacement {
  final String word;
  final List<String> positions;
  final Direction direction;  // Main direction, used for variety checking

  WordPlacement(this.word, this.positions, this.direction);

  // Check if a position is adjacent to the last position in the path
  static bool isAdjacent(String pos1, String pos2) {
    final p1 = pos1.split(',').map(int.parse).toList();
    final p2 = pos2.split(',').map(int.parse).toList();
    return (p1[0] - p2[0]).abs() <= 1 && (p1[1] - p2[1]).abs() <= 1;
  }
}