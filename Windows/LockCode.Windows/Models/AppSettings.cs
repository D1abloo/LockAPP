using System.IO;

namespace LockCode.Windows.Models;

public sealed class AppSettings
{
    public bool ProtectionEnabled { get; set; } = true;
    public bool BiometricsEnabled { get; set; } = true;
    public bool StartWithWindows { get; set; } = true;
    public int GraceMinutes { get; set; }
    public HashSet<string> ProtectedExecutables { get; set; } = new(StringComparer.OrdinalIgnoreCase);
    public HashSet<string> ManualExecutables { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public sealed record InstalledApp(string Name, string ExecutablePath)
{
    public bool IsProtected { get; set; }
}

public sealed record AccessEvent(DateTimeOffset At, string Kind);

public static class ExecutablePathPolicy
{
    public static string Normalize(string path)
    {
        try
        {
            var executable = Path.GetFullPath(path);
            var versionDirectory = Directory.GetParent(executable);
            if (versionDirectory?.Parent is not null
                && Version.TryParse(versionDirectory.Name, out _))
            {
                var launcher = Path.Combine(versionDirectory.Parent.FullName, Path.GetFileName(executable));
                if (File.Exists(launcher)) return launcher;
            }
            return executable;
        }
        catch { return path; }
    }
}

public sealed class AttemptLimiter
{
    public int Failures { get; private set; }
    public DateTimeOffset BlockedUntil { get; private set; }
    public bool CanAttempt(DateTimeOffset now) => now >= BlockedUntil;
    public TimeSpan Failed(DateTimeOffset now)
    {
        Failures++;
        var seconds = Failures < 3 ? 0 : Math.Min(300, Math.Pow(2, Failures - 3));
        var delay = TimeSpan.FromSeconds(seconds); BlockedUntil = now + delay; return delay;
    }
    public void Succeeded() { Failures = 0; BlockedUntil = default; }
}

public sealed class AccessGrantState
{
    private sealed record Grant(DateTimeOffset? Until, HashSet<int> ProcessIds);
    private readonly Dictionary<string, Grant> _grants = new(StringComparer.OrdinalIgnoreCase);
    public void Approve(string path, int processId, int minutes, DateTimeOffset now)
        => Approve(path, [processId], minutes, now);
    public void Approve(string path, IEnumerable<int> processIds, int minutes, DateTimeOffset now)
    {
        _grants[path] = minutes > 0
            ? new Grant(now.AddMinutes(minutes), [])
            : new Grant(null, processIds.ToHashSet());
    }
    public bool IsGranted(string path, int processId, DateTimeOffset now, Func<int, bool> isLiving)
    {
        if (!_grants.TryGetValue(path, out var grant)) return false;
        if (grant.Until is not null)
        {
            if (grant.Until > now) return true;
            _grants.Remove(path); return false;
        }
        grant.ProcessIds.RemoveWhere(pid => !isLiving(pid));
        if (grant.ProcessIds.Count == 0) { _grants.Remove(path); return false; }
        grant.ProcessIds.Add(processId);
        return true;
    }
    public void InvalidateAll() => _grants.Clear();
}

public sealed class PendingRequestState
{
    private readonly Dictionary<string, HashSet<int>> _requests = new(StringComparer.OrdinalIgnoreCase);
    public bool Begin(string path, int processId)
    {
        if (_requests.TryGetValue(path, out var processIds))
        {
            processIds.Add(processId);
            return false;
        }
        _requests[path] = [processId];
        return true;
    }
    public int[] Complete(string path)
    {
        if (!_requests.Remove(path, out var processIds)) return [];
        return processIds.ToArray();
    }
    public int[] Members(string path) => _requests.TryGetValue(path, out var processIds) ? processIds.ToArray() : [];
    public void Retain(ISet<int> living)
    {
        foreach (var (path, processIds) in _requests.ToArray())
        {
            processIds.RemoveWhere(pid => !living.Contains(pid));
            if (processIds.Count == 0) _requests.Remove(path);
        }
    }
    public int[] Drain()
    {
        var result = _requests.Values.SelectMany(processIds => processIds).Distinct().ToArray();
        _requests.Clear();
        return result;
    }
}
