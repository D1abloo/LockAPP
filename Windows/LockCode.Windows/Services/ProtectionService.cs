using System.Diagnostics;
using System.Runtime.InteropServices;
using LockCode.Windows.Models;

namespace LockCode.Windows.Services;

public sealed class ProtectionService : IDisposable
{
    public sealed record Request(Process Process, string Path);
    private readonly SettingsStore _settings;
    private readonly System.Threading.Timer _timer;
    private readonly PendingRequestState _pending = new();
    private readonly AccessGrantState _grants = new();
    private int _checking;
    public event Action<Request>? Blocked;

    public ProtectionService(SettingsStore settings)
    {
        _settings = settings;
        _timer = new System.Threading.Timer(_ => Check(), null, TimeSpan.Zero, TimeSpan.FromMilliseconds(250));
    }

    public void LockNow() { lock (_grants) _grants.InvalidateAll(); }

    public void Approve(Request request)
    {
        lock (_pending) _pending.Complete(request.Process.Id);
        lock (_grants)
        {
            _grants.Approve(request.Path, request.Process.Id,
                _settings.Value.GraceMinutes, DateTimeOffset.Now);
        }
        try
        {
            if (!request.Process.HasExited) EnumWindows((window, _) =>
            {
                GetWindowThreadProcessId(window, out var pid);
                if (pid == request.Process.Id) ShowWindow(window, 9);
                return true;
            }, IntPtr.Zero);
            else Process.Start(new ProcessStartInfo(request.Path) { UseShellExecute = true });
        }
        catch { }
        finally { request.Process.Dispose(); }
    }

    public void Deny(Request request)
    {
        // Keep this PID pending and concealed. A fresh launch receives a new PID and request.
        request.Process.Dispose();
    }

    private void Check()
    {
        if (!_settings.Value.ProtectionEnabled || Interlocked.Exchange(ref _checking, 1) != 0) return;
        try
        {
            var processes = Process.GetProcesses();
            lock (_pending) _pending.Retain(processes.Select(process => process.Id).ToHashSet());
            foreach (var process in processes)
            {
                string? path;
                try { path = process.MainModule?.FileName; } catch { process.Dispose(); continue; }
                if (path is null || path.Equals(Environment.ProcessPath, StringComparison.OrdinalIgnoreCase)
                    || !_settings.Value.ProtectedExecutables.Contains(path) || IsGranted(path, process)) { process.Dispose(); continue; }
                lock (_pending) if (!_pending.Begin(process.Id)) { Hide(process); process.Dispose(); continue; }
                Hide(process);
                Blocked?.Invoke(new Request(process, path));
            }
        }
        finally { Volatile.Write(ref _checking, 0); }
    }

    private bool IsGranted(string path, Process process)
    {
        lock (_grants) return _grants.IsGranted(path, process.Id, DateTimeOffset.Now, IsProcessLiving);
    }

    private static bool IsProcessLiving(int processId)
    {
        try { using var process = Process.GetProcessById(processId); return !process.HasExited; }
        catch { return false; }
    }

    private static void Hide(Process process)
    {
        try
        {
            EnumWindows((window, _) => { GetWindowThreadProcessId(window, out var pid); if (pid == process.Id) ShowWindow(window, 0); return true; }, IntPtr.Zero);
            process.CloseMainWindow(); // Normal close only; never Kill().
        }
        catch { }
    }

    public void Dispose()
    {
        _timer.Dispose();
        int[] pending;
        lock (_pending) pending = _pending.Drain();
        foreach (var processId in pending)
            EnumWindows((window, _) => { GetWindowThreadProcessId(window, out var pid); if (pid == processId) ShowWindow(window, 9); return true; }, IntPtr.Zero);
    }
    private delegate bool EnumWindowsProc(IntPtr window, IntPtr parameter);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr parameter);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out int processId);
    [DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr window, int command);
}
