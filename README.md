# ycmd-docker

[![Build
Status](https://travis-ci.org/AlexandreCarlton/ycmd-docker.svg?branch=master)](https://travis-ci.org/AlexandreCarlton/ycmd-docker)

An example of running a Dockerized [`ycmd`](https://github.com/Valloric/ycmd) to:
 - obviate the need to build `ycm_core.so`.
 - capture completion suggestions for libraries that may not be present on the
   user's system when using [`YouCompleteMe`](https://github.com/Valloric/YouCompleteMe).

## Why?

Many projects use Docker containers to capture all build dependencies that may
not normally be present on the user's system to provide a standard build
environment for all developers.
As such, certain completions may only be partially enabled as `YouCompleteMe`
will not be able to find headers that can only be found inside a running
instance of the build container.

## How?

### Docker

The `Dockerfile` provided is only intended as an example (though it can be used
for basic C/C++ completion).
The parent image `alpine` should instead be replaced with the build image, and
subsequently `apk` with the corresponding package manager for that image.


### Vim
We override the `g:ycm_python_server_interpreter` to launch our own container,
using an image which has both our dependencies (headers, libraries, etc) and
`ycmd`:

```vim
Plug 'Valloric/YouCompleteMe'
let g:ycm_server_python_interpreter = '<path/to/ycm-python>'
```

It is imperative that the name of the `ycm-python` ends with `python` if it
needs to be changed, else `YouCompleteMe` will refuse to launch it.
