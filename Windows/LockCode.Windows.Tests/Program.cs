using LockCode.Windows.Services;
using LockCode.Windows.Models;
using System.Text.Json;

var checks = new (string Name, bool Passed)[]
{
    ("mínimo", CodePolicy.IsValid("a!2?")),
    ("símbolos", CodePolicy.IsValid("Frase segura !@#$%^&*()[]{}")),
    ("demasiado corto", !CodePolicy.IsValid("abc")),
    ("control rechazado", !CodePolicy.IsValid("abcd\n")),
    ("máximo", CodePolicy.IsValid(new string('x', 64))),
    ("exceso", !CodePolicy.IsValid(new string('x', 65)))
};
foreach (var check in checks) Console.WriteLine($"{(check.Passed ? "PASS" : "FAIL")} {check.Name}");
var limiter = new AttemptLimiter();
var credential = CredentialHasher.Create("Clave !segura#");
var credentialPassed = CredentialHasher.Verify("Clave !segura#", credential)
    && !CredentialHasher.Verify("Clave incorrecta", credential);
Console.WriteLine($"{(credentialPassed ? "PASS" : "FAIL")} credencial derivada");
var now = DateTimeOffset.UnixEpoch;
var penalties = new[] { limiter.Failed(now), limiter.Failed(now), limiter.Failed(now) };
var limiterPassed = penalties[0] == TimeSpan.Zero && penalties[2] == TimeSpan.FromSeconds(1)
    && !limiter.CanAttempt(now.AddMilliseconds(500));
Console.WriteLine($"{(limiterPassed ? "PASS" : "FAIL")} penalización progresiva");
var grants = new AccessGrantState();
grants.Approve("app.exe", 10, 5, now);
var gracePassed = grants.IsGranted("app.exe", 11, now.AddMinutes(4), _ => false)
    && !grants.IsGranted("app.exe", 11, now.AddMinutes(6), _ => false);
grants.Approve("close.exe", 20, 0, now);
var closePassed = grants.IsGranted("close.exe", 20, now, _ => true)
    && grants.IsGranted("close.exe", 21, now, pid => pid == 20)
    && !grants.IsGranted("close.exe", 22, now, _ => false);
grants.Approve("reset.exe", 30, 5, now);
grants.InvalidateAll();
var resetPassed = !grants.IsGranted("reset.exe", 30, now, _ => true);
Console.WriteLine($"{(gracePassed ? "PASS" : "FAIL")} periodo de gracia");
Console.WriteLine($"{(closePassed ? "PASS" : "FAIL")} bloqueo al cerrar");
Console.WriteLine($"{(resetPassed ? "PASS" : "FAIL")} cambio de política invalida permisos");
var pending = new PendingRequestState();
var cyclePassed = pending.Begin("multi.exe", 30) && !pending.Begin("multi.exe", 31)
    && pending.Members("multi.exe").Order().SequenceEqual([30, 31]);
pending.Complete("multi.exe"); cyclePassed = cyclePassed && pending.Begin("multi.exe", 32);
Console.WriteLine($"{(cyclePassed ? "PASS" : "FAIL")} una solicitud por aplicación multiproceso");
var hiddenWindows = new HiddenWindowState();
hiddenWindows.Remember(30, [101, 102]); hiddenWindows.Remember(31, [201]);
var windowsPassed = hiddenWindows.Take([30]).Order().SequenceEqual([101, 102])
    && hiddenWindows.Drain().SequenceEqual([201]);
Console.WriteLine($"{(windowsPassed ? "PASS" : "FAIL")} restaura solo ventanas visibles recordadas");
var manual = new AppSettings { ManualExecutables = new(StringComparer.OrdinalIgnoreCase) { @"C:\Apps\Private.exe" } };
var restored = JsonSerializer.Deserialize<AppSettings>(JsonSerializer.Serialize(manual));
var manualPassed = restored?.ManualExecutables.Contains(@"C:\Apps\Private.exe") == true;
Console.WriteLine($"{(manualPassed ? "PASS" : "FAIL")} aplicación manual persistente");
var packageDirectory = Path.Combine(Path.GetTempPath(), $"lockcode-package-{Guid.NewGuid():N}");
Directory.CreateDirectory(packageDirectory);
var packageExecutable = Path.Combine(packageDirectory, "Calculator.exe");
File.WriteAllBytes(packageExecutable, []);
File.WriteAllText(Path.Combine(packageDirectory, "AppxManifest.xml"), """
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10">
  <Applications><Application Id="App" Executable="Calculator.exe" DisplayName="Calculadora" /></Applications>
</Package>
""");
var packageEntries = PackageManifestCatalog.Load(packageDirectory, "Paquete de Windows");
var packagePassed = packageEntries.Count == 1 && packageEntries[0].Name == "Calculadora"
    && packageEntries[0].ExecutablePath == packageExecutable;
Directory.Delete(packageDirectory, true);
Console.WriteLine($"{(packagePassed ? "PASS" : "FAIL")} aplicaciones integradas de Windows");
var browserDirectory = Path.Combine(Path.GetTempPath(), $"lockcode-browser-{Guid.NewGuid():N}", "Application");
var browserVersionDirectory = Path.Combine(browserDirectory, "150.0.4078.65");
Directory.CreateDirectory(browserVersionDirectory);
var browserLauncher = Path.Combine(browserDirectory, "msedge.exe");
var browserInternal = Path.Combine(browserVersionDirectory, "msedge.exe");
File.WriteAllBytes(browserLauncher, []); File.WriteAllBytes(browserInternal, []);
var browserPassed = ExecutablePathPolicy.Normalize(browserInternal) == browserLauncher;
Directory.Delete(Directory.GetParent(browserDirectory)!.FullName, true);
Console.WriteLine($"{(browserPassed ? "PASS" : "FAIL")} navegador normalizado a un único lanzador");
var updateJson = """
{"tag_name":"v0.4.7","assets":[{"name":"LockCode-Windows-0.4.7-Setup.exe","browser_download_url":"https://github.com/D1abloo/LockAPP/releases/download/v0.4.7/LockCode-Windows-0.4.7-Setup.exe","digest":"sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","size":123}]}
""";
var release = UpdateService.Parse(updateJson, new Version(0, 4, 0));
var updatePassed = release?.Version == new Version(0, 4, 7)
    && UpdateService.Parse(updateJson.Replace("github.com", "example.com"), new Version(0, 4, 0)) is null;
Console.WriteLine($"{(updatePassed ? "PASS" : "FAIL")} actualización oficial validada");
var installerInfo = UpdateService.InstallerStartInfo(Path.Combine(Path.GetTempPath(), "LockCode-Windows-0.4.7-Setup.exe"));
var installerPassed = !installerInfo.UseShellExecute && installerInfo.ArgumentList.SequenceEqual(["/S"]);
Console.WriteLine($"{(installerPassed ? "PASS" : "FAIL")} instalador ejecutado directamente sin navegador");
return checks.All(x => x.Passed) && credentialPassed && limiterPassed && gracePassed && closePassed && resetPassed
    && cyclePassed && windowsPassed && manualPassed && packagePassed && browserPassed && updatePassed && installerPassed ? 0 : 1;
