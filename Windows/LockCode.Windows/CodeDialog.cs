using System.Windows;
using System.Windows.Controls;
using LockCode.Windows.Services;
using System.Windows.Media.Imaging;

namespace LockCode.Windows;

public sealed class CodeDialog : Window
{
    private readonly PasswordBox _code = new();
    private readonly PasswordBox? _confirmation;
    private readonly TextBlock _error = new() { Foreground = System.Windows.Media.Brushes.Firebrick };
    public string Code { get; private set; } = "";

    public CodeDialog(string title, bool confirm)
    {
        Title = title; Width = 390; Height = confirm ? 260 : 220; WindowStartupLocation = WindowStartupLocation.CenterOwner;
        Topmost = true; ResizeMode = ResizeMode.NoResize;
        Icon = BitmapFrame.Create(new Uri("pack://application:,,,/Assets/LockCode.png"));
        _confirmation = confirm ? new PasswordBox() : null;
        var panel = new StackPanel { Margin = new Thickness(22) };
        panel.Children.Add(new TextBlock { Text = "Código (4–64 caracteres, admite letras y símbolos):", TextWrapping = TextWrapping.Wrap });
        panel.Children.Add(_code); _code.Margin = new Thickness(0, 8, 0, 8);
        if (_confirmation is not null) { panel.Children.Add(new TextBlock { Text = "Confirmar código:" }); panel.Children.Add(_confirmation); }
        panel.Children.Add(_error);
        var button = new System.Windows.Controls.Button { Content = "Continuar", Margin = new Thickness(0, 14, 0, 0), Padding = new Thickness(12, 5, 12, 5), IsDefault = true };
        button.Click += (_, _) => Submit(); panel.Children.Add(button); Content = panel;
        Loaded += (_, _) => _code.Focus();
    }

    private void Submit()
    {
        var candidate = _code.Password;
        if (!CodePolicy.IsValid(candidate)) { _error.Text = "Usa entre 4 y 64 caracteres imprimibles."; Clear(); return; }
        if (_confirmation is not null && candidate != _confirmation.Password) { _error.Text = "Los códigos no coinciden."; Clear(); return; }
        Code = candidate; Clear(); DialogResult = true;
    }
    private void Clear() { _code.Clear(); _confirmation?.Clear(); }
}
