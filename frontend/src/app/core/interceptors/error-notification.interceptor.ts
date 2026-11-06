import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { catchError, take, throwError } from 'rxjs';
import { ToastService } from '@shared/ui/toast/toast.service';

/**
 * Internal/background calls that must fail silently: a failed token refresh or logout is not a
 * user-facing error (the former happens on every anonymous page load, the latter is already
 * swallowed by `AuthService`).
 */
const SILENT_URLS = ['/auth/refresh', '/auth/logout'];

/**
 * Shows a toast for any failed API call, as a safety net on top of the inline error messages
 * forms already render. `err.error.errorCode` is used directly as a Transloco key, same as the
 * per-form handlers, because the backend's error codes (e.g. `auth.invalid_credentials`) are
 * already translated under those exact keys.
 */
export const errorNotificationInterceptor: HttpInterceptorFn = (req, next) => {
  const isApiCall = req.url.startsWith('/api/');
  const isSilent = SILENT_URLS.some((url) => req.url.includes(url));

  if (!isApiCall || isSilent) {
    return next(req);
  }

  const toastService = inject(ToastService);
  const translocoService = inject(TranslocoService);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      const errorCode = error?.error?.errorCode as string | undefined;
      const key = errorCode ? errorCode : 'common.unexpected_error';
      translocoService
        .selectTranslate<string>(key)
        .pipe(take(1))
        .subscribe((message) => toastService.error(message));

      return throwError(() => error);
    }),
  );
};
