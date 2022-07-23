meta:
  id: cdr_unpk
  title: A made up format for unpacked streams from >=X6 CorelDRAW .cdr file
  application: bin/cdr-unpk
  file-extension: cdr.unpk
  endian: be
  encoding: ascii
  imports:
    - file_streams
    - coreldraw_cdr
seq:
  - id: magic
    contents: unpk
  - id: len_root
    type: u4
  - id: files
    size: _io.size - _io.pos - len_root
    type: file_streams
  - id: root
    size: len_root
    type: coreldraw_cdr(files)
