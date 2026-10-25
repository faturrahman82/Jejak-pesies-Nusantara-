import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class RequestState extends StatelessWidget {
  const RequestState.loading({super.key})
    : message = 'Sedang mencari catatan spesies…',
      onRetry = null,
      isLoading = true;
  const RequestState.error({
    super.key,
    required this.message,
    required this.onRetry,
  }) : isLoading = false;
  const RequestState.empty({super.key, required this.message})
    : onRetry = null,
      isLoading = false;

  final String message;
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const CircularProgressIndicator(color: AppColors.forest)
          else
            Icon(
              onRetry == null ? Icons.search_off : Icons.wifi_off,
              size: 34,
              color: AppColors.forest,
            ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    ),
  );
}
