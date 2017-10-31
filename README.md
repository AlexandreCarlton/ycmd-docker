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
it can be used for basic C/C++ completion).
The parent image [`alpine`](https://hub.docker.com/_/alpine/) should instead be
replaced with the build image, and subsequently [`apk`](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management)
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
