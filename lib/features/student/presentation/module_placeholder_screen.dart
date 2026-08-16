import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';

/// Modül iskelet ekranı — etkinlik motoru sonraki fazlarda gelir.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.phaseNote,
  });

  final String title;
  final String phaseNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student');
            }
          },
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
                body: phaseNote,
                icon: Icons.construction_outlined,
              ),
              const Spacer(),
              LulunaPrimaryButton(
                label: 'Ana sayfaya dön',
                icon: Icons.home_outlined,
                onPressed: () => context.go('/student'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
