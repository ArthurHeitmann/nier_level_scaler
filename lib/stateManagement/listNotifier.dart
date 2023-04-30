import 'dart:collection';
import 'package:flutter/foundation.dart';

class ListNotifier<T> extends ChangeNotifier with IterableMixin<T> {
  final List<T> _children;
  late final ChangeNotifier onDisposed;
  bool _debugDisposed = false;

  ListNotifier(List<T> children)
    : _children = children,
    onDisposed = ChangeNotifier();
    
  @override
  Iterator<T> get iterator => _children.iterator;

  @override
  int get length => _children.length;

  T operator [](int index) => _children[index];

  void operator []=(int index, T value) {
    if (value == _children[index]) return;
    _children[index] = value;
    notifyListeners();
  }

  int indexOf(T child) => _children.indexOf(child);

  int indexWhere(bool Function(T) test) => _children.indexWhere(test);

  T? find(bool Function(T) test) {
    for (final child in _children) {
      if (test(child))
        return child;
    }
    return null;
  }

  T? findRecWhere(bool Function(T) test, { Iterable<T>? children }) {
    children ??= this;
    for (var child in children) {
      if (test(child))
        return child;
      if (child is! Iterable)
        continue;
      var result = findRecWhere(test, children: child as Iterable<T>);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  List<T> findAllRecWhere(bool Function(T) test, { Iterable<T>? children }) {
    children ??= this;
    var result = <T>[];
    for (var child in children) {
      if (test(child))
        result.add(child);
      if (child is! Iterable)
        continue;
      result.addAll(findAllRecWhere(test, children: child as Iterable<T>));
    }
    return result;
  }

  void add(T child) {
    _children.add(child);
    notifyListeners();
  }

  void addAll(Iterable<T> children) {
    if (children.isEmpty) return;
    _children.addAll(children);
    notifyListeners();
  }

  void insert(int index, T child) {
    _children.insert(index, child);
    notifyListeners();
  }

  void remove(T child) {
    _children.remove(child);
    notifyListeners();
  }

  T removeAt(int index) {
    var ret =_children.removeAt(index);
    notifyListeners();
    return ret;
  }

  void removeWhere(bool Function(T) test) {
    _children.removeWhere(test);
    notifyListeners();
  }

  void move(int from, int to) {
    if (from == to)
      return;
    if (from < 0 || from >= _children.length || to < 0 || to >= _children.length)
      throw RangeError('from: $from, to: $to, length: ${_children.length}');
    var child = _children.removeAt(from);
    _children.insert(to, child);
    notifyListeners();
  }

  void clear() {
    if (_children.isEmpty) return;
    _children.clear();
    notifyListeners();
  }

  void replaceWith(List<T> newChildren) {
    if (listEquals(newChildren, _children)) return;
    _children.clear();
    _children.addAll(newChildren);
    notifyListeners();
  }

  @override
  void dispose() {
    assert(() {
      if (_debugDisposed) {
        throw FlutterError(
          "A $runtimeType was used after being disposed.\n"
          "Once you have called dispose() on a $runtimeType, it can no longer be used."
        );
      }
      _debugDisposed = true;
      return true;
    }());
    for (var child in _children) {
      if (child is ChangeNotifier)
        child.dispose();
    }
    super.dispose();
    onDisposed.notifyListeners();
    onDisposed.dispose();
  }
}
