using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Net.Http;
using System.Windows;
using LockCode.Windows.Models;
using LockCode.Windows.Services;

namespace LockCode.Windows;

public partial class MainWindow : Window
{
    private readonly CredentialStore _credentials = new();
    private readonly SettingsStore _settings = new();
    private readonly AuditStore _audit = new();
    private readonly ProtectionService _protection;
    private readonly ObservableCollection<InstalledApp> _apps = [];
    private readonly AttemptLimiter _limiter = new();
    private bool _loading;
    private bool _allowClose;
    private bool _managementAuthorized;

    public MainWindow()
    {
        InitializeComponent();
        AppsList.ItemsSource = _apps;
        _protection = new ProtectionService(_settings);
        _protection.Blocked += request => Dispatcher.BeginInvoke(async () => await AuthenticateRequestAsync(request));
        Loaded += async (_, _) => await InitializeAsync();
        Closing += OnClosing;
    }

    private async Task InitializeAsync()
    {
        if (!_credentials.HasCode)
        {
            var setup = new CodeDialog("Crear código", true) { Owner = this };
            if (setup.ShowDialog() != true) return;
            _credentials.SetCode(setup.Code);
        }
        LoadSettings();
        RefreshApps();
        RefreshAudit();
        StartupService.SetEnabled(_settings.Value.StartWithWindows);
        await CheckUpdateAsync(false);
    }

    private async Task AuthenticateRequestAsync(ProtectionService.Request request)
    {
        var approved = _settings.Value.BiometricsEnabled
            && await BiometricService.AuthenticateAsync("Desbloquear aplicación protegida con LockCode");
        if (!approved && _limiter.CanAttempt(DateTimeOffset.Now))
        {
            var dialog = new CodeDialog("Aplicación protegida", false) { Owner = this };
            if (dialog.ShowDialog() == true) approved = _credentials.Verify(dialog.Code);
        }
        if (approved) { _limiter.Succeeded(); _audit.Record("Desbloqueo correcto"); _protection.Approve(request); }
        else { _limiter.Failed(DateTimeOffset.Now); _audit.Record("Intento fallido o cancelado"); _protection.Deny(request); }
        RefreshAudit();
    }

    public async Task<bool> AuthorizeExitAsync()
    {
        if (_settings.Value.BiometricsEnabled && await BiometricService.AuthenticateAsync("Confirmar salida de LockCode")) return true;
        var dialog = new CodeDialog("Salir de LockCode", false) { Owner = this };
        return dialog.ShowDialog() == true && _credentials.Verify(dialog.Code);
    }

    public async Task<bool> AuthorizeManagementAsync()
    {
        if (!_credentials.HasCode || _managementAuthorized) return true;
        var approved = _settings.Value.BiometricsEnabled
            && await BiometricService.AuthenticateAsync("Acceder a la configuración de LockCode");
        if (!approved)
        {
            var dialog = new CodeDialog("Acceder a LockCode", false) { Owner = IsVisible ? this : null };
            approved = dialog.ShowDialog() == true && _credentials.Verify(dialog.Code);
        }
        if (!approved) _audit.Record("Intento fallido");
        _managementAuthorized = approved;
        return approved;
    }

    public void LockNow() => _protection.LockNow();
    public void AllowSystemExit() => _allowClose = true;
    public void DisposeServices() { _allowClose = true; _protection.Dispose(); }
    private void OnClosing(object? sender, CancelEventArgs e)
    {
        if (_allowClose) return;
        e.Cancel = true; _managementAuthorized = false; Hide();
    }
    private void LockNow_Click(object sender, RoutedEventArgs e) => LockNow();
    private void Refresh_Click(object sender, RoutedEventArgs e) => RefreshApps();

    private void RefreshApps()
    {
        _apps.Clear();
        foreach (var app in AppCatalog.Load(_settings.Value)) _apps.Add(app);
    }

