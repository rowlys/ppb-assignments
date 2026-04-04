import '../models/task_model.dart';
import '../database/database_helper.dart';

class TaskRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<Task>> getAllTasks() async {
    final data = await _db.readAll();
    return data.map((map) => Task.fromMap(map)).toList();
  }

  Future<void> addTask(Task task) async {
    await _db.create(task.toMap());
  }

  Future<void> updateTask(Task task) async {
    await _db.update(task.toMap());
  }

  Future<void> removeTask(int id) async {
    await _db.delete(id);
  }
}