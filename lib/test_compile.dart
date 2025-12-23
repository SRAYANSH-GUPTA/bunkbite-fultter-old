import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyState {}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState());
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

void main() {
  // Compilation check
}
