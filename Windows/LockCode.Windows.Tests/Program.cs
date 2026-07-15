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
    && !grants.IsGranted("close.exe", 21, now, _ => true)
    && !grants.IsGranted("close.exe", 20, now, _ => false);
Console.WriteLine($"{(gracePassed ? "PASS" : "FAIL")} periodo de gracia");
Console.WriteLine($"{(closePassed ? "PASS" : "FAIL")} bloqueo al cerrar");
var pending = new PendingRequestState();
var cyclePassed = pending.Begin(30) && !pending.Begin(30);
pending.Complete(30); cyclePassed = cyclePassed && pending.Begin(30);
Console.WriteLine($"{(cyclePassed ? "PASS" : "FAIL")} prevención de ciclos");
var manual = new AppSettings { ManualExecutables = new(StringComparer.OrdinalIgnoreCase) { @"C:\Apps\Private.exe" } };
var restored = JsonSerializer.Deserialize<AppSettings>(JsonSerializer.Serialize(manual));
var manualPassed = restored?.ManualExecutables.Contains(@"C:\Apps\Private.exe") == true;
Console.WriteLine($"{(manualPassed ? "PASS" : "FAIL")} aplicación manual persistente");
return checks.All(x => x.Passed) && credentialPassed && limiterPassed && gracePassed && closePassed && cyclePassed && manualPassed ? 0 : 1;
