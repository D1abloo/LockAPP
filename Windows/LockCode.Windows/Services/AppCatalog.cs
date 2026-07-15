using Microsoft.Win32;
using System.Diagnostics;
using System.IO;
using LockCode.Windows.Models;
using Windows.Management.Deployment;

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
                    var executable = ExecutablePathPolicy.Normalize(icon);
                    found[executable] = new InstalledApp(displayName, executable)
                        { IsProtected = settings.ProtectedExecutables.Contains(executable) };
                }
            }
            catch { /* An inaccessible uninstall entry is ignored. */ }
        }
        LoadAppPaths(settings, found);
        LoadPackagedApps(settings, found);
        LoadBuiltInApps(settings, found);
        foreach (var path in settings.ManualExecutables.Where(File.Exists))
        {
            var executable = ExecutablePathPolicy.Normalize(path);
            if (string.Equals(executable, Environment.ProcessPath, StringComparison.OrdinalIgnoreCase)) continue;
            var name = FileVersionInfo.GetVersionInfo(executable).FileDescription;
            found[executable] = new InstalledApp(
                string.IsNullOrWhiteSpace(name) ? Path.GetFileNameWithoutExtension(executable) : name,
                executable) { IsProtected = settings.ProtectedExecutables.Contains(executable) };
        }
        return found.Values.OrderBy(x => x.Name, StringComparer.CurrentCultureIgnoreCase).ToList();
    }

    private static void LoadAppPaths(AppSettings settings, IDictionary<string, InstalledApp> found)
    {
        foreach (var hive in new[] { RegistryHive.CurrentUser, RegistryHive.LocalMachine })
        foreach (var view in new[] { RegistryView.Registry64, RegistryView.Registry32 })
        try
        {
            using var root = RegistryKey.OpenBaseKey(hive, view);
            using var paths = root.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\App Paths");
            if (paths is null) continue;
            foreach (var name in paths.GetSubKeyNames())
            using (var item = paths.OpenSubKey(name))
            {
                if (item?.GetValue(null) is string path) Add(path.Trim('"'), null, settings, found);
            }
        }
        catch { /* Inaccessible registry views are ignored. */ }
    }

    private static void LoadPackagedApps(AppSettings settings, IDictionary<string, InstalledApp> found)
    {
        try
        {
            foreach (var package in new PackageManager().FindPackagesForUser(string.Empty))
            {
                if (package.IsFramework || package.IsResourcePackage) continue;
                string installedPath;
                try { installedPath = package.InstalledLocation.Path; }
                catch { continue; }
                foreach (var entry in PackageManifestCatalog.Load(installedPath, package.DisplayName))
                    Add(entry.ExecutablePath, entry.Name, settings, found);
            }
        }
        catch { /* Package enumeration is best effort on restricted Windows accounts. */ }
    }

    private static void LoadBuiltInApps(AppSettings settings, IDictionary<string, InstalledApp> found)
    {
        var system = Environment.GetFolderPath(Environment.SpecialFolder.System);
        foreach (var (name, relativePath) in new[]
        {
            ("Bloc de notas", "notepad.exe"),
            ("Símbolo del sistema", "cmd.exe"),
            ("PowerShell", @"WindowsPowerShell\v1.0\powershell.exe"),
            ("Paint", "mspaint.exe"),
            ("Recortes", "SnippingTool.exe"),
            ("Conexión a Escritorio remoto", "mstsc.exe")
        }) Add(Path.Combine(system, relativePath), name, settings, found);
    }

    private static void Add(
        string path,
        string? displayName,
        AppSettings settings,
        IDictionary<string, InstalledApp> found)
    {
        if (!File.Exists(path) || !path.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)
            || string.Equals(Path.GetFullPath(path), Environment.ProcessPath, StringComparison.OrdinalIgnoreCase)) return;
        var executable = ExecutablePathPolicy.Normalize(path);
        var fileName = FileVersionInfo.GetVersionInfo(executable).FileDescription;
        var name = string.IsNullOrWhiteSpace(displayName)
            ? string.IsNullOrWhiteSpace(fileName) ? Path.GetFileNameWithoutExtension(executable) : fileName
            : displayName;
        found[executable] = new InstalledApp(name, executable)
            { IsProtected = settings.ProtectedExecutables.Contains(executable) };
    }
}
