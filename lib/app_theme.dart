import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg         = Color(0xFF1C1C1A);
  static const fg         = Color(0xFFE2E2DE);
  static const sub        = Color(0xFF5A5A56);
  static const border     = Color(0xFF2E2E2C);
  static const pillBg     = Color(0xFF2A2A28);
  static const pillActive = Color(0xFF363634);
  static const cardBg     = Color(0xFF242422);

  static const colorTodo    = Color(0xFF94A3B8);
  static const colorDoing   = Color(0xFF60A5FA);
  static const colorDone    = Color(0xFF34D399);
  static const colorTrash   = Color(0xFFF87171);
  static const colorArchive = Color(0xFFFBBF24);
  static const colorClone   = Color(0xFF34D399);

  static Color kanbanColor(String colId) => switch (colId) {
    'todo'  => colorTodo,
    'doing' => colorDoing,
    'done'  => colorDone,
    _       => colorTodo,
  };
}
