import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/request.dart';
import '../models/student.dart';
import '../models/message.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._constructor();

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "dorm_fix_app.db");

    final database = await openDatabase(
      databasePath,
      version: 6,
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT NOT NULL,
            fullName TEXT NOT NULL,
            studentId TEXT NOT NULL,
            password TEXT NOT NULL,
            userType TEXT NOT NULL
          )
        ''');

        // Requests table
        await db.execute('''
          CREATE TABLE requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            studentName TEXT NOT NULL,
            studentId TEXT NOT NULL,
            title TEXT,
            problemCategory TEXT NOT NULL,
            description TEXT NOT NULL,
            urgencyLevel TEXT NOT NULL,
            status TEXT NOT NULL,
            photoPath TEXT,
            assignedStaff INTEGER,
            createdAt INTEGER NOT NULL,
            roomNumber TEXT,
            progressNotes TEXT,
            completedAt INTEGER,
            FOREIGN KEY (assignedStaff) REFERENCES users(id)
          )
        ''');

        // Students table
        await db.execute('''
          CREATE TABLE students (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            password TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');

        // Messages table
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            senderId TEXT NOT NULL,
            receiverId TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');

        // Default users
        await db.insert('users', {
          'username': 'admin',
          'email': 'admin@dormfix.com',
          'fullName': 'Administrator',
          'studentId': 'ADMIN001',
          'password': 'admin123',
          'userType': 'UserType.admin',
        });

        await db.insert('users', {
          'username': 'staff1',
          'email': 'staff1@dormfix.com',
          'fullName': 'Mike Johnson',
          'studentId': 'STAFF001',
          'password': 'staff123',
          'userType': 'UserType.staff',
        });

        await db.insert('users', {
          'username': 'student1',
          'email': 'student1@dormfix.com',
          'fullName': 'Jane Smith',
          'studentId': 'STUDENT001',
          'password': 'student123',
          'userType': 'UserType.student',
        });

        await db.insert('students', {
          'id': 'TEST001',
          'name': 'Test Student',
          'password': 'test123',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE requests ADD COLUMN progressNotes TEXT",
          );
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE Students RENAME TO students');
          } catch (e) {
            print('Table rename skipped: $e');
          }
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE requests ADD COLUMN completedAt INTEGER",
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE requests ADD COLUMN assignedStaff_new INTEGER",
          );
          await db.execute(
            "UPDATE requests SET assignedStaff_new = CAST(assignedStaff AS INTEGER)",
          );
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              senderId TEXT NOT NULL,
              receiverId TEXT NOT NULL,
              content TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        }
      },
    );

    return database;
  }

  // ----------------- Student Operations -----------------
  Future<void> createStudent(Student student) async {
    final db = await database;
    await db.insert('students', student.toMap());
  }

  Future<Student?> getStudentById(String id) async {
    final db = await database;
    final maps = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Student.fromMap(maps.first);
    return null;
  }

  Future<Student?> authenticateStudent(String id, String password) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'id = ? AND password = ?',
      whereArgs: [id, password],
    );
    if (maps.isNotEmpty) return Student.fromMap(maps.first);
    return null;
  }

  // ----------------- User Operations -----------------
  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<List<User>> getAllStaff() async {
    final db = await database;
    final userMaps = await db.query(
      'users',
      where: 'userType = ?',
      whereArgs: ['UserType.staff'],
    );

    final requests = await getAllRequests();

    return userMaps.map((map) {
      final userId = map['id'] as int?;
      final assignedCount = requests
          .where((req) => req.assignedStaff == userId)
          .length;

      return User(
        id: userId,
        username: map['username'] as String,
        email: map['email'] as String,
        fullName: map['fullName'] as String,
        studentId: map['studentId'] as String,
        password: map['password'] as String,
        userType: UserType.values.firstWhere(
          (type) => type.toString() == map['userType'],
          orElse: () => UserType.staff,
        ),
        assignedRequestsCount: assignedCount,
      );
    }).toList();
  }

  Future<void> addStaff(User staff) async {
    final db = await database;
    await db.insert('users', {
      'username': staff.username,
      'email': staff.email,
      'fullName': staff.fullName,
      'studentId': staff.studentId,
      'password': staff.password,
      'userType': staff.userType.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ----------------- Request Operations -----------------
  Future<int> createRequest(MaintenanceRequest request) async {
    final db = await database;
    return await db.insert('requests', request.toMap());
  }

  Future<List<MaintenanceRequest>> getRequestsByStudentId(
    String studentId,
  ) async {
    final db = await database;
    final result = await db.query(
      'requests',
      where: 'studentId = ?',
      whereArgs: [studentId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => MaintenanceRequest.fromMap(map)).toList();
  }

  Future<List<MaintenanceRequest>> getAllRequests() async {
    final db = await database;
    final result = await db.query('requests', orderBy: 'createdAt DESC');
    return result.map((map) => MaintenanceRequest.fromMap(map)).toList();
  }

  Future<int> updateRequest(MaintenanceRequest request) async {
    final db = await database;
    return await db.update(
      'requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<List<MaintenanceRequest>> getRequestsAssignedTo(int staffId) async {
    final db = await database;
    final result = await db.query(
      'requests',
      where: 'assignedStaff = ?',
      whereArgs: [staffId],
      orderBy: 'createdAt DESC',
    );
    return result.map((m) => MaintenanceRequest.fromMap(m)).toList();
  }

  Future<void> assignStaffToRequest(
    int staffId,
    MaintenanceRequest request,
  ) async {
    final db = await database;
    await db.update(
      'requests',
      {'assignedStaff': staffId},
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  // ----------------- Messaging Operations -----------------
  Future<int> sendMessage(Message message) async {
    final db = await database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessagesForStudent(String studentId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'receiverId = ?',
      whereArgs: [studentId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<List<Message>> getMessagesFromSender(String senderId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'senderId = ?',
      whereArgs: [senderId],
      orderBy: 'timestamp ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<List<Message>> getConversation(String user1Id, String user2Id) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT * FROM messages
      WHERE (senderId = ? AND receiverId = ?)
         OR (senderId = ? AND receiverId = ?)
      ORDER BY timestamp ASC
      ''',
      [user1Id, user2Id, user2Id, user1Id],
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }
}
