#!/usr/bin/env python3
"""Verify live Compose output without invoking Docker or changing an installation."""

import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import signal
import struct
import subprocess
import tempfile
import termios
import time

MANAGER = Path(__file__).resolve().parents[1] / 'gml-manager.sh'


def script(result=0, wrapper='run_compose_step'):
    return f'''GML_MANAGER_SKIP_MAIN=1
. {shlex.quote(str(MANAGER))}
mock_compose() {{
    printf '\\033[31mpull-first\\033[0m\\n'
    sleep 0.6
    printf 'stderr-second\\n' >&2
    printf '\\033]0;hidden-title\\007progress-old\\rprogress-new\\n'
    printf '%s\\n' 'Прогресс загрузки образа {'я' * 120}'
    sleep 0.6
    printf 'finished-last\\n'
    return {result}
}}
{wrapper} 'Docker output test' mock_compose
printf 'WORKFLOW-CONTINUED\\n'
'''


def resize(fd, rows, columns):
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', rows, columns, 0, 0))


def check_pty(tmpdir, result=0, size=(24, 80), term='xterm', change_size=False, cancel=False):
    pid, master = pty.fork()
    if pid == 0:
        os.environ.update(TERM=term, TMPDIR=tmpdir)
        os.execvp('sh', ['sh', '-c', script(result)])
    resize(master, *size)
    output = bytearray()
    deadline = time.monotonic() + 8
    early = False
    resized = False
    interrupted = False
    try:
        while time.monotonic() < deadline:
            readable, _, _ = select.select([master], [], [], 0.1)
            if readable:
                try:
                    chunk = os.read(master, 65536)
                except OSError as error:
                    if error.errno != errno.EIO:
                        raise
                    break
                if not chunk:
                    break
                output.extend(chunk)
            if b'pull-first' in output and b'finished-last' not in output:
                early = True
                if change_size and not resized:
                    resize(master, 12, 48)
                    resized = True
                if cancel and not interrupted:
                    # Model Ctrl-C from the terminal, including foreground children.
                    os.killpg(pid, signal.SIGINT)
                    interrupted = True
        else:
            raise AssertionError('live output test timed out')
        _, status = os.waitpid(pid, 0)
    finally:
        try:
            os.killpg(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        os.close(master)
    decoded = output.decode('utf-8')
    assert early, decoded
    framed = size[0] >= 7 and size[1] >= 30 and term != 'dumb'
    if framed:
        assert '\x1b[?25l' in decoded and '\x1b[?25h' in decoded, decoded
        assert '+---' in decoded and '| ' in decoded, decoded
        widths = {size[1], 48} if change_size else {size[1]}
        for line in decoded.splitlines():
            if line.startswith(('| ', '+---')):
                assert len(line) in widths, repr(line)
    else:
        assert '\x1b' not in decoded, decoded
    assert 'hidden-title' not in decoded and '\x1b[31m' not in decoded, decoded
    if cancel:
        assert 'WORKFLOW-CONTINUED' not in decoded
        assert os.waitstatus_to_exitcode(status) != 0
    else:
        assert 'stderr-second' in decoded and 'finished-last' in decoded, decoded
        assert os.waitstatus_to_exitcode(status) == result, decoded
        assert ('WORKFLOW-CONTINUED' in decoded) == (result == 0), decoded
        assert ('✗' if result else '✓') in decoded, decoded
    assert not list(Path(tmpdir).glob('gml-manager.*'))


def check_pipe(tmpdir, result=0, wrapper='run_compose_step'):
    env = dict(os.environ, TMPDIR=tmpdir, TERM='xterm')
    process = subprocess.Popen(['sh', '-c', script(result, wrapper)],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env)
    first = process.stdout.readline()
    if wrapper == 'run_compose_step':
        assert b'Docker output test' in first
        second = process.stdout.readline()
        assert b'pull-first' in second and process.poll() is None, second
    else:
        second = b''
    remainder, _ = process.communicate(timeout=8)
    output = first + second + remainder
    if wrapper == 'run_compose_step':
        assert b'\x1b' not in output, output
        assert b'stderr-second' in output and b'finished-last' in output
    else:
        assert b'pull-first' not in output and b'finished-last' not in output
    assert process.returncode == result, output
    assert (b'WORKFLOW-CONTINUED' in output) == (result == 0), output
    assert not list(Path(tmpdir).glob('gml-manager.*'))


with tempfile.TemporaryDirectory(prefix='gml-output-tests-') as tmpdir:
    check_pipe(tmpdir)
    check_pipe(tmpdir, result=7)
    check_pipe(tmpdir, wrapper='run_step')
    check_pty(tmpdir)
    check_pty(tmpdir, result=7)
    check_pty(tmpdir, change_size=True)
    check_pty(tmpdir, size=(5, 20))
    check_pty(tmpdir, term='dumb')
    check_pty(tmpdir, cancel=True)
print('Compose output tests passed (live output, errors, UTF-8, resize, fallback, Ctrl-C)')
