"""Shared bits of the stand-in CLIs: argv log, paint counter, SIGPIPE like a native binary."""
import json
import os
import signal
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # die of SIGPIPE like the real CLIs, not with a Python traceback


def log(cli, **extra):
    path = os.environ.get("STUB_LOG")
    if path:
        with open(path, "a") as f:
            f.write(json.dumps(dict(cli=cli, argv=sys.argv[1:], **extra)) + "\n")


def painted(cli, path):
    counter = os.environ.get("STUB_PAINTS")
    if counter:
        with open(counter, "a") as f:
            f.write(f"{cli} {path}\n")


def chatty():
    """STUB_CHATTY=1: keep talking after the answer, the way a CLI streams a long listing."""
    if os.environ.get("STUB_CHATTY"):
        sys.stdout.flush()
        for _ in range(4000):
            sys.stdout.write("filler line that keeps the pipe busy after the useful answer\n")
        sys.stdout.flush()


def arg(flag, default=""):
    a = sys.argv
    for i, v in enumerate(a):
        if v == flag and i + 1 < len(a):
            return a[i + 1]
        if v.startswith(flag + "="):
            return v.split("=", 1)[1]
    return default


DIMS = {"1:1": (1024, 1024), "16:9": (1376, 768), "9:16": (768, 1376), "4:3": (1184, 864), "3:4": (864, 1184),
        "3:2": (1248, 832), "2:3": (832, 1248), "2:1": (1280, 640), "1:2": (640, 1280), "auto": (1024, 1024)}
