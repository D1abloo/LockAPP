using System.Security.Cryptography;
using System.Text.Json;
using System.Diagnostics;
using System.IO;
using System.Net.Http;

namespace LockCode.Windows.Services;

public sealed record UpdateRelease(Version Version, string Name, Uri DownloadUrl, string Sha256, long Size);

public static class UpdateService
{
    public static ProcessStartInfo InstallerStartInfo(string installer)
    {
        var path = Path.GetFullPath(installer);
        if (!Path.GetExtension(path).Equals(".exe", StringComparison.OrdinalIgnoreCase))
            throw new InvalidDataException("El instalador de Windows no es un ejecutable válido.");
        var startInfo = new ProcessStartInfo(path)
        {
            UseShellExecute = false,
            WorkingDirectory = Path.GetDirectoryName(path)!,
            CreateNoWindow = true
        };
        startInfo.ArgumentList.Add("/S");
        return startInfo;
    }

    public static UpdateRelease? Parse(string json, Version currentVersion)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        var tag = root.GetProperty("tag_name").GetString()?.TrimStart('v');
        if (!Version.TryParse(tag, out var version) || version <= currentVersion) return null;

        foreach (var asset in root.GetProperty("assets").EnumerateArray())
        {
            var name = asset.GetProperty("name").GetString() ?? "";
            var url = asset.GetProperty("browser_download_url").GetString();
            var digest = asset.TryGetProperty("digest", out var digestValue)
                ? digestValue.GetString() : null;
            if (!name.Contains("Windows", StringComparison.OrdinalIgnoreCase)
                || !name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)
                || !Uri.TryCreate(url, UriKind.Absolute, out var uri)
                || !IsTrusted(uri)
                || digest is null
                || !digest.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase)
                || digest.Length != 71) continue;
            var hash = digest[7..].ToLowerInvariant();
            if (!hash.All(Uri.IsHexDigit)) continue;
            var size = asset.TryGetProperty("size", out var sizeValue) ? sizeValue.GetInt64() : 0;
            return new UpdateRelease(version, name, uri, hash, size);
        }
        return null;
    }

    public static bool IsTrusted(Uri uri) => uri.Scheme == Uri.UriSchemeHttps
        && uri.Host.Equals("github.com", StringComparison.OrdinalIgnoreCase)
        && uri.AbsolutePath.StartsWith("/D1abloo/LockAPP/releases/download/", StringComparison.Ordinal);

    public static async Task<string> DownloadAsync(
        UpdateRelease release,
        IProgress<double> progress,
        CancellationToken cancellationToken = default)
    {
        var directory = Path.Combine(Path.GetTempPath(), "LockCode", "updates");
        Directory.CreateDirectory(directory);
        var destination = Path.Combine(directory, release.Name);
        using var client = new HttpClient();
        client.DefaultRequestHeaders.UserAgent.ParseAdd("LockCode-Windows-Updater");
        using var response = await client.GetAsync(
            release.DownloadUrl, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();
        var total = response.Content.Headers.ContentLength ?? release.Size;
        await using var input = await response.Content.ReadAsStreamAsync(cancellationToken);
        await using var output = new FileStream(destination, FileMode.Create, FileAccess.Write, FileShare.None);
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        var buffer = new byte[128 * 1024];
        long received = 0;
        int count;
        while ((count = await input.ReadAsync(buffer, cancellationToken)) > 0)
        {
            await output.WriteAsync(buffer.AsMemory(0, count), cancellationToken);
            hash.AppendData(buffer, 0, count);
            received += count;
            if (total > 0) progress.Report(Math.Min((double)received / total, 1));
        }
        await output.FlushAsync(cancellationToken);
        var actual = Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant();
        if (!actual.Equals(release.Sha256, StringComparison.Ordinal))
        {
            File.Delete(destination);
            throw new InvalidDataException("La firma SHA-256 de la actualización no coincide.");
        }
        progress.Report(1);
        return destination;
    }
}
