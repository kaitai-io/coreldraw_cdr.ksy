meta:
  id: coreldraw_cdr
  title: CorelDraw drawing
  license: MIT
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
  imports:
    - file_streams
doc: |
  A native file format of CorelDraw.
  Some test files are available here: https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/test_data/

doc-ref:
  - https://github.com/photopea/CDR-specification
  - https://github.com/LibreOffice/libcdr/tree/master/src/lib
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/docs/specification.txt
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/cdr_explorer/src/
params:
  - id: streams
    type: file_streams
seq:
  - id: riff_chunk
    type: riff_chunk
    size: root_len
  - id: streams
    type: slot
    size: stream_lens[_index]
    repeat: expr
    repeat-expr: stream_lens.size
instances:
  # Using example file from https://www.online-convert.com/file-format/cdr#:~:text=Download%20example.cdr%20file
  # unzipped to example/ folder
  #
  # Output from `ls -l example/content/data/` with files in the order
  # specified in `example/content/dataFileList.dat`:
  #
  #   -rw-r--r-- 1 Petr Pučil 197121     312 Oct 14  2014 data1.dat
  #   -rw-r--r-- 1 Petr Pučil 197121   11108 Oct 14  2014 Bitmaps.dat
  #   -rw-r--r-- 1 Petr Pučil 197121   17349 Oct 14  2014 data2.dat
  #   -rw-r--r-- 1 Petr Pučil 197121     451 Oct 14  2014 masterPage.dat
  #   -rw-r--r-- 1 Petr Pučil 197121 1642871 Oct 14  2014 page1.dat
  root_len:
    value: '51_204'
    doc-ref: "wc -c example/content/root.dat | cut -d ' ' -f 1"
  stream_names:
    value: '["data1.dat", "Bitmaps.dat", "data2.dat", "masterPage.dat", "page1.dat"]'
  stream_lens:
    value: '[312, 11108, 17349, 451, 1642871]'
  version:
    value: 'riff_chunk.body.version'
    # value: >-
    #   riff_chunk.body.chunks.chunks[0].chunk_id == 'vrsn'
    #     ? riff_chunk.body.chunks.chunks[0].body.as<vrsn_chunk_data>.version
    #     : riff_chunk.body.version
  precision_16bit:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2415-L2418
    value: _root.version < 600
