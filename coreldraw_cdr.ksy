meta:
  id: coreldraw_cdr
  title: CorelDraw drawing
  license: CC0-1.0
  application: CorelDraw
  file-extension: cdr
  xref:
    justsolve: CorelDRAW
    pronom:
      - fmt/465
    wikidata:
      - Q939636
      - Q142371
  encoding: ASCII
  endian: le

doc: |
  A native file format of CorelDraw.
  Some test files are available here: https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/test_data/

doc-ref:
  - https://github.com/photopea/CDR-specification
  - https://github.com/LibreOffice/libcdr/tree/master/src/lib
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/docs/specification.txt
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/cdr_explorer/src/
seq:
  - id: riff_chunk
    type: riff_chunk
types:
  riff_chunk:
    seq:
      - id: chunk_id
        contents: RIFF
      - id: len_body
        type: u4
      - id: body
        type: cdr_chunk_data
        size: len_body
      - id: pad_byte
        size: len_body % 2
  chunks:
    # Defined this type to be consistent with the unconsistent `cmpr` chunk
    seq:
      - id: chunks
        type: chunk
        repeat: eos
  chunks_comp:
    params:
      - id: block_lens
        type: chunk_sizes
    seq:
      - id: chunks
        type: chunk_comp(block_lens)
        repeat: eos
  cdr_chunk_data:
    seq:
      - id: form_type
        contents: CDR
      - id: version
        type: str
        size: 1
      - id: chunks
        type: chunks
        size-eos: true
  chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
      - id: len_body
        type: u4
      - id: body
        type:
          switch-on: chunk_id
          cases:
            '"vrsn"': vrsn_chunk_data
            '"DISP"': disp_chunk_data
            '"LIST"': list_chunk_data
        size: len_body
      - id: pad_byte
        size: len_body % 2
  chunk_comp:
    params:
      - id: block_lens
        type: chunk_sizes
    seq:
      - id: chunk_id
        type: str
        size: 4
      - id: len_body_index
        type: u4
      - id: body
        type:
          switch-on: chunk_id
          cases:
            '"LIST"': list_chunk_data_comp(block_lens)
            _: not_supported
        size: len_body
      - id: pad_byte
        size: len_body % 2
    instances:
      len_body:
        value: block_lens.sizes[len_body_index]
  vrsn_chunk_data:
    seq:
      - id: version
        type: u2
  disp_chunk_data:
    # TODO: replace with imported type from BMP spec
    seq:
      - id: unknown
        size: 4
      - id: header_size
        type: u4
      - id: width
        type: u4
      - id: height
        type: u4
      - id: color_plane_value
        type: u2
      - id: color_depth
        type: u2
      - id: compression
        type: u4
      - id: bitmap_size
        type: u4
      - id: width2
        type: u4
      - id: height2
        type: u4
      - id: colors_num
        type: u4
      - id: used_colors_num
        type: u4
  list_chunk_data:
    seq:
      - id: form_type
        type: str
        size: 4
      - id: chunks
        type:
          switch-on: form_type
          cases:
            '"cmpr"': cmpr_special_chunk
            '"stlt"': not_supported
            _: chunks
        size-eos: true
  list_chunk_data_comp:
    params:
      - id: block_lens
        type: chunk_sizes
    seq:
      - id: form_type
        type: str
        size: 4
      - id: chunks
        type:
          switch-on: form_type
          cases:
            '"stlt"': not_supported
            _: chunks_comp(block_lens)
        size-eos: true

  cmpr_special_chunk:
    seq:
      - id: size_pairs
        type: cmpr_size_pair
        repeat: expr
        repeat-expr: 2
      - id: cpng_first
        type: cmpr_special_subchunk(true)
        size: size_pairs[0].compressed
    instances:
      cpng_second:
        pos: sizeof<cmpr_size_pair> * size_pairs.size + size_pairs[0].compressed
        type: cmpr_special_subchunk(false)
        size: size_pairs[1].compressed
  cmpr_size_pair:
    seq:
      - id: compressed
        type: u4
      - id: uncompressed
        type: u4
  cmpr_special_subchunk:
    params:
      - id: is_first_cpng
        type: bool
    seq:
      - id: chunk_id
        contents: CPng
      - id: magic
        contents: [0x01, 0x00, 0x04, 0x00]
      - id: chunk_data
        type:
          switch-on: is_first_cpng
          cases:
            true: chunks_comp(_parent.cpng_second.chunk_data.as<chunk_sizes>)
            _: chunk_sizes
        size-eos: true
        process: zlib
  chunk_sizes:
    seq:
      - id: sizes
        type: u4
        repeat: eos

  not_supported: {}
