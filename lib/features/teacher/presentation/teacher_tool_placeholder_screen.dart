import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';

class TeacherToolPlaceholderScreen extends StatelessWidget {
  const TeacherToolPlaceholderScreen({
    super.key,
    required this.title,
    required this.note,
  });

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EducationStatusPanel(
                title: title,
                body: note,
                icon: Icons.handyman_outlined,
              ),
              const Spacer(),
              LulunaPrimaryButton(
                label: 'Panele dön',
                onPressed: () => context.go('/teacher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
