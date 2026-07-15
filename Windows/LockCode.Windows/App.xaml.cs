using System.Threading;
using System.Windows;
using LockCode.Windows.Services;

namespace LockCode.Windows;

public partial class App : System.Windows.Application
{
    private Mutex? _singleInstance;
    private MainWindow? _window;
    private System.Windows.Forms.NotifyIcon? _tray;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        if (e.Args.Contains("--smoke-test", StringComparer.OrdinalIgnoreCase))
        {
            _window = new MainWindow();
            _window.DisposeServices();
            Shutdown();
            return;
        }
        _singleInstance = new Mutex(true, "Local\\LockCode.Windows", out var first);
        if (!first) { Shutdown(); return; }

        _window = new MainWindow();
        var appIcon = System.Drawing.Icon.ExtractAssociatedIcon(Environment.ProcessPath!);
        _tray = new System.Windows.Forms.NotifyIcon
        {
            Text = "LockCode",
            Icon = appIcon ?? System.Drawing.SystemIcons.Shield,
            Visible = true,
            ContextMenuStrip = BuildMenu()
        };
        _tray.DoubleClick += async (_, _) => await ShowWindowAsync();
        if (!e.Args.Contains("--background", StringComparer.OrdinalIgnoreCase)) _ = ShowWindowAsync();
    }

    private System.Windows.Forms.ContextMenuStrip BuildMenu()
    {
        var menu = new System.Windows.Forms.ContextMenuStrip();
        menu.Items.Add("Abrir LockCode", null, async (_, _) => await ShowWindowAsync());
        menu.Items.Add("Bloquear ahora", null, (_, _) => _window?.LockNow());
        menu.Items.Add("Salir", null, async (_, _) =>
        {
            if (_window is not null && await _window.AuthorizeExitAsync())
            {
                _window.DisposeServices();
                _tray!.Visible = false;
                Shutdown();
            }
        });
        return menu;
    }

    private async Task ShowWindowAsync()
    {
        if (_window is null || !await _window.AuthorizeManagementAsync()) return;
        _window?.Show();
        _window?.Activate();
    }

    protected override void OnSessionEnding(SessionEndingCancelEventArgs e)
    {
        _window?.AllowSystemExit();
        _window?.DisposeServices();
        if (_tray is not null) _tray.Visible = false;
        base.OnSessionEnding(e);
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (_tray is not null) _tray.Dispose();
        _singleInstance?.Dispose();
        base.OnExit(e);
    }
}
