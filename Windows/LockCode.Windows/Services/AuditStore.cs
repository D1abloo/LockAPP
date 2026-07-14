using System.Text.Json;
using System.IO;
using LockCode.Windows.Models;

namespace LockCode.Windows.Services;

public sealed class AuditStore
{
    private readonly string _path = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LockCode", "audit.json");
    public IReadOnlyList<AccessEvent> Read()
    {
        try { return JsonSerializer.Deserialize<List<AccessEvent>>(File.ReadAllText(_path)) ?? []; }
        catch { return []; }
    }
    public void Record(string kind)
    {
        var events = Read().Append(new AccessEvent(DateTimeOffset.Now, kind)).TakeLast(200).ToList();
        Directory.CreateDirectory(Path.GetDirectoryName(_path)!);
        File.WriteAllText(_path, JsonSerializer.Serialize(events));
    }
    public void Clear() { if (File.Exists(_path)) File.Delete(_path); }
}
