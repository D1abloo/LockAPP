namespace LockCode.Windows.Models;

public sealed class AppSettings
{
    public bool ProtectionEnabled { get; set; } = true;
    public bool BiometricsEnabled { get; set; } = true;
    public bool StartWithWindows { get; set; } = true;
    public int GraceMinutes { get; set; }
    public HashSet<string> ProtectedExecutables { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public sealed record InstalledApp(string Name, string ExecutablePath)
{
    public bool IsProtected { get; set; }
}

public sealed record AccessEvent(DateTimeOffset At, string Kind);

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
    {
        _grants[path] = minutes > 0
            ? new Grant(now.AddMinutes(minutes), [])
            : new Grant(null, [processId]);
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
        return grant.ProcessIds.Contains(processId);
    }
    public void InvalidateAll() => _grants.Clear();
}

public sealed class PendingRequestState
{
    private readonly HashSet<int> _processIds = [];
    public bool Begin(int processId) => _processIds.Add(processId);
    public void Complete(int processId) => _processIds.Remove(processId);
    public void Retain(ISet<int> living) => _processIds.RemoveWhere(pid => !living.Contains(pid));
    public int[] Drain() { var result = _processIds.ToArray(); _processIds.Clear(); return result; }
}
