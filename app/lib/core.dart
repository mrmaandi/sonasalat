import 'dart:math';

class PuzzleAlgorithm {
  static const List<List<int>> directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1]
  ];

  final Random _random = Random();
  
  bool _valid(int r, int c) => r >= 0 && r < 4 && c >= 0 && c < 4;

  // Place a word snake-like (each letter follows adjacent path)
  bool _placeWordSnake(List<List<String>> grid, String word, int idx, int r, int c, Set<String> used, List<List<int>> path) {
    if (idx == word.length) return true;
    
    String pos = '$r,$c';
    if (!_valid(r, c) || used.contains(pos)) {
      return false;
    }

    // If cell is already occupied, it must match the current letter
    if (grid[r][c] != '' && grid[r][c] != word[idx]) {
      return false;
    }

    String prev = grid[r][c];
    bool wasEmpty = prev == '';
    grid[r][c] = word[idx];
    used.add(pos);
    path.add([r, c]);

    if (idx == word.length - 1) {
      return true;
    }

    // Try all adjacent directions for next letter
    for (var dir in directions) {
      int nr = r + dir[0], nc = c + dir[1];
      if (_placeWordSnake(grid, word, idx + 1, nr, nc, used, path)) {
        return true;
      }
    }

    // Backtrack
    if (wasEmpty) grid[r][c] = '';
    used.remove(pos);
    path.removeLast();
    return false;
  }

  bool _backtrack(List<List<String>> grid, List<String> words, int i, Set<String> globalUsed) {
    if (i == words.length) {
      // Check if all cells are filled
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          if (grid[r][c] == '') return false;
        }
      }
      return true;
    }

    // Create list of all positions and shuffle them for randomness
    List<List<int>> positions = [];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        positions.add([r, c]);
      }
    }
    positions.shuffle(_random);

    for (var pos in positions) {
      int r = pos[0], c = pos[1];
      Set<String> wordUsed = <String>{};
      List<List<int>> path = [];
      
      if (_placeWordSnake(grid, words[i], 0, r, c, wordUsed, path)) {
        // Print grid after placing each word
        print('Placed word: \'${words[i]}\'');
        for (var row in grid) {
          print(row);
        }
        print('---');
        
        // Add word cells to global used set
        Set<String> newGlobalUsed = Set<String>.from(globalUsed)..addAll(wordUsed);
        
        if (_backtrack(grid, words, i + 1, newGlobalUsed)) {
          return true;
        }
        
        // Backtrack: remove word from grid
        for (var pos in path) {
          if (!globalUsed.contains('${pos[0]},${pos[1]}')) {
            grid[pos[0]][pos[1]] = '';
          }
        }
      }
    }
    return false;
  }

  List<List<String>>? solve(List<String> words) {
    // Check total letters can fill the grid
    int totalLetters = words.fold(0, (sum, word) => sum + word.length);
    if (totalLetters < 16) {
      print('Not enough letters to fill grid. Need 16, got $totalLetters');
      return null;
    }

    // Shuffle words for more randomness
    List<String> shuffledWords = List.from(words);
    shuffledWords.shuffle(_random);

    List<List<String>> grid = List.generate(4, (_) => List.filled(4, ''));
    
    if (_backtrack(grid, shuffledWords, 0, <String>{})) {
      return grid;
    }
    return null;
  }

  List<List<String>> fitWordsOnGrid(List<String> words, {int gridSize = 4}) {
    var result = solve(words);
    if (result != null) {
      return result;
    }
    // Return empty grid if no solution found
    return List.generate(gridSize, (_) => List.filled(gridSize, ''));
  }
}
