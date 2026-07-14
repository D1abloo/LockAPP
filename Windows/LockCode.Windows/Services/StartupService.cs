using Microsoft.Win32;

namespace LockCode.Windows.Services;

public static class StartupService
{
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    public static void SetEnabled(bool enabled)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RunKey);
        if (enabled)
            key.SetValue("LockCode", $"\"{Environment.ProcessPath}\" --background", RegistryValueKind.String);
        else key.DeleteValue("LockCode", false);
    }
    public static bool IsEnabled()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKey);
        return key?.GetValue("LockCode") is string;
    }
}
