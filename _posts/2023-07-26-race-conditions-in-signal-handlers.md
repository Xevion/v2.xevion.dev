---
layout: default
title:  Race Conditions in Signal Handlers
date:   2023-07-26 16:08:12 -0500
tags:   tar signals interrupt handler process unix race-condition
_preview_description: Signals offer a unique, low-level way of communicating with processes. But under certain circumstances, they can kill processes, even when they should work.
---

> This article is a deep dive on a classic race condition issue. If you're hoping for an elegant and interesting article
> on how I identified a critical vulnerability in `tar`, I'm sorry to say - there's no such vulnerability.

Signals are a special, but very primitive way for processes to communicate functionality. Signals are useful as they are
a standardized interface available to 99.99% of programs run on UNIX systems (in existence). Interaction can be done
with just the `kill` command.

While the signals API can be quite bare bones and simple, it's technically much less complex compared to a network
interface, usage of STDIN/STDOUT, a file, or even a shared memory segment. These other options might have a lot more
features,
but none of them are perfectly standardized, completely secure, or simple to use.

If you're looking to allow basic communication with your program for very specific use cases and don't need complexity
or I/O, signals can be a great way to go.

## The `tar` command

> This section is a bit of a tangent, but it's a great example of how signals can be used in practice, as well
> as how I came across this issue. Skip to the next section if you just want to hear the error & solution.

The `tar` command is a ubiquitous tool for creating and extracting archives. It's a very simple tool, but it's
extremely powerful. It's also a great example of a program that uses signals.

A couple months ago, I was writing software to help bootstrap embedded devices. The software would use `tar` to extract
a filesystem onto the device's eMMC. Due to the size of the filesystem and the speed of the device, this process could
take some time - I wanted to add a progress bar to confirm that the process was still running & progress was being made.

Unfortunately, `tar` doesn't emit progress information under normal circumstances, and no alternatives were available
in my language of choice that maintained the speed of `tar`. But looking into the documentation, `tar` could receive
specific, designated signals to [emit progress information][checking-tar-progress] for both archival and extraction
operations.

By starting `tar` with the `--totals` flag, it would emit a statistic when the operation completes. But to request
information during the operation, a signal must be chosen, like so `tar -x -f archive.tar --totals=SIGUSR1`.

Emitting a signal can be done with the `kill` command, like so: `kill -USR1 <pid>`. This will send the `USR1` signal
to the process with the given PID. The `USR1` signal is a user-defined signal, and is not used by the system.

And so, my plan was to start a tar process as usual with the `--totals` flag, and then send the `USR1` signal to the
process occasionally to query an extraction operation's progress. In Python, I used the `subprocess` module to start
and manage the process.

```python
import os
import subprocess
import signal
import time
import sys

# Define the command to execute
command = ["tar", "-xpf", sys.argv[2], "-C", sys.argv[1], "--totals=SIGUSR1"]

# Start the subprocess
print(' '.join(command))
process = subprocess.Popen(command, preexec_fn=os.setsid, stderr=subprocess.PIPE)

try:
    while True:
        # Ping the subprocess with SIGUSR1 signal
        # NOTWORK: process.send_signal(signal.SIGUSR1)
        # NOTWORK: os.killpg(os.getpgid(process.pid), signal.SIGUSR1)
        subprocess.Popen(["kill", "-SIGUSR1", str(process.pid)])

        print(process.stderr.readline().decode("utf-8").strip())
        # print(process.stdout.readline().decode("utf-8").strip())

        # Wait for a specified interval
        time.sleep(1.9)  # Adjust the interval as needed

except KeyboardInterrupt:
    # Handle Ctrl+C to gracefully terminate the script
    process.terminate()

# Wait for the subprocess to complete
process.wait()
```

You'll notice I have three different ways to send signals shown, but only one of them is working. Moreover, instead
of the signal not working like expected, the signal actually kills the process. When checked the exit code,
one will find that the status code is the same as the signal number, but negated.

For example, `SIGUSR1` exits with `-10`, `SIGUSR2` exits with `-12`, and `SIGHUP` exits with `-2`. In fact,
when you look into signals, this is the default behavior for processes exited by signals.

## Signal Handlers Aren't Instant

To my surprise, the handlers that programs like `tar` use aren't available instantly - so much so that even Python
can send a signal before they're registered.

I am still not sure as to how signal handlers are implemented - I would've assumed they are static, unchanging, and
registered at program start, but that doesn't seem to be the case - or at least, Python can beat them to the punch.

Whatever the case, the issue with my implementation is that the signal is sent before the handler is registered, and
the default behavior of the signal takes over. For many signals, this is to terminate the process.

## How to wait for Signal Handlers

```TODO```

### Credits

Credit to [Eryk Sun][python-discuss-solution] for explaining the issue and providing an immaculate solution to signal
handlers in Python.

[python-discuss-solution]: https://discuss.python.org/t/os-kill-signals-not-being-received-correctly-alternative-is-kill-sigusr1-command/26913/6

[checking-tar-progress]: https://www.gnu.org/software/tar/manual/html_section/verbose.html