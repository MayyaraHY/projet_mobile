import '../database/database_helper.dart';
import '../utils/constants.dart';

class RatingService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Add a rating for a seller. rating should be 1..5
  Future<void> addRating({
    required String sellerId,
    required String raterId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) throw ArgumentError('rating must be between 1 and 5');

    final db = await _dbHelper.database;
    await db.insert(DatabaseConstants.ratingsTable, {
      DatabaseConstants.columnRatingSellerId: sellerId,
      DatabaseConstants.columnRatingRaterId: raterId,
      DatabaseConstants.columnRatingValue: rating,
      DatabaseConstants.columnRatingComment: comment ?? '',
      DatabaseConstants.columnRatingCreatedAt: DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Compute average rating for a seller (returns 0 if none)
  Future<double> getAverageRating(String sellerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(${DatabaseConstants.columnRatingValue}) as avg, COUNT(*) as cnt FROM ${DatabaseConstants.ratingsTable} WHERE ${DatabaseConstants.columnRatingSellerId} = ?',
      [sellerId],
    );

    if (result.isEmpty) return 0.0;
    final avg = (result.first['avg'] as num?)?.toDouble() ?? 0.0;
    return avg;
  }

  /// Get recent ratings for a seller
  Future<List<Map<String, dynamic>>> getRatingsForSeller(String sellerId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseConstants.ratingsTable,
      where: '${DatabaseConstants.columnRatingSellerId} = ?',
      whereArgs: [sellerId],
      orderBy: '${DatabaseConstants.columnRatingCreatedAt} DESC',
    );
    return rows;
  }
}
