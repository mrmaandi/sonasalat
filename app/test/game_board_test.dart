import 'package:flutter_test/flutter_test.dart';
import 'package:sonasalat_app/game_logic.dart';

void main() {
  group('GameBoard Generation Tests', () {
    test('should place venomous creatures words in a 4x4 grid', () {
      final gameLogic = GameLogic(
        theme: 'Venomous creatures',
        words: ['COBRA', 'SQUID', 'SPIDER', 'VIPER', 'SCORPION', 'WASP'],
      );

      final grid = gameLogic.generateGrid();
      final placedWords = gameLogic.findPlacedWords();
      
      // Print the generated grid for inspection
      print('\nGenerated grid:');
      for (var row in grid) {
        print(row.join(' '));
      }
      print('\nPlaced words: ${placedWords.join(', ')}');
      
      expect(grid.length, equals(4));
      expect(grid[0].length, equals(4));
      
      // Verify that at least 4 words were placed
      expect(placedWords.length, greaterThanOrEqualTo(4),
        reason: 'Should place at least 4 words from the theme');
        
      // Print word placements for inspection
      final placements = gameLogic.getWordPlacements();
      print('\nWord placements:');
      for (var wp in placements) {
        print('${wp.word}: ${wp.positions.join(" -> ")}');
      }
    });

    test('should place words in different directions', () {
      final gameLogic = GameLogic(theme: 'Colors', words: [
        'BLUE',  // 4 letters
        'PINK',  // 4 letters
        'GOLD',  // 4 letters
        'TEAL',  // 4 letters
        'GREEN', // 5 letters
        'BLACK', // 5 letters
        'WHITE', // 5 letters
      ]);
      
      gameLogic.generateGrid();
      final wordPlacements = gameLogic.getWordPlacements();
      
      // Verify word placements
      expect(wordPlacements.length, greaterThanOrEqualTo(4),
        reason: 'Should place at least 4 words');
      
      // Verify we have different directions for words
      final directions = wordPlacements.map((wp) => wp.direction).toSet();
      expect(directions.length, greaterThan(1), 
        reason: 'Words should be placed in at least 2 different directions');
      
      // Print placed words and their directions for debugging
      for (var placement in wordPlacements) {
        print('Placed ${placement.word} in direction ${placement.direction}');
      }
    });

    test('should handle overlapping words correctly', () {
      final gameLogic = GameLogic(theme: 'Fruits', words: [
        'PEAR',
        'PLUM',
        'LIME',
        'KIWI',
      ]);
      
      final grid = gameLogic.generateGrid();
      final placedWords = gameLogic.findPlacedWords();
      
      // Count letter occurrences
      final letterCounts = <String, int>{};
      for (var row in grid) {
        for (var cell in row) {
          letterCounts[cell] = (letterCounts[cell] ?? 0) + 1;
        }
      }
      
      // Some letters should be shared (count > 1) if words overlap
      expect(
        letterCounts.values.any((count) => count > 1),
        true,
        reason: 'Some letters should be shared between words'
      );
    });
  });
}