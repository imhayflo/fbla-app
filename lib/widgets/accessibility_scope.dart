import 'package:flutter/material.dart';
import 'package:fbla_member_app/services/accessibility_controller.dart';

class AccessibilityScope extends InheritedNotifier<AccessibilityController> {
  const AccessibilityScope({
    super.key,
    required AccessibilityController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccessibilityController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AccessibilityScope>();
    assert(scope != null, 'AccessibilityScope not found');
    return scope!.notifier!;
  }
}
