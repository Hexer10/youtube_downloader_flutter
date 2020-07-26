


import 'package:equatable/equatable.dart';

void main() {
  var a = Y([1,2,3]);
  var b = Y([1,2,3]);
  print(a == b);
}
class Y extends Equatable {
  final List<int> l;

  Y(this.l);

  @override
  List<Object> get props => [l];
}