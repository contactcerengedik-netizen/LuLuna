import 'package:flutter/material.dart';

import '../../../data/models/skill_level.dart';
import '../../education/presentation/category_hub_screen.dart';
import '../data/math_categories.dart';

class MathHubScreen extends StatelessWidget {
  const MathHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryHubScreen(
      title: 'Matematik',
      skill: SkillArea.mathematics,
      categories: MathCategories.mvp,
      routePrefix: '/student/math',
    );
  }
}

class MathDifficultyScreen extends StatelessWidget {
  const MathDifficultyScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final cat = MathCategories.byId(categoryId);
    return DifficultySelectScreen(
      title: cat?.title ?? 'Matematik',
      skill: SkillArea.mathematics,
      categoryId: categoryId,
      routePrefix: '/student/math',
    );
  }
}
