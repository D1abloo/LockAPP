using Windows.Security.Credentials.UI;

namespace LockCode.Windows.Services;

public static class BiometricService
{
    public static async Task<bool> AuthenticateAsync(string message)
    {
        try
        {
            if (await UserConsentVerifier.CheckAvailabilityAsync() != UserConsentVerifierAvailability.Available)
                return false;
            return await UserConsentVerifier.RequestVerificationAsync(message)
                == UserConsentVerificationResult.Verified;
        }
        catch { return false; }
    }
}
