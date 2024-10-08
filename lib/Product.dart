import 'package:objectbox/objectbox.dart';

@Entity()
class Product {
  @Id()
  int id;
  String name;
  double price;

  Product({this.id = 0, required this.name, required this.price});
}