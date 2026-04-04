import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskController extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();
  
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await _repository.getAllTasks();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(String title, String description) async {
    final newTask = Task(
      id: null,
      title: title,
      description: description,
      isCompleted: false,
    );

    await _repository.addTask(newTask);
    await fetchTasks();
  }

  Future<void> toggleCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    await _repository.updateTask(updatedTask);
    await fetchTasks();
  }

  Future<void> removeTask(int id) async {
    await _repository.removeTask(id);
    await fetchTasks();
  }
}