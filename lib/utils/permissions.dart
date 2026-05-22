import 'package:skillforgeapp/models/auth/auth_models.dart';

bool isAdmin(User? user) => user?.roles.contains('admin') == true;

bool isInstructor(User? user) => user?.roles.contains('instructor') == true;

bool canAccessAdmin(User? user) => isAdmin(user) || isInstructor(user);
