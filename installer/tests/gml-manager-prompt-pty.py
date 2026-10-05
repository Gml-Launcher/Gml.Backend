#!/usr/bin/env python3
"""Exercise actual prompt reads with a script pipe and separate sudo/user PTYs."""

import errno
import os
from pathlib import Path
import pty
import select
import shlex
import signal
import sys
import termios
import time
import tty


MANAGER = Path(__file__).resolve().parents[1] / "gml-manager.sh"


def check_prompts(separate_sudo_tty, cancel=False, raw_tty=False, background_tty=False, real_sudo=False):
    user_master, user_slave = pty.openpty()
    tty.setraw(user_slave)
    original_settings = termios.tcgetattr(user_slave)
    script_read, script_write = os.pipe()
    pid, command_master = pty.fork()
    if pid == 0:
        if background_tty:
            command_pid = os.fork()
            if command_pid:
                os.close(script_read)
                os.close(script_write)
                def terminate_monitor(signum, frame):
                    os.kill(command_pid, signal.SIGKILL)
                    os.waitpid(command_pid, 0)
                    os._exit(1)

                signal.signal(signal.SIGTERM, terminate_monitor)
                while True:
                    _, status = os.waitpid(command_pid, os.WUNTRACED)
                    if os.WIFSTOPPED(status):
                        # Model sudo-rs promoting the command after its first
                        # read from /dev/tty receives SIGTTIN.
                        os.tcsetpgrp(1, command_pid)
                        os.kill(command_pid, signal.SIGCONT)
                    else:
                        os._exit(os.waitstatus_to_exitcode(status))
            os.setpgid(0, 0)
        os.dup2(script_read, 0)
        os.close(script_write)
        if separate_sudo_tty:
            os.environ["SUDO_TTY"] = os.ttyname(user_slave)
        else:
            os.environ.pop("SUDO_TTY", None)
        os.environ.pop("SUDO_USER", None)
        if real_sudo:
            os.execvp("sudo", ["sudo", "-n", "sh", "-s"])
        os.execvp("sh", ["sh", "-s"])

    if raw_tty:
        tty.setraw(command_master)
    command_settings = termios.tcgetattr(command_master)
    os.close(script_read)
    script = f"""GML_MANAGER_SKIP_MAIN=1
. {shlex.quote(str(MANAGER))}
GML_MANAGER_LANGUAGE=en
INTERACTIVE_MODE=1
prompt_language
resolve_action_and_base_dir
resolve_proxy_inputs
fetch_latest_stable_version() {{ printf '%s\\n' v2025.3.3.2; }}
resolve_version_input
confirm_compose_overwrite || exit 1
printf 'RESULT:%s:%s:%s:%s:%s\\n' "$GML_MANAGER_LANGUAGE" "$ACTION" "$BASE_DIR" "$PROXY_MODE" "$VERSION"
"""
    os.write(script_write, script.encode())
    os.close(script_write)
    output = bytearray()
    consumed = 0
    reaped = False

    def wait_for_exit():
        nonlocal reaped
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            finished, status = os.waitpid(pid, os.WNOHANG)
            if finished:
                reaped = True
                return os.waitstatus_to_exitcode(status)
            time.sleep(0.01)
        raise AssertionError("Prompt shell did not exit")

    def wait_for(text):
        nonlocal consumed
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            index = output.find(text.encode(), consumed)
            if index >= 0:
                consumed = index + len(text.encode())
                return
            if select.select([command_master], [], [], 0.05)[0]:
                try:
                    data = os.read(command_master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    break
                if not data:
                    break
                output.extend(data)
        raise AssertionError(f"Prompt/result {text!r} not reached: {output.decode(errors='replace')}")

    def answer(prompt, value):
        wait_for(prompt)
        if separate_sudo_tty:
            # The prompt is printed just before its input terminal is configured.
            deadline = time.monotonic() + 5
            while not termios.tcgetattr(user_slave)[3] & termios.ICANON:
                if time.monotonic() >= deadline:
                    raise AssertionError("Original sudo terminal was not prepared for line input")
                time.sleep(0.01)
            os.write(user_master, value.encode() + (b"" if value == "\x04" else b"\r"))
        elif real_sudo:
            # sudo owns and may switch the user-facing PTY to raw mode. Feed
            # complete lines through it; CR handling is covered above separately.
            os.write(command_master, value.encode() + b"\n")
        else:
            deadline = time.monotonic() + 5
            while not termios.tcgetattr(command_master)[3] & termios.ICANON:
                if time.monotonic() >= deadline:
                    raise AssertionError("Command terminal was not prepared for line input")
                time.sleep(0.01)
            os.write(command_master, value.encode() + (b"" if value == "\x04" else b"\r"))

    try:
        if cancel:
            answer("Language [en]:", "\x04")
            wait_for("Unable to read an answer from terminal")
            assert wait_for_exit() == 1
            assert termios.tcgetattr(user_slave) == original_settings
            assert termios.tcgetattr(command_master) == command_settings
            return
        answer("Language [en]:", "1")
        answer("Действие [1]:", "2")
        answer("Каталог установки [/srv/gml]:", "/tmp/gml-prompt-test")
        answer("Режим прокси [external]:", "1")
        answer("Версия Gml [v2025.3.3.2]:", "")
        answer("[y/N]:", "да")
        wait_for("RESULT:ru:update:/tmp/gml-prompt-test:external:v2025.3.3.2")
        assert wait_for_exit() == 0
        assert termios.tcgetattr(user_slave) == original_settings, "Original terminal settings were not restored"
        assert termios.tcgetattr(command_master) == command_settings, "Command terminal settings were not restored"
    finally:
        if not reaped:
            os.kill(pid, signal.SIGTERM if background_tty or real_sudo else signal.SIGKILL)
            os.waitpid(pid, 0)
        for descriptor in (user_master, user_slave, command_master):
            os.close(descriptor)


if __name__ == "__main__":
    check_prompts(separate_sudo_tty=True)
    check_prompts(separate_sudo_tty=False)
    check_prompts(separate_sudo_tty=True, cancel=True)
    check_prompts(separate_sudo_tty=False, raw_tty=True)
    check_prompts(separate_sudo_tty=False, raw_tty=True, background_tty=True)
    check_prompts(separate_sudo_tty=False, raw_tty=True, background_tty=True, cancel=True)
    print("Prompt PTY tests passed (sudo terminal, raw terminal, background job control, EOF)")
    if "--real-sudo" in sys.argv[1:]:
        check_prompts(separate_sudo_tty=False, real_sudo=True)
        print("Prompt integration test passed through system sudo")
