import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String firstName;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  String dni;

  @HiveField(3)
  String gender;

  @HiveField(4)
  int school;

  @HiveField(5)
  String profileImage;

  @HiveField(6)
  int level;

  @HiveField(7)
  int grade;

  @HiveField(8)
  int section;

  Student({
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.gender,
    required this.school,
    required this.profileImage,
    required this.level,
    required this.grade,
    required this.section,
  });
}
