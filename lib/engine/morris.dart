/// Board topology constants for Nine Men's Morris.
///
/// 24 points on a 7x7 grid: three concentric squares (outer, middle, inner),
/// each with 8 points (4 corners + 4 edge midpoints), joined by 4 radial
/// lines connecting the corresponding midpoints. Indices 0-7 outer,
/// 8-15 middle, 16-23 inner.
library;

class MorrisBoard {
  MorrisBoard._();

  /// Grid coordinates (col, row) in 0..6 for each of the 24 points.
  static const List<List<int>> xy = [
    [0, 0], [3, 0], [6, 0], [6, 3], [6, 6], [3, 6], [0, 6], [0, 3], // 0-7
    [1, 1], [3, 1], [5, 1], [5, 3], [5, 5], [3, 5], [1, 5], [1, 3], // 8-15
    [2, 2], [3, 2], [4, 2], [4, 3], [4, 4], [3, 4], [2, 4], [2, 3], // 16-23
  ];

  /// Adjacency: directly connected by one carved line segment.
  static const List<List<int>> adj = [
    [1, 7], [0, 2, 9], [1, 3], [2, 4, 11], [3, 5], [4, 6, 13], [5, 7], [0, 6, 15],
    [9, 15], [8, 10, 1, 17], [9, 11], [10, 12, 3, 19], [11, 13], [12, 14, 5, 21],
    [13, 15], [8, 14, 7, 23], [17, 23], [16, 18, 9], [17, 19], [18, 20, 11],
    [19, 21], [20, 22, 13], [21, 23], [16, 22, 15],
  ];

  /// The 16 mills (3 collinear points connected by board lines).
  static const List<List<int>> mills = [
    [0, 1, 2], [2, 3, 4], [4, 5, 6], [6, 7, 0],
    [8, 9, 10], [10, 11, 12], [12, 13, 14], [14, 15, 8],
    [16, 17, 18], [18, 19, 20], [20, 21, 22], [22, 23, 16],
    [1, 9, 17], [3, 11, 19], [5, 13, 21], [7, 15, 23],
  ];

  /// High-connectivity non-corner points (edge midpoints + radial joins).
  /// Used for positional evaluation and AI opening preferences.
  static const Set<int> hotPoints = {
    1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23
  };

  /// The 4 radial lines (top, right, bottom, left).
  static const List<List<int>> radials = [
    [1, 9, 17],
    [3, 11, 19],
    [5, 13, 21],
    [7, 15, 23],
  ];
}
