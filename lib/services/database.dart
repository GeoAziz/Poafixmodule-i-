import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static Db? _db;

  // Getter for the database instance
  static Future<Db> get db async {
    if (_db == null) {
      try {
        // Replace with your MongoDB connection string
        _db = await Db.create("mongodb://192.168.100.21:27017/home_service_db");

        // Open the database connection
        await _openDatabase();
      } catch (e) {
        print("Failed to connect to the database: $e");
        rethrow; // Re-throw the exception to handle it in the calling code
      }
    } else if (!_db!.isConnected) {
      // If the database instance exists but is not connected, reconnect
      try {
        await _openDatabase();
      } catch (e) {
        print("Failed to reconnect to the database: $e");
        rethrow; // Re-throw the exception to handle it in the calling code
      }
    }

    return _db!;
  }

  // Open the database connection with a retry mechanism
  static Future<void> _openDatabase() async {
    int attempts = 0;
    const maxAttempts = 5;
    const delay = Duration(milliseconds: 500);

    while (attempts < maxAttempts) {
      try {
        if (_db!.state == State.OPENING) {
          // If the state is State.OPENING, wait for a short period of time before retrying
          await Future.delayed(delay);
        } else {
          await _db!.open();
          print("Database connected successfully!");
          return;
        }
      } catch (e) {
        attempts++;
        print("Attempt $attempts failed: $e");
      }
    }

    print("Failed to connect to the database after $maxAttempts attempts.");
    throw Exception(
        "Failed to connect to database after $maxAttempts attempts");
  }

  // Close the database connection
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      print("Database connection closed.");
    }
  }

  // Method to get a collection by name
  static Future<DbCollection> collection(String name) async {
    var db = await Database.db; // Ensure the database is connected
    return db.collection(name);
  }
}
