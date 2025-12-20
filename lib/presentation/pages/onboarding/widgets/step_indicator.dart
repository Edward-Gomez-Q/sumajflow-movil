import 'package:flutter/material.dart';

/// Indicador visual de pasos
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Row(
      children: List.generate(
        totalSteps,
            (index) => Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildStep(
                  theme: theme,
                  stepNumber: index + 1,
                  isActive: index == currentStep,
                  isCompleted: index < currentStep,
                ),
              ),
              if (index < totalSteps - 1)
                _buildConnector(
                  theme: theme,
                  isCompleted: index < currentStep,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required ThemeData theme,
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color bgColor;
    Color textColor;
    Widget icon;

    if (isCompleted) {
      bgColor = theme.colorScheme.primary;
      textColor = Colors.white;
      icon = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      bgColor = theme.colorScheme.primary;
      textColor = Colors.white;
      icon = Text(
        '$stepNumber',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      bgColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface.withOpacity(0.4);
      icon = Text(
        '$stepNumber',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive || isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(child: icon),
    );
  }

  Widget _buildConnector({
    required ThemeData theme,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isCompleted
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.2),
      ),
    );
  }
}