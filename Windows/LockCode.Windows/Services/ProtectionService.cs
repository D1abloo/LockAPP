using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using LockCode.Windows.Models;

namespace LockCode.Windows.Services;

public sealed class ProtectionService : IDisposable
{
    public sealed record Request(Process Process, string Path);
    private readonly SettingsStore _settings;
    private readonly System.Threading.Timer _timer;
    private readonly PendingRequestState _pending = new();
    private readonly AccessGrantState _grants = new();
    private readonly HiddenWindowState _hiddenWindows = new();
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
        int[] processIds;
        lock (_pending) processIds = _pending.Complete(request.Path);
        if (processIds.Length == 0) processIds = [request.Process.Id];
        lock (_grants)
        {
            _grants.Approve(request.Path, processIds,
                _settings.Value.GraceMinutes, DateTimeOffset.Now);
        }
        try
        {
            if (processIds.Any(IsProcessLiving))
                Restore(processIds);
            else Process.Start(new ProcessStartInfo(request.Path) { UseShellExecute = true });
        }
        catch { }
        finally { request.Process.Dispose(); }
    }

    public void Deny(Request request)
    {
        // The app is only asked to close after authentication is cancelled, never before.
        try
        {
            int[] processIds;
            lock (_pending) processIds = _pending.Members(request.Path);
            foreach (var processId in processIds)
                try { using var process = Process.GetProcessById(processId); process.CloseMainWindow(); }
                catch { }
        }
        catch { }
        finally { request.Process.Dispose(); }
    }

    private void Check()
    {
        if (!_settings.Value.ProtectionEnabled || Interlocked.Exchange(ref _checking, 1) != 0) return;
        try
        {
            var processes = Process.GetProcesses();
            var living = processes.Select(process => process.Id).ToHashSet();
            lock (_pending) _pending.Retain(living);
            lock (_hiddenWindows) _hiddenWindows.Retain(living);
            foreach (var process in processes)
            {
                var rawPath = ExecutablePath(process);
                if (rawPath is null) { process.Dispose(); continue; }
                var path = ExecutablePathPolicy.Normalize(rawPath);
                if (path.Equals(Environment.ProcessPath, StringComparison.OrdinalIgnoreCase)
                    || !_settings.Value.ProtectedExecutables.Contains(path) || IsGranted(path, process)) { process.Dispose(); continue; }
                bool first;
                lock (_pending) first = _pending.Begin(path, process.Id);
                var hidden = Hide(process);
                lock (_hiddenWindows) _hiddenWindows.Remember(process.Id, hidden);
                if (!first) { process.Dispose(); continue; }
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

    private static string? ExecutablePath(Process process)
    {
        try { return process.MainModule?.FileName; }
        catch
        {
            try
            {
                var path = new StringBuilder(32_768);
                var length = (uint)path.Capacity;
                return QueryFullProcessImageName(process.Handle, 0, path, ref length)
                    ? path.ToString() : null;
            }
            catch { return null; }
        }
    }

    private static nint[] Hide(Process process)
    {
        var hidden = new List<nint>();
        try
        {
            EnumWindows((window, _) =>
            {
                GetWindowThreadProcessId(window, out var pid);
                if (pid == process.Id && IsWindowVisible(window))
                {
                    hidden.Add(window);
                    ShowWindow(window, 0);
                }
                return true;
            }, IntPtr.Zero);
        }
        catch { }
        return hidden.ToArray();
    }

    private void Restore(IEnumerable<int> processIds)
    {
        nint[] windows;
        lock (_hiddenWindows) windows = _hiddenWindows.Take(processIds);
        foreach (var window in windows) ShowWindow(window, 9);
    }

    public void Dispose()
    {
        _timer.Dispose();
        lock (_pending) _pending.Drain();
        nint[] windows;
        lock (_hiddenWindows) windows = _hiddenWindows.Drain();
        foreach (var window in windows) ShowWindow(window, 9);
    }
    private delegate bool EnumWindowsProc(IntPtr window, IntPtr parameter);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr parameter);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out int processId);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr window, int command);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool QueryFullProcessImageName(
        IntPtr process,
        uint flags,
        StringBuilder executableName,
        ref uint size);
}
