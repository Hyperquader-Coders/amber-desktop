# amber-desktop

The Amber Linux suite under one name.

```sh
sudo apt install amber-desktop
```

## What it is

A metapackage: a `.deb` with no payload at all. It ships a copyright file, a
changelog and a lintian override — the Debian-policy minimum — and nothing else.
The whole product is the `Depends` line.

```
Depends:    kat800, ambrosia, copal, amberlin
Recommends: amber-odin, amber-ols
Suggests:   amberlin-backend
```

Installing it installs the four applications. **Removing it leaves them
installed** — it only stops holding them, which is the point: a user who no
longer wants the suite as a set can drop this and keep whatever they use.

## What it deliberately does not name

**The shared libraries.** `amber-fonts` and `amber-gtk4` are dependencies of the
applications themselves, so apt pulls them in anyway. Naming them here would be a
second place to keep the same fact.

**The ONNX runtime.** `amberlin-runtime` and `amberlin-runtime-cuda` are mutually
exclusive — both provide the virtual `amberlin-onnxruntime`, and installing both
is wrong. A metapackage naming either would make that choice for the user, so it
names neither.

**The toolchain, as a requirement.** `amber-odin` and its language server are
`Recommends`: running the suite needs no compiler.

```sh
sudo apt install --no-install-recommends amber-desktop   # suite only
```

## Building

```sh
make deb        # dist/amber-desktop_<version>-1_all.deb
make check      # every name in Depends exists in the archive
make lint       # check + lintian + shellcheck
```

`make check` needs a sibling checkout of the apt archive to ask what it carries;
without one it skips rather than fails, so the package still builds from a bare
clone. A typo in a dependency name would otherwise fail on a user's machine
rather than here.

## Where the packages come from

- <https://apt.amberlinux.org> — the archive itself, signed, for Linux Mint 22+
  and other Ubuntu noble derivatives.
- <https://amberlinux.org/packages/> — every package and what it is for.

## Licence

**BSD-3-Clause**, covering the packaging in this repository — the Makefile, the
control template and the changelog. See [LICENSE](LICENSE).

It restricts nothing about the suite, because this package contains no files:
it is a metapackage whose entire function is its `Depends:` line. **The
applications it installs carry their own licences**, and most of the suite is
BUSL-1.1 — source-available, with commercial-use restrictions and a change date.
Read the licence of the application you care about, or
[`amberlinux-apt/docs/LICENSING.md`](https://github.com/Hyperquader-Coders/amberlinux-apt/blob/main/docs/LICENSING.md)
for how the suite is licensed as a whole.

Permissive packaging around restrictively-licensed applications is the normal
shape, and the same one the archives use: being free to reuse a `Depends:` line
says nothing about what you may do with what it pulls in.
