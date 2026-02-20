abstract class Model {
  int? id;
  
  String get table;

  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
}
