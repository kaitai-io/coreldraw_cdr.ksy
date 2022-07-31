# coreldraw_cdr.ksy

CDR (CorelDRAW drawing) format specification for Kaitai Struct

## What it is

Formal specifications for the CorelDRAW `.cdr` format in [Kaitai Struct](https://kaitai.io/) YAML (`.ksy`), a declarative language for describing binary formats.

If you are interested in...

* what graphic objects (paths, polygons, rectangles, ellipses, embedded images) the CDR document contains,
* how do they look like (i.e. the geometry data associated with them: path points, rectangle side lengths and so on),
* what fill and outline styles the objects use (solid colors, gradients),
* what transformation matrix is applied on each object,

... and more, [Kaitai Struct](https://kaitai.io/) can make all this data accessible to you given the `.ksy` specifications from this repository.

## How to use

**Use the [`bin/cdr-unpk`](bin/cdr-unpk) Bash script** to preprocess the `.cdr` file so that you can read all CDR versions (especially the new ones) without having to worry about what version of the CDR format the `.cdr` file in front of you is using. The usage is the following:

```
bin/cdr-unpk example.cdr
```

It creates <code>example.cdr<strong>.unpk</strong></code> in the same directory where `example.cdr` is. The `example.cdr.unpk` file needs to be interpreted by [`cdr_unpk.ksy`](cdr_unpk.ksy) (which imports [`coreldraw_cdr.ksy`](coreldraw_cdr.ksy) and [`file_streams.ksy`](file_streams.ksy) under the hood).

---

To understand why applying the `coreldraw_cdr.ksy` Kaitai Struct specification to real-world `.cdr` files is complicated, you need to have a basic overview of CDR format versions:

* X3 (13.0) and older: directly the RIFF-based chunk structure that `coreldraw_cdr.ksy` understands;
* X4 (14.0) and X5 (15.0): a ZIP archive, the `coreldraw_cdr.ksy` spec can only recognize the `content/riffData.cdr` file inside it;
* X6 (16.0) or later: also a ZIP archive, but the entrypoint is `content/root.dat` which needs to read external chunk payloads from `content/data/*.dat` files.

The need for accessing external streams in CDR X6+ files was a problem, because to be able to use visualizers available for [Kaitai Struct](https://kaitai.io/) (e.g. [ksv](https://github.com/kaitai-io/kaitai_struct_visualizer), [Web IDE](https://ide.kaitai.io/)), the entire parsed byte stream needs to be contained in a single file and the top-level type in the main `.ksy` spec must not have any parameters. That's why the [`bin/cdr-unpk`](bin/cdr-unpk) script was created - it extracts the necessary streams from the given `.cdr` file and dumps them into a `.unpk` file in a custom auxiliary format described in [`cdr_unpk.ksy`](cdr_unpk.ksy).

## Standalone use of `coreldraw_cdr.ksy`

By default, the `coreldraw_cdr.ksy` spec is expected to be imported from [`cdr_unpk.ksy`](cdr_unpk.ksy) and not used by itself. However, if you don't want to preprocess `.cdr` files by [`bin/cdr-unpk`](bin/cdr-unpk), you can manually edit `coreldraw_cdr.ksy` to disable support for external streams (comment out sections `/meta/imports`, `/params` and `/types/chunk_wrapper/instances/body_external`).

Such a `coreldraw_cdr.ksy` specification can be used directly on the `.cdr` file for pre-X4 files (will work great), or on `content/riffData.cdr` if it's inside the ZIP archive of CDR X4/X5 files. For X6 and later it's technically possible to use it on `content/root.dat` itself too, but you won't get too deep into the file because it uses external streams for most chunks (so it probably won't be very useful).
