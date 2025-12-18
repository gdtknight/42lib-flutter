import 'package:flutter/material.dart';

/// 재사용 가능한 버튼 위젯
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return isOutlined
        ? OutlinedButton(onPressed: onPressed, child: Text(text))
        : ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}
