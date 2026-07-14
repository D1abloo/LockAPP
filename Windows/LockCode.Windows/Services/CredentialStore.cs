using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace LockCode.Windows.Services;

public sealed class CredentialStore
{
    private const string Target = "LockCode.Windows.PrimaryCode";

    public bool HasCode => ReadSecret() is not null;

    public void SetCode(string code)
    {
        CodePolicy.ThrowIfInvalid(code);
        WriteSecret(JsonSerializer.Serialize(CredentialHasher.Create(code)));
    }

    public bool Verify(string code)
    {
        var value = ReadSecret();
        if (value is null || !CodePolicy.IsValid(code)) return false;
        try
        {
            return CredentialHasher.Verify(code, JsonSerializer.Deserialize<DerivedCredential>(value)!);
        }
        catch { return false; }
    }

    private static void WriteSecret(string value)
    {
        var bytes = Encoding.Unicode.GetBytes(value);
        var pointer = Marshal.AllocCoTaskMem(bytes.Length);
        try
        {
            Marshal.Copy(bytes, 0, pointer, bytes.Length);
            var credential = new NativeCredential
            {
                Type = 1, TargetName = Target, CredentialBlobSize = (uint)bytes.Length,
                CredentialBlob = pointer, Persist = 2, UserName = Environment.UserName
            };
            if (!CredWrite(ref credential, 0)) throw new InvalidOperationException("Credential Manager rechazó la credencial.");
        }
        finally { CryptographicOperations.ZeroMemory(bytes); Marshal.FreeCoTaskMem(pointer); }
    }

    private static string? ReadSecret()
    {
        if (!CredRead(Target, 1, 0, out var pointer)) return null;
        try
        {
            var credential = Marshal.PtrToStructure<NativeCredential>(pointer);
            return Marshal.PtrToStringUni(credential.CredentialBlob, (int)credential.CredentialBlobSize / 2);
        }
        finally { CredFree(pointer); }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NativeCredential
    {
        public uint Flags, Type;
        public string TargetName;
        public string? Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist, AttributeCount;
        public IntPtr Attributes;
        public string? TargetAlias;
        public string UserName;
    }

    [DllImport("advapi32", EntryPoint = "CredWriteW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredWrite(ref NativeCredential credential, uint flags);
    [DllImport("advapi32", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string target, uint type, uint flags, out IntPtr credential);
    [DllImport("advapi32")] private static extern void CredFree(IntPtr credential);
}

public sealed record DerivedCredential(string Salt, string Hash, int Rounds);

public static class CredentialHasher
{
    private const int Iterations = 210_000;
    public static DerivedCredential Create(string code)
    {
        CodePolicy.ThrowIfInvalid(code);
        var salt = RandomNumberGenerator.GetBytes(32);
        var hash = Rfc2898DeriveBytes.Pbkdf2(code, salt, Iterations, HashAlgorithmName.SHA256, 32);
        return new(Convert.ToBase64String(salt), Convert.ToBase64String(hash), Iterations);
    }
    public static bool Verify(string code, DerivedCredential stored)
    {
        if (!CodePolicy.IsValid(code)) return false;
        var actual = Rfc2898DeriveBytes.Pbkdf2(code, Convert.FromBase64String(stored.Salt),
            stored.Rounds, HashAlgorithmName.SHA256, 32);
        return CryptographicOperations.FixedTimeEquals(actual, Convert.FromBase64String(stored.Hash));
    }
}

public static class CodePolicy
{
    public static bool IsValid(string value) => value.Length is >= 4 and <= 64
        && value.All(c => !char.IsControl(c));
    public static void ThrowIfInvalid(string value)
    {
        if (!IsValid(value)) throw new ArgumentException("El código debe tener entre 4 y 64 caracteres imprimibles.");
    }
}
