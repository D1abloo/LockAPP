from __future__ import annotations

import argparse
import html
import queue
import subprocess
import threading
import webbrowser
from datetime import datetime

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import GLib, Gtk  # noqa: E402

from . import __version__, biometrics, updates
from .audit import AuditStore
from .catalog import load_apps
from .policy import AttemptLimiter, valid_code
from .protection import AccessRequest, ProtectionService
from .secure_store import SecretStore
from .settings import SettingsStore
from .startup import set_enabled


class LockCodeApplication(Gtk.Application):
    def __init__(self, background: bool = False) -> None:
        super().__init__(application_id="com.lockcode.Linux")
        self.background = background
        self.settings = SettingsStore()
        self.secrets = SecretStore(self.settings.value.credential_id)
        self.audit = AuditStore()
        self.limiter = AttemptLimiter()
        self.protection = ProtectionService(self.settings)
        self.window: Gtk.ApplicationWindow | None = None
        self.auth_active = False
        self.management_unlocked = False
        self.management_pending = False
        self.store = Gtk.ListStore(bool, str, str)

    def do_startup(self) -> None:
        Gtk.Application.do_startup(self)
        self.hold()
        self.protection.start()
        set_enabled(self.settings.value.start_with_linux)
        GLib.timeout_add(100, self._poll_requests)
        self._create_indicator()

    def do_activate(self) -> None:
        if self.window is None:
            self.window = self._build_window()
        if not self.secrets.available():
            self._message("Instala libsecret-tools para guardar el código de forma segura.", Gtk.MessageType.ERROR)
            return
        if not self._has_configured_code() and not self._setup_code():
            return
        self._refresh_apps()
        self._refresh_audit()
        if self.background:
            self.background = False
            threading.Thread(target=self._background_update_check, daemon=True).start()
            return
        if self.management_unlocked:
            self.window.present()
        elif not self.management_pending:
            self.management_pending = True
            threading.Thread(target=self._authenticate_management, daemon=True).start()

    def do_shutdown(self) -> None:
        self.protection.close()
        Gtk.Application.do_shutdown(self)

    def _create_indicator(self) -> None:
        try:
            gi.require_version("AyatanaAppIndicator3", "0.1")
            from gi.repository import AyatanaAppIndicator3
            indicator = AyatanaAppIndicator3.Indicator.new(
                "lockcode", "com.lockcode.Linux",
                AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS,
            )
            menu = Gtk.Menu()
            for label, callback in [
                ("Abrir LockCode", lambda *_: self.activate()),
                ("Bloquear ahora", lambda *_: self.protection.lock_now()),
                ("Salir", self._request_exit),
            ]:
                item = Gtk.MenuItem(label=label); item.connect("activate", callback); menu.append(item)
            menu.show_all(); indicator.set_menu(menu); indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)
            self.indicator = indicator
        except (ValueError, ImportError):
            self.indicator = None

    def _build_window(self) -> Gtk.ApplicationWindow:
        window = Gtk.ApplicationWindow(application=self, title="LockCode para Linux")
        window.set_default_size(900, 620)
        window.connect("delete-event", self._hide_window)
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin=16)
        title = Gtk.Label(); title.set_markup('<span foreground="#c62828" size="xx-large">🔒</span>  <span size="xx-large"><b>LockCode</b></span>')
        title.set_xalign(0); outer.pack_start(title, False, False, 0)
        notebook = Gtk.Notebook(); outer.pack_start(notebook, True, True, 0)

        apps_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, margin=10)
        refresh = Gtk.Button(label="Actualizar lista"); refresh.connect("clicked", lambda *_: self._refresh_apps()); apps_box.pack_start(refresh, False, False, 0)
        tree = Gtk.TreeView(model=self.store); toggle = Gtk.CellRendererToggle(); toggle.connect("toggled", self._toggle_app)
        tree.append_column(Gtk.TreeViewColumn("Proteger", toggle, active=0)); tree.append_column(Gtk.TreeViewColumn("Aplicación", Gtk.CellRendererText(), text=1))
        scroll = Gtk.ScrolledWindow(); scroll.add(tree); apps_box.pack_start(scroll, True, True, 0)
        notebook.append_page(apps_box, Gtk.Label(label="Aplicaciones"))

        settings_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin=18)
        self.protection_check = Gtk.CheckButton(label="Protección activada"); self.protection_check.set_active(self.settings.value.protection_enabled)
        self.bio_check = Gtk.CheckButton(label="Usar huella automáticamente"); self.bio_check.set_active(self.settings.value.biometrics_enabled)
        self.start_check = Gtk.CheckButton(label="Iniciar LockCode con Linux"); self.start_check.set_active(self.settings.value.start_with_linux)
        self.minutes = Gtk.SpinButton.new_with_range(0, 1440, 1); self.minutes.set_value(self.settings.value.grace_minutes)
        for widget in (self.protection_check, self.bio_check, self.start_check): widget.connect("toggled", self._save_settings); settings_box.pack_start(widget, False, False, 0)
        settings_box.pack_start(Gtk.Label(label="Minutos de desbloqueo (0 = hasta cerrar la aplicación)", xalign=0), False, False, 0)
        self.minutes.connect("value-changed", self._save_settings); settings_box.pack_start(self.minutes, False, False, 0)
        lock_now = Gtk.Button(label="Bloquear ahora"); lock_now.connect("clicked", lambda *_: self.protection.lock_now()); settings_box.pack_start(lock_now, False, False, 0)
        change = Gtk.Button(label="Cambiar código"); change.connect("clicked", self._change_code); settings_box.pack_start(change, False, False, 0)
        notebook.append_page(settings_box, Gtk.Label(label="Ajustes"))

        audit_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6, margin=10)
        self.audit_list = Gtk.ListBox(); audit_scroll = Gtk.ScrolledWindow(); audit_scroll.add(self.audit_list); audit_box.pack_start(audit_scroll, True, True, 0)
        clear = Gtk.Button(label="Borrar registro"); clear.connect("clicked", self._clear_audit); audit_box.pack_start(clear, False, False, 0)
        notebook.append_page(audit_box, Gtk.Label(label="Registro"))

        update_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin=18)
        check = Gtk.Button(label="Buscar actualización"); check.connect("clicked", self._check_update); update_box.pack_start(check, False, False, 0)
        notebook.append_page(update_box, Gtk.Label(label="Actualizaciones"))

        help_label = Gtk.Label(xalign=0, yalign=0, margin=18); help_label.set_line_wrap(True)
        help_label.set_markup("<b>Ayuda y soporte</b>\n\nCrea un código, selecciona aplicaciones y deja LockCode activo. Al cerrar la ventana, sigue funcionando desde su icono en la bandeja. La huella se solicita automáticamente si fprintd está disponible. El registro nunca contiene códigos ni nombres de aplicaciones.\n\nLockCode es gratuito y no requiere donación. Si quieres donar, puedes hacerlo ;)\n\nSoporte: kin_coriano14@hotmail.com\nSoftware realizado por Isaac Silva Jiménez.\n\nEs una protección de privacidad <i>best effort</i>, no un bloqueo infalible de procesos.")
        help_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL); help_box.pack_start(help_label, True, True, 0)
        donate = Gtk.Button(label="Donación voluntaria con PayPal"); donate.connect("clicked", lambda *_: webbrowser.open("https://www.paypal.com/paypalme/kin_coriano14")); help_box.pack_start(donate, False, False, 12)
        notebook.append_page(help_box, Gtk.Label(label="Ayuda y soporte"))
        window.add(outer); outer.show_all(); return window

    def _setup_code(self) -> bool:
        first = self._code_dialog("Crear código", "Código (4–64 caracteres, admite símbolos)")
        if first is None: return False
        second = self._code_dialog("Confirmar código", "Repite el código")
        if first != second: self._message("Los códigos no coinciden.", Gtk.MessageType.ERROR); return False
        return self._store_code(first)

    def _has_configured_code(self) -> bool:
        if self.settings.value.credential_configured:
            return True
        if not self.secrets.has_code():
            return False
        self.settings.value.credential_configured = True
        self.settings.save()
        return True

    def _store_code(self, code: str) -> bool:
        result: list[str | None] = [None]
        dialog = Gtk.MessageDialog(
            transient_for=self.window, modal=True, message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.NONE,
            text="Guardando el código de forma segura…",
        )
        dialog.format_secondary_text(
            "Si Ubuntu lo solicita, desbloquea el llavero GNOME. LockCode seguirá respondiendo."
        )

        def store() -> None:
            try:
                self.secrets.set_code(code)
            except RuntimeError as error:
                result[0] = str(error)
            GLib.idle_add(dialog.response, Gtk.ResponseType.OK)

        threading.Thread(target=store, daemon=True).start()
        dialog.run(); dialog.destroy()
        if result[0] is not None:
            self._message(result[0], Gtk.MessageType.ERROR)
            return False
        self.settings.value.credential_configured = True
        self.settings.save()
        return True

    def _code_dialog(self, title: str, prompt: str) -> str | None:
        dialog = Gtk.Dialog(title=title, transient_for=self.window, modal=True)
        dialog.add_buttons("Cancelar", Gtk.ResponseType.CANCEL, "Continuar", Gtk.ResponseType.OK)
        entry = Gtk.Entry(); entry.set_visibility(False); entry.set_activates_default(True)
        box = dialog.get_content_area(); box.set_spacing(8); box.set_margin_top(14); box.set_margin_bottom(14); box.set_margin_start(14); box.set_margin_end(14)
        box.add(Gtk.Label(label=prompt, xalign=0)); box.add(entry); dialog.set_default_response(Gtk.ResponseType.OK); dialog.show_all(); entry.grab_focus()
        response = dialog.run(); value = entry.get_text(); entry.set_text(""); dialog.destroy()
        return value if response == Gtk.ResponseType.OK and valid_code(value) else None

    def _poll_requests(self) -> bool:
        if self.auth_active: return True
        try: request = self.protection.requests.get_nowait()
        except queue.Empty: return True
        self.auth_active = True
        threading.Thread(target=self._biometric_then_prompt, args=(request,), daemon=True).start()
        return True

    def _biometric_then_prompt(self, request: AccessRequest) -> None:
        approved = self.settings.value.biometrics_enabled and biometrics.authenticate()
        GLib.idle_add(self._finish_authentication, request, approved)

    def _authenticate_management(self) -> None:
        approved = self.settings.value.biometrics_enabled and biometrics.authenticate()
        GLib.idle_add(self._finish_management_authentication, approved)

    def _finish_management_authentication(self, approved: bool) -> bool:
        if not approved:
            code = self._code_dialog("Acceder a LockCode", "Introduce el código")
            approved = code is not None and self.secrets.verify(code)
        self.management_pending = False
        self.management_unlocked = approved
        if approved and self.window is not None: self.window.present()
        elif not approved: self.audit.record("Intento fallido")
        return False

    def _finish_authentication(self, request: AccessRequest, approved: bool) -> bool:
        if not approved and self.limiter.can_attempt():
            code = self._code_dialog("Aplicación protegida", "Introduce el código")
            approved = code is not None and self.secrets.verify(code)
        if approved:
            self.limiter.succeeded(); self.audit.record("Desbloqueo correcto"); self.protection.approve(request)
        else:
            self.limiter.failed(); self.audit.record("Intento fallido o cancelado"); self.protection.deny(request)
        self.auth_active = False; self._refresh_audit(); return False

    def _toggle_app(self, _cell: Gtk.CellRendererToggle, path: str) -> None:
        row = self.store[path]; row[0] = not row[0]; executable = row[2]
        values = self.settings.value.protected_executables
        if row[0] and executable not in values: values.append(executable)
        elif not row[0] and executable in values: values.remove(executable)
        self.settings.save()

    def _refresh_apps(self) -> None:
        self.store.clear(); protected = set(self.settings.value.protected_executables)
        for app in load_apps(): self.store.append([app.executable in protected, app.name, app.executable])

    def _save_settings(self, *_args) -> None:
        self.settings.value.protection_enabled = self.protection_check.get_active()
        self.settings.value.biometrics_enabled = self.bio_check.get_active()
        self.settings.value.start_with_linux = self.start_check.get_active()
        self.settings.value.grace_minutes = self.minutes.get_value_as_int()
        self.settings.save(); set_enabled(self.settings.value.start_with_linux)

    def _change_code(self, *_args) -> None:
        current = self._code_dialog("Código actual", "Introduce el código actual")
        if current is None or not self.secrets.verify(current): self.audit.record("Intento fallido"); return
        self._setup_code()

    def _refresh_audit(self) -> None:
        if not hasattr(self, "audit_list"): return
        for child in self.audit_list.get_children(): self.audit_list.remove(child)
        for event in reversed(self.audit.read()):
            try: shown = datetime.fromisoformat(event["at"]).astimezone().strftime("%d/%m/%Y %H:%M:%S")
            except ValueError: shown = event.get("at", "")
            self.audit_list.add(Gtk.Label(label=f"{shown} — {event.get('kind', '')}", xalign=0))
        self.audit_list.show_all()

    def _clear_audit(self, *_args) -> None: self.audit.clear(); self._refresh_audit()
    def _check_update(self, *_args) -> None:
        remote = updates.latest_version()
        if remote and remote != __version__:
            dialog = Gtk.MessageDialog(
                transient_for=self.window, modal=True, message_type=Gtk.MessageType.QUESTION,
                buttons=Gtk.ButtonsType.YES_NO,
                text=f"Hay una actualización {html.escape(remote)}. ¿Abrir la descarga?",
            )
            response = dialog.run(); dialog.destroy()
            if response == Gtk.ResponseType.YES:
                webbrowser.open("https://github.com/D1abloo/LockAPP/releases")
        else:
            self._message("No hay una actualización posterior publicada o no se pudo consultar.")
    def _request_exit(self, *_args) -> None:
        approved = self.settings.value.biometrics_enabled and biometrics.authenticate()
        if not approved:
            code = self._code_dialog("Salir", "Autentícate para salir")
            approved = code is not None and self.secrets.verify(code)
        if approved: self.quit()
    def _hide_window(self, widget: Gtk.Widget, _event) -> bool:
        self.management_unlocked = False; widget.hide(); return True
    def _background_update_check(self) -> None:
        remote = updates.latest_version()
        if remote and remote != __version__: GLib.idle_add(self._offer_update, remote)
    def _offer_update(self, remote: str) -> bool:
        dialog = Gtk.MessageDialog(
            transient_for=self.window, modal=True, message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text=f"Hay una actualización {html.escape(remote)}. ¿Quieres actualizar?",
        )
        response = dialog.run(); dialog.destroy()
        if response == Gtk.ResponseType.YES: webbrowser.open("https://github.com/D1abloo/LockAPP/releases")
        return False
    def _message(self, text: str, kind: Gtk.MessageType = Gtk.MessageType.INFO) -> None:
        dialog = Gtk.MessageDialog(transient_for=self.window, modal=True, message_type=kind, buttons=Gtk.ButtonsType.OK, text=text)
        dialog.run(); dialog.destroy()


def main() -> int:
    parser = argparse.ArgumentParser(); parser.add_argument("--background", action="store_true")
    args = parser.parse_args(); return LockCodeApplication(args.background).run([])