types:
  slot: {}
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
      - id: c
        type: u1
      - id: chunks
        type: chunks
        size-eos: true
    instances:
      version:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L38-L49
        value: >-
          c == 0x20
             ? 300
             : c < 0x31
               ? 0
               : c < 0x3a
                 ? 100 * (c - 0x30)
                 : c < 0x41
                   ? 0
                   : 100 * (c - 0x37)
  chunk:
    seq:
      - id: chunk_id
        type: str
        size: 4
      - id: len
        type: u4
      - id: wrapper
        type:
          switch-on: chunk_id
          cases:
            # '"LIST"': list_chunk_data
            _: chunk_wrapper
        size: len
      - id: pad_byte
        size: len % 2
    # instances:
    #   chunk_debug:
    #     value: '(chunk_id == "LIST" ? ":" + body.as<list_chunk_data>.form_type : "")'
    # -webide-representation: "{chunk_id}{chunk_debug}"
  chunk_wrapper:
    seq:
      - id: stream_number
        type: u4
        if: is_stream_redir
      - id: len_body_redir
        type: u4
        if: is_stream_redir
      - id: stream_offs
        type: u4
        if: is_stream_redir and stream_number != 0xffffffff
      - id: body_seq
        type: chunk_body
        size: len_body
        if: not is_stream_redir or stream_number == 0xffffffff
    instances:
      body_inst:
        io: _root.streams[stream_number]._io
        pos: stream_offs
        type: chunk_body
        size: len_body
        # type: slot
        if: is_stream_redir and stream_number != 0xffffffff
      len_body:
        value: 'is_stream_redir ? len_body_redir : _io.size'
      is_stream_redir:
        value: '_root.version >= 1600 and _io.size == 0x10'
  chunk_body:
    seq:
      - id: body
        type:
          switch-on: _parent._parent.chunk_id
          cases:
            '"LIST"': list_chunk_data
            '"DISP"': disp_chunk_data
            '"loda"': loda_chunk_data
            '"lobj"': loda_chunk_data
            '"vrsn"': vrsn_chunk_data
            '"trfd"': trfd_chunk_data
            '"outl"': outl_chunk_data
            '"fild"': fild_chunk_data
            '"fill"': fild_chunk_data
            '"arrw"': arrw_chunk_data
            '"flgs"': flgs_chunk_data
            '"mcfg"': mcfg_chunk_data
            '"bmp "': bmp_chunk_data
            '"bmpf"': bmpf_chunk_data
            '"ppdt"': ppdt_chunk_data
            '"ftil"': ftil_chunk_data
            '"iccd"': iccd_chunk_data
            '"bbox"': bbox_chunk_data
            '"spnd"': spnd_chunk_data
            '"uidr"': uidr_chunk_data
            '"vpat"': vpat_chunk_data
            '"font"': font_chunk_data
            '"txsm"': txsm_chunk_data
            '"udta"': udta_chunk_data
            '"styd"': styd_chunk_data
        size-eos: true
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
            '"DISP"': disp_chunk_data
            '"loda"': loda_chunk_data
            '"trfd"': not_supported
            '"outl"': not_supported
            '"fild"': not_supported

            '"vrsn"': vrsn_chunk_data
            '"mcfg"': mcfg_chunk_data
        size: len_body
      - id: pad_byte
        size: len_body % 2
    instances:
      len_body:
        value: block_lens.sizes[len_body_index]
    #   chunk_debug:
    #     value: '(chunk_id == "LIST" ? ":" + chunk_data.as<list_chunk_data_comp>.form_type : "")'
    # -webide-representation: "{chunk_id}{chunk_debug}"
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
  loda_chunk_data:
    seq:
      - id: chunk_length
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        # valid: _io.size
      - id: num_of_args
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
      - id: start_of_args
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
      - id: start_of_arg_types
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
      - id: chunk_type_int
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
    instances:
      chunk_type:
        value: chunk_type_int
        enum: chunk_type
      arg_offsets:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2110-L2112
        pos: start_of_args
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        repeat: expr
        repeat-expr: num_of_args
      arg_types:
        doc: in reverse order against arg_offsets (arg_offsets[0] corresponds to arg_types[num_of_args - 1] and vice versa)
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2113-L2115
        pos: start_of_arg_types
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        repeat: expr
        repeat-expr: num_of_args
      args:
        type: arg(arg_offsets[_index], arg_types[(num_of_args - 1) - _index])
        repeat: expr
        # repeat-expr: num_of_args - 1
        repeat-expr: num_of_args
    types:
      # unsigned:
      #   seq:
      #     - id: value
      #       type:
      #         switch-on: _root.precision_16bit
      #         cases:
      #           true: u2
      #           false: u4
      #   -webide-representation: "{value:dec}"
      arg:
        params:
          - id: offs
            type: u4
          - id: type_raw
            type: u4
        instances:
          # not using an enum parameter to achieve better experience in the Web IDE
          type:
            value: type_raw
            enum: arg_type
          arg:
            pos: offs
            type:
              switch-on: type
              cases:
                'arg_type::loda_coords': loda_coords
                'arg_type::fill_style': fill_style
                'arg_type::line_style': line_style
                'arg_type::style': style
                'arg_type::polygon_transform': polygon_transform
                'arg_type::opacity': opacity
                'arg_type::page_size': page_size
            # size-eos: true

      loda_coords:
        seq:
          - id: chunk
            type:
              switch-on: _parent._parent.chunk_type
              cases:
                'chunk_type::spline': spline
                'chunk_type::rectangle': rectangle
                'chunk_type::ellipse': ellipse
                'chunk_type::line_and_curve': line_and_curve
                'chunk_type::path': path
                'chunk_type::artistic_text': artistic_text
                'chunk_type::bitmap': bitmap
                'chunk_type::paragraph_text': paragraph_text
                'chunk_type::polygon_coords': polygon_coords

      fill_style: {}
      line_style: {}
      style: {}
      polygon_transform: {}
      opacity: {}
      page_size: {}

      spline: {}
      rectangle:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L1162
        seq:
          - id: x0
            type: rect_coord
          - id: y0
            type: rect_coord
          - id: ext
            type:
              switch-on: _root.version < 1500
              cases:
                true: rect_old_ext
                _: rect_new_ext
        types:
          rect_old_ext:
            seq:
              - id: r3
                type: rect_coord
              - id: r2
                type: rect_coord
                if: _root.version >= 900
              - id: r1
                type: rect_coord
                if: _root.version >= 900
              - id: r0
                type: rect_coord
                if: _root.version >= 900
          rect_new_ext:
            seq:
              - id: scale_x
                type: f8
              - id: scale_y
                type: f8
              - id: scale_with
                type: u1
              - id: unkw_3
                size: 7
              - id: r3_raw
                type: f8
              - id: corner_type
                type: u1
              - id: unkw_2
                size: 15
              - id: r2_raw
                type: f8
              - id: unkw_1
                size: 16
              - id: r1_raw
                type: f8
              - id: unkw_0
                size: 16
              - id: r0_raw
                type: f8
            instances:
              width:
                value: _parent.x0.value * scale_x / 2.0
              height:
                value: _parent.y0.value * scale_y / 2.0
              scale:
                value: 'scale_with == 0 ? 1 : 254000.0'
              r3:
                value: r3_raw * scale
              r2:
                value: r2_raw * scale
              r1:
                value: r1_raw * scale
              r0:
                value: r0_raw * scale

          rect_coord:
            seq:
              - id: raw
                type:
                  switch-on: _root.version < 1500
                  cases:
                    true: coord
                    _: f8
            instances:
              value:
                value: '_root.version < 1500 ? raw.as<coord>.value : raw.as<f8> / 254000.0'
      ellipse: {}
      line_and_curve:
        seq:
          - id: num_points_raw
            type: u2
          - id: unknown
            size: 2
          - id: points
            type: point
            repeat: expr
            repeat-expr: num_points
          - id: point_types
            type: u1
            repeat: expr
            repeat-expr: num_points
        instances:
          num_points:
            value: 'num_points_raw <= num_points_max ? num_points_raw : num_points_max'
          num_points_max:
            value: '(_io.size - _io.pos) / (_root.precision_16bit ? sizeof<s2> : sizeof<s4>)'
          point_size:
            value: '2 * (_root.precision_16bit ? sizeof<s2> : sizeof<s4>) + 1'
        types:
          point:
            seq:
              - id: first
                type: coord
              - id: second
                type: coord
      path: {}
      artistic_text: {}
      bitmap: {}
      paragraph_text: {}
      polygon_coords: {}
    enums:
      arg_type:
        0x1e: loda_coords
        0x14: fill_style
        0x0a: line_style
        0xc8: style
        0x2af8: polygon_transform
        0x1f40: opacity
        0x64: waldo_trfd
        0x4aba: page_size
      chunk_type:
        0x26: spline
        0x01: rectangle
        0x02: ellipse
        0x03: line_and_curve
        0x25: path
        0x04: artistic_text
        0x05: bitmap
        0x06: paragraph_text
        0x14: polygon_coords


  trfd_chunk_data: {}
  outl_chunk_data: {}
  fild_chunk_data: {}
  arrw_chunk_data: {}
  flgs_chunk_data: {}
  mcfg_chunk_data:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2190
    # mostly reverse-engineered from generated files using CorelDraw 9
    seq:
      - id: unknown0
        size: len_unknown0
      - id: old_page_size
        if: v < 400
        type: old_page_size
      - id: page_size
        if: v >= 400
        type: page_size
      - id: unknown1
        type: u2
      - id: orientation
        type: u2
        enum: orientation
      - id: unknown2
        size: 12
      - id: show_page_border
        type: u2
        enum: boolean
      - id: layout
        type: u2
        enum: layout
      - id: facing_pages
        type: u2
        enum: boolean
      - id: start_on
        type: u2
        enum: start_on
      - id: offset_x
        type: coord
      - id: offset_y
        type: coord
      - id: grid_freq_horz
        type: f4
      - id: grid_freq_vert
        type: f4
      - id: unit_horz
        doc: Also the default drawing unit
        type: u2
        enum: unit
      - id: unit_vert
        type: u2
        enum: unit
      - id: unit_unknown
        doc: No idea what is this used for, cannot make different from `unit_horz`
        type: u2
        enum: unit
      - id: scale_factor
        type: f4
      - id: scale_unit
        type: u2
        enum: unit
      - id: debug_rest
        size-eos: true
    types:
      old_page_size:
        seq:
          - id: unknown
            size: 2
          - id: x0
            type: coord
          - id: y0
            type: coord
          - id: x1
            type: coord
          - id: y1
            type: coord
      page_size:
        seq:
          - id: width
            type: coord
          - id: height
            type: coord
    instances:
      v:
        value: _root.version
      len_unknown0:
        value: >-
          v >= 1300 ?
            12 :
            v >= 900 ?
              4 :
              v < 700 and v >= 600 ?
                0x1c :
                0
      width:
        value: 'v < 400 ? (old_page_size.x1.value - old_page_size.x0.value) : page_size.width.value'
      height:
        value: 'v < 400 ? (old_page_size.y1.value - old_page_size.y0.value) : page_size.height.value'
    enums:
      orientation:
        0: portrait
        1: landscape
      layout:
        1: full_page
        2: book
        3: booklet
        4: tent
        5: side_folded_card
        6: top_folded_card
      boolean:
        0: false
        1: true
      start_on:
        0: right_side
        1: left_side
      unit:
        1: inch
        2: milimeter
        3: picas_point
        4: point
        5: centimeter
        6: pixel
        7: feet
        8: mile
        9: meter
        10: kilometer
        12: ciceros_didot
        13: didot
        16: yard
  bmp_chunk_data: {}
  bmpf_chunk_data: {}
  ppdt_chunk_data: {}
  ftil_chunk_data: {}
  iccd_chunk_data: {}
  bbox_chunk_data: {}
  spnd_chunk_data: {}
  uidr_chunk_data: {}
  vpat_chunk_data: {}
  font_chunk_data: {}
  stlt_chunk_data: {}
  txsm_chunk_data: {}
  udta_chunk_data: {}
  styd_chunk_data: {}

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

  coord:
    seq:
      - id: raw
        type:
          switch-on: _root.precision_16bit
          cases:
            true: s2
            _: s4
    instances:
      value:
        value: >-
          _root.precision_16bit ?
            raw / 1000.0 :
            raw / 254000.0
    -webide-representation: "{value:dec}"
  not_supported: {}
