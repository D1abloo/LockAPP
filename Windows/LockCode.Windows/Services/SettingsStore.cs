using System.Text.Json;
using System.IO;
using LockCode.Windows.Models;

namespace LockCode.Windows.Services;

public sealed class SettingsStore
{
    private static readonly string DirectoryPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LockCode");
    private static readonly string FilePath = Path.Combine(DirectoryPath, "settings.json");
    public AppSettings Value { get; private set; }

    public SettingsStore()
    {
        Directory.CreateDirectory(DirectoryPath);
        try { Value = JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(FilePath)) ?? new(); }
        catch { Value = new(); }
        var protectedExecutables = Value.ProtectedExecutables
            .Select(ExecutablePathPolicy.Normalize).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var manualExecutables = Value.ManualExecutables
            .Select(ExecutablePathPolicy.Normalize).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var changed = !protectedExecutables.SetEquals(Value.ProtectedExecutables)
            || !manualExecutables.SetEquals(Value.ManualExecutables);
        Value.ProtectedExecutables = protectedExecutables;
        Value.ManualExecutables = manualExecutables;
        if (changed) Save();
    }

    public void Save()
    {
        Directory.CreateDirectory(DirectoryPath);
        var temporary = FilePath + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(Value, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(temporary, FilePath, true);
    }
}