    private void ProtectionChanged(object sender, RoutedEventArgs e)
    {
        if (_loading || (sender as FrameworkElement)?.DataContext is not InstalledApp app) return;
        if (app.IsProtected) _settings.Value.ProtectedExecutables.Add(app.ExecutablePath);
        else _settings.Value.ProtectedExecutables.Remove(app.ExecutablePath);
        _settings.Save();
    }

    private void LoadSettings()
    {
        _loading = true;
        ProtectionEnabled.IsChecked = _settings.Value.ProtectionEnabled;
        BiometricsEnabled.IsChecked = _settings.Value.BiometricsEnabled;
        StartupEnabled.IsChecked = _settings.Value.StartWithWindows;
        GraceMinutes.Text = _settings.Value.GraceMinutes.ToString();
        _loading = false;
    }

    private void SettingsChanged(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        _settings.Value.ProtectionEnabled = ProtectionEnabled.IsChecked == true;
        _settings.Value.BiometricsEnabled = BiometricsEnabled.IsChecked == true;
        _settings.Value.StartWithWindows = StartupEnabled.IsChecked == true;
        _settings.Value.GraceMinutes = int.TryParse(GraceMinutes.Text, out var minutes) ? Math.Clamp(minutes, 0, 1440) : 0;
        _settings.Save();
        StartupService.SetEnabled(_settings.Value.StartWithWindows);
    }

    private void ChangeCode_Click(object sender, RoutedEventArgs e)
    {
        var current = new CodeDialog("Código actual", false) { Owner = this };
        if (current.ShowDialog() != true || !_credentials.Verify(current.Code)) { _audit.Record("Intento fallido"); return; }
        var next = new CodeDialog("Nuevo código", true) { Owner = this };
        if (next.ShowDialog() == true) _credentials.SetCode(next.Code);
    }

    private void RefreshAudit()
    {
        AuditList.ItemsSource = _audit.Read().Reverse().Select(x => $"{x.At.LocalDateTime:g} — {x.Kind}");
    }
    private void ClearAudit_Click(object sender, RoutedEventArgs e) { _audit.Clear(); RefreshAudit(); }
    private async void Updates_Click(object sender, RoutedEventArgs e) => await CheckUpdateAsync(true);
    private void Donate_Click(object sender, RoutedEventArgs e) => Process.Start(
        new ProcessStartInfo("https://www.paypal.com/paypalme/kin_coriano14") { UseShellExecute = true });

    private static async Task CheckUpdateAsync(bool interactive)
    {
        try
        {
            using var client = new HttpClient();
            client.DefaultRequestHeaders.UserAgent.ParseAdd("LockCode-Windows/0.1.0");
            var json = await client.GetStringAsync("https://api.github.com/repos/D1abloo/LockAPP/releases/latest");
            using var document = System.Text.Json.JsonDocument.Parse(json);
            var hasWindowsInstaller = document.RootElement.GetProperty("assets").EnumerateArray()
                .Any(asset => asset.GetProperty("name").GetString()?.Contains("Windows", StringComparison.OrdinalIgnoreCase) == true);
            if (!hasWindowsInstaller) { if (interactive) System.Windows.MessageBox.Show("No hay un instalador de Windows publicado.", "LockCode"); return; }
            var tag = document.RootElement.GetProperty("tag_name").GetString()?.TrimStart('v');
            if (Version.TryParse(tag, out var remote) && remote > new Version("0.1.0")
                && System.Windows.MessageBox.Show($"Hay una actualización {remote}. ¿Abrir la descarga?", "LockCode", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
                Process.Start(new ProcessStartInfo("https://github.com/D1abloo/LockAPP/releases") { UseShellExecute = true });
            else if (interactive) System.Windows.MessageBox.Show("No hay una actualización posterior publicada.", "LockCode");
        }
        catch { if (interactive) System.Windows.MessageBox.Show("No se pudo comprobar la actualización.", "LockCode"); }
    }
}
