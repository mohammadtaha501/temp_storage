import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';

class UnableToGetDocumentsDirectory implements Exception{}
class DataNotAdded implements Exception{}
class RecordNotFound implements Exception {
  final String message;

  RecordNotFound([this.message = "No matching record found."]);

  @override
  String toString() => message;
}

class datastorage{
  late Database _db;

  datastorage._sharedInstance();
  factory datastorage()=> datastorage._sharedInstance();

  Future<void> open()async{
    try {
      print("in open");
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, "water_intake.db");
      _db = await openDatabase(dbPath);
      await _db.execute('''
      CREATE TABLE water_intake (
      date TEXT NOT NULL,
      time TEXT NOT NULL,
      amount_ml INTEGER NOT NULL,
      cumulative_total_ml INTEGER,
      notes TEXT,
      PRIMARY KEY (date, time)
    )
    ''');
    }on MissingPlatformDirectoryException {
      print("in open exception");
      throw UnableToGetDocumentsDirectory();
    }
  }

  Future<int?> getLastCumulativeTotal(String date) async {

    List<Map<String, dynamic>> results = await _db.rawQuery(
        'SELECT cumulative_total_ml FROM water_intake WHERE date = ? ORDER BY time DESC LIMIT 1',
        [date]
    );

    if (results.isNotEmpty) {
      return results.first['cumulative_total_ml'] as int;
    }
    return null;
  }

  Future<void> addWaterIntake( String date, String time, int amountMl, int goalMl, String notes) async {

    final int? cumulativeTotalMl =await getLastCumulativeTotal(date) ;
    Map<String, dynamic> data = {
      'date': date,
      'time': time,
      'amount_ml': amountMl,
      'cumulative_total_ml': cumulativeTotalMl != null ? amountMl + cumulativeTotalMl : amountMl,
      'goal_ml': goalMl,
      'notes': notes,
    };

    int id = await _db.insert('water_intake', data);
    if(id == -1){
      throw DataNotAdded();
    }
  }

  Future<void> deleteWaterIntake(String date, String time) async {

    final int result = await _db.delete(
      'water_intake',
      where: 'date = ? AND time = ?',
      whereArgs: [date, time],
    );

    if (result == 0) {
      throw RecordNotFound();
    }
    // this is how to catch this exception
    // try {
    //   await deleteWaterIntake('2024-10-08', '14:30:00');
    //   print('Record deleted successfully!');
    // } on RecordNotFound catch (e) {  // Catching the specific exception and naming it 'e'
    //   print('Error: ${e.message}');
    // } catch (e) {  // Catching any other exceptions
    //   print('An unexpected error occurred: $e');
    // }
  }

  Future<List<Map<String, dynamic>>> getAllWaterIntakeRecords() async {
    List<Map<String, dynamic>> results = await _db.query('water_intake');
    return results;
  }

}

final waterDataService = datastorage();