meta:
  id: file_streams
  title: Type for cdr_unpk.ksy file streams
doc: |
  Avoids circular dependency cdr_unpk.ksy <-> coreldraw_cdr.ksy

  With this type, the dependency tree looks like this, which is fine:

             cdr_unpk
            /        \
           v          v
  coreldraw_cdr -> file_streams

seq:
  - id: files
    type: file
    repeat: eos
types:
  file:
    seq:
      - id: len_name
        type: u1
      - id: name
        type: str
        size: len_name
      - id: len_body
        type: u4
      - id: body
        size: len_body
