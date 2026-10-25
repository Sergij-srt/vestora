import 'package:flutter/widgets.dart';

/// Owns a list of [ChangeNotifier]s (such as [TextEditingController] or [FocusNode])
/// for the exact widget-tree lifetime of a modal dialog or bottom sheet.
///
/// Because Flutter unmounts children before calling a parent's [State.dispose],
/// every descendant [EditableTextState] detaches its listener at the end of the
/// modal's exit animation BEFORE these controllers are disposed — preventing both
/// memory leaks AND `TextEditingController was used after being disposed` crashes.
class ControllerScope<T extends List<ChangeNotifier>> extends StatefulWidget {
  final T Function() create;
  final Widget Function(BuildContext context, T controllers) builder;

  const ControllerScope({
    super.key,
    required this.create,
    required this.builder,
  });

  @override
  State<ControllerScope<T>> createState() => _ControllerScopeState<T>();
}

class _ControllerScopeState<T extends List<ChangeNotifier>>
    extends State<ControllerScope<T>> {
  late final T _controllers = widget.create();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controllers);
  }
}
