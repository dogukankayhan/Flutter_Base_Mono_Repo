import 'package:flutter/material.dart';
import 'package:flutter_kit_ui/theme/app_brand_colors.dart';
import 'package:flutter_kit_ui/theme/app_text_style.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Hata mesajı göstermek için iki variant:
///
/// **Inline (form içi):** `isInline: true` — kompakt satır, dismiss butonu
///   AppErrorBanner(message: state.errorMessage!, isInline: true, onDismiss: _dismiss)
///
/// **Full (ekran ortası):** `isInline: false` — icon + mesaj + retry butonu
///   AppErrorBanner(message: state.errorMessage!, onRetry: _retry)
class AppErrorBanner extends StatelessWidget {
  const AppErrorBanner({
    super.key,
    required this.message,
    this.isInline = false,
    this.onDismiss,
    this.onRetry,
    this.retryLabel = 'Tekrar Dene',
  });

  final String message;
  final bool isInline;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return isInline ? _InlineBanner(this) : _FullBanner(this);
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner(this.banner);
  final AppErrorBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: AppBrandColors.error, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              banner.message,
              style: context.textStyle.paragraph12Regular.copyWith(
                    color: AppBrandColors.error,
                  ),
            ),
          ),
          if (banner.onDismiss != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: banner.onDismiss,
              child: Icon(Icons.close, color: AppBrandColors.error, size: 16.w),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullBanner extends StatelessWidget {
  const _FullBanner(this.banner);
  final AppErrorBanner banner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined,
                color: AppBrandColors.error, size: 48.w),
            SizedBox(height: 16.h),
            Text(
              banner.message,
              textAlign: TextAlign.center,
              style: context.textStyle.paragraph14Regular.copyWith(
                    color: AppBrandColors.error,
                  ),
            ),
            if (banner.onRetry != null) ...[
              SizedBox(height: 16.h),
              TextButton(
                onPressed: banner.onRetry,
                child: Text(
                  banner.retryLabel,
                  style: context.textStyle.button14Bold.copyWith(
                        color: AppBrandColors.primary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
