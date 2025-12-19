import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

class MyState {}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState());
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

void main() {
  print('Compilation check');
}
