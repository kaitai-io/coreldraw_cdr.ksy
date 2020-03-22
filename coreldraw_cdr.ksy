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
      - id: chunk_size
        type: u4
      - id: chunk_data
        type: cdr_chunk_data
        size: chunk_size
      - id: pad_byte
        size: chunk_size % 2
  chunks:
    # Defined this type to be consistent with the unconsistent `cmpr` chunk
    seq:
      - id: chunks
        type: chunk
        repeat: eos
  chunks_comp:
    params:
      - id: block_sizes
        type: struct
    seq:
      - id: chunks
        type: chunk_comp(block_sizes.as<block_sizes>)
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
      - id: chunk_size
        type: u4
      - id: chunk_data
        type:
          switch-on: chunk_id
          cases:
            '"vrsn"': vrsn_chunk_data
            '"DISP"': disp_chunk_data
            '"LIST"': list_chunk_data
        size: chunk_size
      - id: pad_byte
        size: chunk_size % 2
  chunk_comp:
    params:
      - id: block_sizes
        type: struct
    seq:
      - id: chunk_id
        type: str
        size: 4
      - id: chunk_size_index
        type: u4
      - id: chunk_data
        type:
          switch-on: chunk_id
          cases:
            '"LIST"': list_chunk_data_comp(block_sizes)
            _: not_supported
        size: chunk_size
      - id: pad_byte
        size: chunk_size % 2
    instances:
      chunk_size:
        value: block_sizes.as<block_sizes>.sizes[chunk_size_index]
  vrsn_chunk_data:
    seq:
      - id: version
        type: u2
    instances:
      cdr_version:
        value: version / 100
  disp_chunk_data:
    doc: 'TODO: calculate size of `indices`'
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

      - id: palette
        type:
          switch-on: compression
          cases:
            # 0: samples(color_depth)
            _: not_supported
        size: bitmap_size
      - id: indices
        size-eos: true
  samples:
    doc: Not sure if that works correctly
    params:
      - id: color_depth
        type: u4
    seq:
      - id: samples
        type:
          switch-on: color_depth
          cases:
            2: b1
            4: b4
            8: b8
            16: u2
            32: u4
        repeat: eos
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
      - id: block_sizes
        type: struct
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
            _: chunks_comp(block_sizes)
        size-eos: true

  cmpr_special_chunk:
    seq:
      - id: size_pairs
        type: cmpr_size_pair
        repeat: expr
        repeat-expr: 2

      - id: cpng_first
        type: cmpr_special_subchunk(0)
        size: size_pairs[0].compressed
    instances:
      cpng_second:
        pos: size_pairs.size * (4 + 4) + size_pairs[0].compressed
        type: cmpr_special_subchunk(1)
        size: size_pairs[1].compressed
  cmpr_size_pair:
    seq:
      - id: compressed
        type: u4
      - id: uncompressed
        type: u4
  cmpr_special_subchunk:
    params:
      - id: index
        type: s4
    seq:
      - id: chunk_id
        contents: CPng
      - id: magic
        contents: [0x01, 0x00, 0x04, 0x00]
      - id: chunk_data
        type:
          switch-on: index
          cases:
            0: chunks_comp(_parent.cpng_second.chunk_data.as<block_sizes>)
            1: block_sizes
        size-eos: true
        process: zlib
  block_sizes:
    seq:
      - id: sizes
        type: u4
        repeat: eos

  not_supported: {}
