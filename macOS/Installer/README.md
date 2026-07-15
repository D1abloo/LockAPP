# Instalador macOS

Versión publicada: **0.4.6**. El uso es gratuito y no requiere donación; consulta la [Política de uso](../../USAGE_POLICY.md).

Genera un ZIP universal para Intel y Apple Silicon en `macOS/Installer/output`:

```bash
chmod +x macOS/Installer/build.sh
./macOS/Installer/build.sh
```

Usa `SIGN_IDENTITY="Developer ID Application: …"` para distribución. Sin esa variable emplea la identidad local estable disponible o firma ad hoc. Para una publicación pública, notariza el paquete con Apple.

Instalación manual: descomprime `LockCode-macOS-0.4.6.zip`, mueve `LockCode.app` a `/Applications` y ábrela. Las actualizaciones posteriores pueden descargarse, verificarse e instalarse desde **Actualizaciones** cuando la copia instalada sea escribible por el usuario.
