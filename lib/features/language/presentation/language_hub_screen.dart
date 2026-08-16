import 'package:flutter/material.dart';

import '../../../data/models/skill_level.dart';
import '../../education/presentation/category_hub_screen.dart';
import '../data/language_categories.dart';

class LanguageHubScreen extends StatelessWidget {
  const LanguageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryHubScreen(
      title: 'Türkçe',
      skill: SkillArea.language,
      categories: LanguageCategories.mvp,
      routePrefix: '/student/language',
    );
  }
}

class LanguageDifficultyScreen extends StatelessWidget {
  const LanguageDifficultyScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final cat = LanguageCategories.byId(categoryId);
    return DifficultySelectScreen(
      title: cat?.title ?? 'Türkçe',
      skill: SkillArea.language,
      categoryId: categoryId,
      routePrefix: '/student/language',
    );
  }
}
