# Estado de mantenimiento

LockCode tiene ediciones independientes para macOS, Windows y Linux.

| Plataforma | Versión publicada |
| --- | --- |
| macOS | 0.4.6 |
| Windows | 0.4.5 |
| Debian/Ubuntu | 0.4.5 |
| Fedora/CentOS RPM | 0.4.5 |

## Reglas para futuras entregas

1. Mantener el código fuera de archivos, preferencias y logs; solo se guarda una credencial derivada en el almacén seguro del sistema.
2. Mantener la descripción *best effort* y no prometer bloqueo previo a la ejecución.
3. Probar modo inmediato, periodo de gracia, cancelación, reinicio e inicio automático.
4. Ejecutar las pruebas y construir el instalador de cada plataforma modificada.
5. Publicar SHA-256 y actualizar los informes de prueba.
6. Respetar la [Política de uso](USAGE_POLICY.md), la privacidad y la autoría.
