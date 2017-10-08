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
architecture, with the server component provided by [`ycmd`](https://github.com/Valloric/ycmd).
However, there is a pain point in that [`ycmd`](https://github.com/Valloric/ycmd)
requires the user compile `ycm_core.so` with a modern enough `cmake` and `libclang`
for it to function properly.

Furthermore, more and more projects are using Docker containers to provide a
uniform build environment containing all dependencies needed to build them.
These dependencies (usually libraries and headers) may not be present on the
user's system, and thus [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe)
will not be able to pick them up for completion.

## Implementation

### Docker

The [`Dockerfile`](Dockerfile) provided is only intended as an example (though
it can be used for basic C/C++ completion).
The parent image `alpine` should instead be replaced with the build image, and
subsequently `apk` with the corresponding package manager for that image.

### Vim

We override `g:ycm_python_server_interpreter` to launch our own container,
using an image which has both our dependencies (headers, libraries, etc) and
`ycmd`:

```vim
Plug 'Valloric/YouCompleteMe'
let g:ycm_server_python_interpreter = '<path/to/ycmd-python>'
```

It is imperative that the name of the `ycmd-python` ends with `python` (should it
need to be changed), else `YouCompleteMe` will refuse to launch it.

### Emacs / Spacemacs

**NB:** I have little success with this; while in theory this should work [`emacs-ycmd`](https://github.com/abingham/emacs-ycmd)
fails to contact the launched Docker container.

Emacs integration with `ycmd` is provided through [`emacs-ycmd`](https://github.com/abingham/emacs-ycmd).
[Spacemacs](http://spacemacs.org) provides this package through its [`ycmd` layer](https://github.com/syl20bnr/spacemacs/tree/master/layers/%2Btools/ycmd).

To use our container here, we override `ycmd-server-command` to use our binary:

```elisp
(setq ycmd-server-command '("<path/to/ycmd-python>")')
```

There does not appear to be any restriction on the name of `ycmd-python`,
though filename expansion is not supported for characters like `~`, so it may
be necessary to use `file-truename` to expand it.

## Caveats

You will not be able to jump to a file that is located only inside the
container, as your editor will not be able to find it in the host filesystem.
