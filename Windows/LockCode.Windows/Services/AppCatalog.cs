using Microsoft.Win32;
using System.Diagnostics;
using System.IO;
using LockCode.Windows.Models;

namespace LockCode.Windows.Services;

public static class AppCatalog
{
    public static IReadOnlyList<InstalledApp> Load(AppSettings settings)
    {
        var found = new Dictionary<string, InstalledApp>(StringComparer.OrdinalIgnoreCase);
        foreach (var root in new[] { Registry.CurrentUser, Registry.LocalMachine })
        foreach (var view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
        {
            try
            {
                using var baseKey = RegistryKey.OpenBaseKey(root == Registry.CurrentUser
                    ? RegistryHive.CurrentUser : RegistryHive.LocalMachine, view);
                using var uninstall = baseKey.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall");
                if (uninstall is null) continue;
                foreach (var name in uninstall.GetSubKeyNames())
                using (var item = uninstall.OpenSubKey(name))
                {
                    var displayName = item?.GetValue("DisplayName") as string;
                    var icon = (item?.GetValue("DisplayIcon") as string)?.Split(',')[0].Trim('"');
                    if (string.IsNullOrWhiteSpace(displayName) || string.IsNullOrWhiteSpace(icon)
                        || !icon.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) || !File.Exists(icon)) continue;
                    found[icon] = new InstalledApp(displayName, icon)
                        { IsProtected = settings.ProtectedExecutables.Contains(icon) };
                }
            }
            catch { /* An inaccessible uninstall entry is ignored. */ }
        }
        foreach (var path in settings.ManualExecutables.Where(File.Exists))
        {
            var executable = Path.GetFullPath(path);
            if (string.Equals(executable, Environment.ProcessPath, StringComparison.OrdinalIgnoreCase)) continue;
            var name = FileVersionInfo.GetVersionInfo(executable).FileDescription;
            found[executable] = new InstalledApp(
                string.IsNullOrWhiteSpace(name) ? Path.GetFileNameWithoutExtension(executable) : name,
                executable) { IsProtected = settings.ProtectedExecutables.Contains(executable) };
        }
        return found.Values.OrderBy(x => x.Name, StringComparer.CurrentCultureIgnoreCase).ToList();
    }
}
