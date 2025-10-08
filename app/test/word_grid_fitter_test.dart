import 'package:flutter_test/flutter_test.dart';
import '../lib/core.dart';

// Helper function to verify a word can be found using Boggle rules
bool _canFindWord(List<List<String>> grid, String word) {
  for (int r = 0; r < 4; r++) {
    for (int c = 0; c < 4; c++) {
      if (grid[r][c] == word[0]) {
        Set<String> used = {};
        if (_searchWord(grid, word, 0, r, c, used)) {
          return true;
        }
      }
    }
  }
  return false;
}

bool _searchWord(List<List<String>> grid, String word, int idx, int r, int c, Set<String> used) {
  if (idx == word.length) return true;
  if (r < 0 || r >= 4 || c < 0 || c >= 4) return false;
  
  String pos = '$r,$c';
  if (used.contains(pos) || grid[r][c] != word[idx]) return false;
  
  used.add(pos);
  
  // Try all 8 directions
  const directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1]
  ];
  
  for (var dir in directions) {
    if (_searchWord(grid, word, idx + 1, r + dir[0], c + dir[1], used)) {
      used.remove(pos);
      return true;
    }
  }
  
  used.remove(pos);
  return false;
}

void main() {
  test('PuzzleAlgorithm generates valid Boggle-style grid', () {
    final words = ['SININE', 'KOLLANE', 'PUNANE', 'LILLA'];
    final algo = PuzzleAlgorithm();
    final grid = algo.solve(words);

    if (grid == null) {
      fail('No solution found for the given words and grid size.');
    }

    // Print final grid for debug
    print('Final grid:');
    for (var row in grid) {
      print(row);
    }

    // Check grid size
    expect(grid.length, 4);
    expect(grid.every((row) => row.length == 4), true);

    // Check that all cells are filled
    for (var row in grid) {
      for (var cell in row) {
        expect(cell.isNotEmpty, true);
        expect(cell, cell.toUpperCase());
      }
    }

    // Verify each word can be found in the grid using Boggle rules
    for (var word in words) {
      bool found = _canFindWord(grid, word);
      expect(found, true, reason: 'Word "$word" should be findable in the grid');
    }
  });
}
