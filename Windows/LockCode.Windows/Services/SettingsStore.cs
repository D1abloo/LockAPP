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
    }

    public void Save()
    {
        Directory.CreateDirectory(DirectoryPath);
        var temporary = FilePath + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(Value, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(temporary, FilePath, true);
    }
}
