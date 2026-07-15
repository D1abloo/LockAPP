using System.IO;
using System.Xml.Linq;

namespace LockCode.Windows.Services;

public static class PackageManifestCatalog
{
    public sealed record Entry(string Name, string ExecutablePath);

    public static IReadOnlyList<Entry> Load(string installedPath, string packageName)
    {
        var root = Path.GetFullPath(installedPath);
        var manifestPath = Path.Combine(root, "AppxManifest.xml");
        if (!File.Exists(manifestPath)) return [];

        try
        {
            var entries = new List<Entry>();
            foreach (var application in XDocument.Load(manifestPath).Descendants()
                         .Where(element => element.Name.LocalName == "Application"))
            {
                var executable = application.Attributes()
                    .FirstOrDefault(attribute => attribute.Name.LocalName == "Executable")?.Value;
                if (string.IsNullOrWhiteSpace(executable)) continue;
                var path = Path.GetFullPath(Path.Combine(root, executable.Replace('/', Path.DirectorySeparatorChar)));
                if (!path.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)
                    || !path.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) || !File.Exists(path)) continue;
                var displayName = application.Attributes()
                    .FirstOrDefault(attribute => attribute.Name.LocalName == "DisplayName")?.Value;
                entries.Add(new Entry(
                    string.IsNullOrWhiteSpace(displayName) || displayName.StartsWith("ms-resource:", StringComparison.OrdinalIgnoreCase)
                        ? packageName : displayName,
                    path));
            }
            return entries;
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or System.Xml.XmlException)
        {
            return [];
        }
    }
}
