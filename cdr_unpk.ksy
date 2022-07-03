meta:
  id: cdr_unpk
  title: A made up format for unpacked streams from >=X6 CorelDraw CDR file
  application:
    - bin/cdr-unpk
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
    type: file_streams
    size: _io.size - len_root
  - id: root
    type: coreldraw_cdr(files)
    size: len_root
