# ycmd-docker

[![Build
Status](https://travis-ci.org/AlexandreCarlton/ycmd-docker.svg?branch=master)](https://travis-ci.org/AlexandreCarlton/ycmd-docker)

An example of running a containerised [`ycmd`](https://github.com/Valloric/ycmd) to:
 - obviate the need to build `ycm_core.so`.
 - capture completion suggestions for libraries that may not be present on the
   user's system when using [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe).

## Motivation

[`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe) is a popular Vim
plugin that provides the user with semantic completion. It has a client-server
architecture, with the server component [`ycmd`](https://github.com/Valloric/ycmd)
providing code-completion and comprehension.
However, there is a pain point in that [`ycmd`](https://github.com/Valloric/ycmd)
requires the user compile `ycm_core.so` with a modern enough [CMake](https://cmake.org/)
and [LibClang](https://clang.llvm.org/docs/Tooling.html) for it to function properly.

Furthermore, more and more projects are using Docker containers to provide a
uniform build environment containing all dependencies needed to build them.
These dependencies (usually libraries and headers) may not be present on the
user's system, and thus [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe)
will not be able to pick them up for completion.

## Implementation

Normally, [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe) fires up
[`ycmd`](https://github.com/Valloric/ycmd) by invoking `python` on its nested
[`ycmd` folder](https://github.com/Valloric/ycmd/tree/master/ycmd) (which
essentially invokes the contained [`__main__.py`](https://github.com/Valloric/ycmd/blob/master/ycmd/__main__.py)).
We will configure [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe) to instead fire up our own Docker container
by fooling it into thinking our script [`ycmd-python`](ycmd-python) is the Python
server interpreter (when it really just launches our own dockerized [`ycmd`](https://github.com/Valloric/ycmd)
instead).

### Docker

The [`Dockerfile`](Dockerfile) provided is only intended as an example (though
it can be used for basic completion).
The parent image [`ubuntu`](https://hub.docker.com/_/ubuntu/) should instead be
replaced with the build image, and subsequently [`apt-get`](https://linux.die.net/man/8/apt-get)
with the corresponding package manager for that image.

### Vim

We copy the [`ycmd-python`](ycmd-python) script somewhere into our `$PATH`,
tweaking the image name as necessary.

We then override `g:ycm_python_server_interpreter` to launch our own container,
using an image which has both our dependencies (headers, libraries, etc) and
[`ycmd`](https://github.com/Valloric/ycmd):

```vim
Plug 'Valloric/YouCompleteMe'
let g:ycm_server_python_interpreter = 'ycmd-python'
```

It is imperative that the name of [`ycmd-python`](ycmd-python) ends with
`python` (should it need to be changed), else [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe)]
will refuse to launch it.

### Emacs / Spacemacs

**NB:** I have little success with this; while in theory this should work [`emacs-ycmd`](https://github.com/abingham/emacs-ycmd)
fails to contact the launched Docker container.

Emacs integration with [`ycmd`](https://github.com/Valloric/ycmd) is provided through [`emacs-ycmd`](https://github.com/abingham/emacs-ycmd).
[Spacemacs](http://spacemacs.org) provides this package through its [`ycmd` layer](https://github.com/syl20bnr/spacemacs/tree/master/layers/%2Btools/ycmd).

To use our container here, we override `ycmd-server-command` to use our binary:

```elisp
(setq ycmd-server-command '("ycmd-python")')
```

There does not appear to be any restriction on the name of [`ycmd-python`](ycmd-python),
though filename expansion is not supported for characters like `~`, so it may
be necessary to use `file-truename` to expand it.

## Diagnostics

### Locating the container instance
A typical YouCompleteMe instance will display the following diagnostics with
`:YcmDebugInfo`:

```
Printing YouCompleteMe debug information...
...
-- Server running at: http://127.0.0.1:8888
-- Server process ID: 123456
...
```

Normally we would use the process ID to locate the running instance and monitor
it.
However, as we are using docker to run this, we cannot use this method.
To make this easier for the user, the containers launched using [`ycmd-python`](ycmd-python)
will have the format `ycmd-<pid>`, so that this will match what we see in the
diagnostic information.
In this instance, we would look for the container `ycmd-12345` using
`docker ps -a`.

### Retrieving logs
A regular installation of YouCompleteMe will start a server that logs to
several files, which can be inspected using `:YcmDebugInfo`:

```
Printing YouCompleteMe debug information...
...
-- Server running at: http://127.0.0.1:8888
...
-- Server logfiles:
--   /tmp/ycmd_8888_stdout_abcdefgh.log
--   /tmp/ycmd_8888_stderr_ijklmnop.log
...
```

However, on a long running server this will result in log files that may never
be cleaned up.

To resolve this, we do not copy across the arguments provided to the `stdout`
and `stderr` options so that `ycmd` will log to `/dev/stdout` and `/dev/stderr`
respectively, and clean this up when we are done with them.
To retrieve them, we can use `docker logs` on the particular instance that we
want (using the process ID as described above).

Note that [`YouCompleteMe` will still create these files regardless of whether
they end up being used](https://github.com/Valloric/YouCompleteMe/blob/28292f0f62e6352111b694ce8753bf739b50fb40/python/ycm/youcompleteme.py#L175),
though they will remain empty.

## Caveats

### Python completion

[`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe) uses
[`jedi`](https://github.com/davidhalter/jedi) for Python
semantic completion. By default, it uses the same python interpreter used to
run [`ycmd`](https://github.com/Valloric/ycmd) (which in the example image is `/usr/bin/python3`).

In order to capture completions for third-party libraries found in a
virtual environment, one can tweak their `.vimrc` to point to the currently
active python:

```vim
let g:ycm_python_binary_path = 'python'
```

[`ycmd-python`](ycmd-python) will automatically pick this up if the activated virtual
environment lies in `$HOME`.

### `:YcmCompleter GoTo`

You will not be able to jump to a file that is located only inside the
container, as your editor will not be able to find it in the host filesystem.
