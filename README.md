# coreldraw_cdr.ksy

CDR (CorelDRAW drawing) format specification for Kaitai Struct

## What is it

Formal specifications for the CorelDRAW `.cdr` format in [Kaitai Struct](https://kaitai.io/) YAML (`.ksy`), a declarative language for describing binary formats.

If you are interested in...

* what graphic objects (paths, polygons, rectangles, ellipses, embedded images) the CDR document contains,
* how do they look like (i.e. the geometry data associated with them: path points, rectangle side lengths and so on),
* what fill and outline styles the objects use (solid colors, gradients),
* what transformation matrix is applied on each object,

... and more, [Kaitai Struct](https://kaitai.io/) can make all this data accessible to you given the `.ksy` specifications from this repository.

## How to use

tl;dr **Use the `bin/cdr-unpk` Bash script** to process the `.cdr` file so that you can read all CDR versions (especially the new ones) without having to worry about what version of CDR format the `.cdr` file in front of you is using. The usage is the following:

```
bin/cdr-unpk example.cdr
```

and it will output an <code>example.cdr<strong>.unpk</strong></code> file into the same directory where `example.cdr` is. The `example.cdr.unpk` file needs to be processed by [`cdr_unpk.ksy`](cdr_unpk.ksy), which imports [`coreldraw_cdr.ksy`](coreldraw_cdr.ksy) and [`file_streams.ksy`](file_streams.ksy) under the hood and you have to **uncomment 3 blocks** in [`coreldraw_cdr.ksy`](coreldraw_cdr.ksy) marked as "*Uncomment when imported from cdr_unpk.ksy*". For example, this is the first one:

```diff
-  # # Uncomment when imported from cdr_unpk.ksy (for X6+ versions)
-  # imports:
-  #   - file_streams
+  # Uncomment when imported from cdr_unpk.ksy (for X6+ versions)
+  imports:
+    - file_streams
```

---

To understand why applying the `coreldraw_cdr.ksy` Kaitai Struct specification to real-world `.cdr` files is complicated, you need to have a basic overview of CDR format versions:

* X3 (13.0) and older: directly the RIFF-based chunk structure that `coreldraw_cdr.ksy` understands;
* X4 (14.0) and X5 (15.0): a ZIP archive, the `coreldraw_cdr.ksy` spec can only recognize the `content/riffData.cdr` file inside it;
* X6 (16.0) or later: also a ZIP archive, but the entrypoint is `content/root.dat` which needs to read external chunk payloads from `content/data/*.dat` files.

The main `coreldraw_cdr.ksy` specification can be used in two modes of operation:

1. As a standalone file (**not** recommended but requires no manual modifications to `coreldraw_cdr.ksy`) - directly on the `.cdr` file for pre-X4 files (will work great), or on `content/riffData.cdr` if it's in the ZIP archive of CDR X4/X5 files. For X6 and later it's technically possible to use it on `content/root.dat` itself too, but you won't get too deep into the file because it uses external streams for most chunks (so it's probably not going to be very useful).

2. Imported from `cdr_unpk.ksy` - the `cdr_unpk.ksy` spec then reads `example.cdr.unpk` files created by [`bin/cdr-unpk`](bin/cdr-unpk). In this mode, it is necessary to uncomment the "*Uncomment when imported from cdr_unpk.ksy*" blocks in [`coreldraw_cdr.ksy`](coreldraw_cdr.ksy), as described above.
