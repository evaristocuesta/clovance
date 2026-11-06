using Clovance.ApiService.Shared;
using FluentValidation.Results;

namespace Clovance.ApiService.Features.Shared;

public static class AppErrors
{
    public static class Common
    {
        public static Error ValidationFailed(IEnumerable<ValidationFailure> failures)
        {
            var errors = failures
                .Where(f => f is not null)
                .GroupBy(f => f.PropertyName)
                .ToDictionary(
                    group => group.Key,
                    group => new
                    {
                        codes = group
                            .Select(f => NormalizeValidationErrorCode(f.ErrorCode))
                            .Distinct()
                            .ToArray()
                    });

            return new Error(
                ErrorCodes.Common.ValidationFailed,
                "Validation failed.",
                StatusCodes.Status400BadRequest,
                new Dictionary<string, object?>
                {
                    ["errors"] = errors
                });
        }

        private static string NormalizeValidationErrorCode(string? errorCode)
        {
            if (string.IsNullOrWhiteSpace(errorCode))
            {
                return ErrorCodes.Common.ValidationFailed;
            }

            return errorCode.Contains('.', StringComparison.Ordinal)
                ? errorCode
                : ErrorCodes.Common.ValidationFailed;
        }

        public static Error StaleData() =>
            CreateConflict(ErrorCodes.Common.StaleData, "The record was modified by someone else.");
    }

    public static class Auth
    {
        public static Error EmailSendFailed() =>
            CreateConflict(ErrorCodes.Auth.EmailSendFailed, "Failed to send email.");

        public static Error InvalidCredentials() =>
            CreateUnauthorized(ErrorCodes.Auth.InvalidCredentials, "Invalid credentials.");

        public static Error AccountLocked() =>
            CreateLocked(ErrorCodes.Auth.AccountLocked, "Account is locked due to repeated failed login attempts.");

        public static Error UserNotAuthenticated() =>
            CreateUnauthorized(ErrorCodes.Auth.UserNotAuthenticated, "User is not authenticated.");

        public static Error UserNotFound() =>
            CreateNotFound(ErrorCodes.Auth.UserNotFound, "User not found.");

        public static Error UserDeletionFailed() =>
            CreateConflict(ErrorCodes.Auth.UserDeletionFailed, "Failed to delete user.");

        public static Error UserUpdateFailed() =>
            CreateConflict(ErrorCodes.Auth.UserUpdateFailed, "Failed to update user.");

        public static Error InvitationInvalidOrExpired() =>
            CreateUnauthorized(ErrorCodes.Auth.InvitationInvalidOrExpired, "Invalid or expired invitation.");

        public static Error PasswordResetFailed(string details) =>
            CreateConflict(ErrorCodes.Auth.PasswordChangeFailed, $"Failed to reset password: {details}");

        public static Error PasswordResetInvalidOrExpiredResetToken() =>
            CreateBadRequest(ErrorCodes.Auth.PasswordResetInvalidOrExpiredResetToken, "Invalid or expired password reset token.");

        public static Error UserAlreadyExists() =>
            CreateConflict(ErrorCodes.Auth.UserAlreadyExists, "A user with this email already exists.");

        public static Error ActiveInvitationAlreadyExists() =>
            CreateConflict(ErrorCodes.Auth.ActiveInvitationAlreadyExists, "There is already an active invitation for this email.");

        public static Error PasswordChangeFailed(string details) =>
            CreateConflict(ErrorCodes.Auth.PasswordChangeFailed, $"Failed to change password: {details}");

        public static Error UserCreationFailed(string details) =>
            CreateConflict(ErrorCodes.Auth.UserCreationFailed, $"Failed to create user: {details}");

        public static Error SetupAlreadyBeenCompleted() =>
            CreateConflict(ErrorCodes.Auth.SetupAlreadyBeenCompleted, "Setup has already been completed.");
        
        public static Error SetupIsNotCompleted() =>
            CreateConflict(ErrorCodes.Auth.SetupIsNotCompleted, "Setup is not completed.");

        public static Error EmailNotConfigured() =>
            CreateConflict(ErrorCodes.Auth.EmailNotConfigured, "Email service is not configured.");
    }

    public static class Accounts
    {
        public static Error AccountNotFound() =>
            CreateNotFound(ErrorCodes.Accounts.AccountNotFound, "Account not found.");

        public static Error AccountNameRequired() =>
            CreateBadRequest(ErrorCodes.Accounts.AccountNameRequired, "Account name is required.");

        public static Error InvalidAccount() =>
            CreateBadRequest(ErrorCodes.Accounts.AccountTypeInvalid, "Invalid Account type");
    }

    public static class Transactions
    {
        public static Error TransactionNotFound() =>
            CreateNotFound(ErrorCodes.Transactions.TransactionNotFound, "Transaction not found.");
    }

    private static Error CreateUnauthorized(string code, string description) =>
        new(code, description, StatusCodes.Status401Unauthorized);

    private static Error CreateConflict(string code, string description) =>
        new(code, description, StatusCodes.Status409Conflict);

    private static Error CreateBadRequest(string code, string description) =>
        new(code, description, StatusCodes.Status400BadRequest);

    private static Error CreateNotFound(string code, string description) =>
        new(code, description, StatusCodes.Status404NotFound);

    private static Error CreateForbidden(string code, string description) =>
        new(code, description, StatusCodes.Status403Forbidden);

    private static Error CreateLocked(string code, string description) =>
        new(code, description, StatusCodes.Status423Locked);
}
