meta:
  id: coreldraw_cdr
  title: CorelDRAW drawing
  license: MIT
  application: CorelDRAW
  file-extension: cdr
  xref:
    justsolve: CorelDRAW
    pronom:
      - fmt/465
    wikidata: Q939636
  encoding: ASCII
  endian: le
  # # Uncomment when imported from cdr_unpk.ksy (for X6+ versions)
  # imports:
  #   - file_streams
doc: |
  A native file format of CorelDRAW.

  Some test files (but only old CDR versions, the latest ones are X3 and
  CorelDRAW X3 was released in 2006) are available here:
  <https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/testing%20base/>

doc-ref:
  - https://github.com/LibreOffice/libcdr/tree/master/src/lib
  - https://github.com/sk1project/uniconvertor/blob/master/src/uc2/formats/cdr/cdr_model.py # rather don't use, very inferior to libcdr
  - https://github.com/photopea/CDR-specification # incomplete, for basic overview only
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/cdr_explorer/src/chunks.py # very old and incomplete, but maybe as a curiosity
# # Uncomment when imported from cdr_unpk.ksy (for X6+ versions)
# params:
#   - id: streams
#     type: file_streams
seq:
  - id: riff_chunk
    type: riff_chunk
instances:
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
    -webide-representation: '{chunk_id}'
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
    doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L2062-L2085
    seq:
      - id: stream_number
        type: u4
        if: has_redir_data
      - id: len_body_redir
        type: u4
        if: has_redir_data
      - id: ofs_body_external
        type: u4
        if: is_body_external
      - id: body_local
        type: chunk_body
        size: len_body
        if: not is_body_external
    instances:
      # # Uncomment when imported from cdr_unpk.ksy (for X6+ versions)
      # body_external:
      #   io: _root.streams.files[stream_number].body._io
      #   pos: ofs_body_external
      #   size: len_body
      #   type: chunk_body
      #   if: is_body_external
      len_body:
        value: 'has_redir_data ? len_body_redir : _io.size'
      has_redir_data:
        value: '_root.version >= 1600 and _io.size == 0x10'
      is_body_external:
        value: 'has_redir_data and stream_number != 0xffff_ffff'
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
            '"stlt"': stlt_chunk_data
            '"txsm"': txsm_chunk_data
            '"udta"': udta_chunk_data
            '"styd"': styd_chunk_data
        size-eos: true
  chunk_comp:
    -webide-representation: '{chunk_id}'
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
            '"outl"': outl_chunk_data
            '"fild"': fild_chunk_data

            '"vrsn"': vrsn_chunk_data
            '"mcfg"': mcfg_chunk_data
        size: len_body
      - id: pad_byte
        size: len_body % 2
    instances:
      len_body:
        io: block_lens._io
        pos: len_body_index * sizeof<u4>
        type: u4
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
        valid: _io.size
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

      fill_style:
        seq:
          - type: waldo_fill
            if: _root.version < 400
          - id: fill_id
            if: _root.version >= 400
            type: u4
        types:
          waldo_fill:
            seq:
              - id: fill_type
                type: u1
              - type:
                  switch-on: fill_type
                  cases:
                    1: solid
                    2: linear_gradient
                    4: radial_gradient
                    7: pattern
                    10: full_color
                    _: not_supported
            types:
              solid:
                seq:
                  - id: color
                    type: color
              linear_gradient:
                seq:
                  - type: gradient
                instances:
                  gradient_type:
                    value: 1
              radial_gradient:
                seq:
                  - type: gradient
                instances:
                  gradient_type:
                    value: 2
              pattern:
                seq:
                  - id: pattern_id
                    type:
                      switch-on: _root.version < 300
                      cases:
                        true: u2
                        _: u4
                  - type: pattern_data
                  - id: color1
                    type: color
                  - id: color2
                    type: color
              full_color:
                seq:
                  - id: pattern_id
                    type: u2
                  - type: pattern_data
              gradient:
                seq:
                  - id: angle
                    type: angle
                  - id: color1
                    type: color
                  - id: color2
                    type: color
                  - id: unknown
                    if: _root.version >= 200
                    size: 7
                  - id: edge_offset
                    if: _root.version >= 200
                    type: s2
                  - id: center_x_offset
                    if: _root.version >= 200
                    type:
                      switch-on: _root.precision_16bit
                      cases:
                        true: u2
                        _: u4
                  - id: center_y_offset
                    if: _root.version >= 200
                    type:
                      switch-on: _root.precision_16bit
                      cases:
                        true: u2
                        _: u4
              pattern_data:
                seq:
                  - id: pattern_width
                    type: coord
                  - id: pattern_height
                    type: coord
                  - id: tile_offset_x_raw
                    type: u2
                  - id: tile_offset_y_raw
                    type: u2
                  - id: rcp_offset_raw
                    type: u2
                  - id: unknown
                    size: 1
                instances:
                  tile_offset_x:
                    value: tile_offset_x_raw / 100.0
                  tile_offset_y:
                    value: tile_offset_y_raw / 100.0
                  rcp_offset:
                    value: rcp_offset_raw / 100.0
      line_style:
        seq:
          - type: waldo_outl
            if: _root.version < 400
          - id: outl_id
            if: _root.version >= 400
            type: u4
        types:
          waldo_outl:
            seq:
              - id: line_type_raw
                type: u1
              - id: line_width
                type: coord
              - id: stretch_raw
                type: u2
              - id: angle
                type: angle
              - id: color
                type: color
              - id: unknown1
                size: 7
              - id: num_dash
                type: u1
              - size: 0
                if: ofs_dashes < 0
              - id: unknown2
                size: 10
              - id: join_type
                type: u2
              - id: caps_type
                type: u2
              - id: start_marker_id
                type: u4
              - id: end_marker_id
                type: u4
            instances:
              ofs_dashes:
                value: _io.pos
              dashes:
                pos: ofs_dashes
                type: u1
                repeat: expr
                repeat-expr: num_dash
      style:
        seq:
          - id: style_id
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
      polygon_transform:
        seq:
          - id: unknown1
            if: _root.version < 1300
            size: 4
          - id: num_angles
            type: u4
          - id: next_point1
            type: u4
          - id: next_point2
            if: next_point1 <= 1
            type: u4
          - id: unknown2
            if: next_point1 > 1
            size: 4
          - id: unknown3
            if: _root.version >= 1300
            size: 4
          - id: rx
            type: f8
          - id: ry
            type: f8
          - id: cx
            type: coord
          - id: cy
            type: coord
      opacity:
        seq:
          - id: unknown
            size:
              '_root.version < 1300 ? 10 : 14'
          - id: opacity_raw
            type: u2
        instances:
          opacity:
            value: opacity_raw / 1000.0
      page_size:
        seq:
          - id: width
            type: coord
          - id: heigth
            type: coord

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
      ellipse:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L1278
        seq:
          - id: x
            type: coord
          - id: y
            type: coord
          - id: angle1
            type: angle
          - id: angle2
            type: angle
          - id: pie_raw
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
        instances:
          cx:
            value: x.value / 2.0
          cy:
            value: y.value / 2.0
          rx:
            value: >-
                  cx >= 0 ? cx : -cx
          ry:
            value: >-
                  cy >= 0 ? cy : -cy
          pie:
            value: 'pie_raw != 0 ? true : false'
          angle1_rem:
            value: angle1.value % (2 * 3.14159265358979323846)
          angle1_normalized:
            value: 'angle1_rem < 0 ? angle1_rem + (2 * 3.14159265358979323846) : angle1_rem'
          angle2_rem:
            value: angle2.value % (2 * 3.14159265358979323846)
          angle2_normalized:
            value: 'angle2_rem < 0 ? angle2_rem + (2 * 3.14159265358979323846) : angle2_rem'
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
      path:
        seq:
          - id: unknown1
            size: 4
          - id: point_num_raw1
            type: u2
          - id: point_num_raw2
            type: u2
          - id: unknown2
            size: 16
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
            value: >-
                  num_points_max < 16
                    ? 0
                      : point_num_raw1 + point_num_raw2 > (num_points_max - 16) / point_size
                        ? (num_points_max - 16) / point_size
                          : point_num_raw1 + point_num_raw2
          num_points_max:
            value: '(_io.size - _io.pos)'
          point_size:
            value: '2 * (_root.precision_16bit ? sizeof<s2> : sizeof<s4>) + 1'
        types:
          point:
            seq:
              - id: first
                type: coord
              - id: second
                type: coord
      artistic_text:
        seq:
          - id: x
            type: coord
          - id: y
            type: coord
      bitmap:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L1468
        seq:
          - id: x1
            type: coord
          - id: y1
            type: coord
          - id: x2
            type: coord
          - id: y2
            type: coord
          - id: unknown1
            size: 16
          - id: unknown2
            size: 16
          - id: image_id
            type: u4
          - id: unknown3
            size: >-
                  _root.version < 400
                    ? 8
                      : _root.version >= 800 and _root.version < 900
                        ? 12
                          : 20
          - id: point_num
            type: u2
          - id: unknown4
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
            value: 'point_num <= point_num ? point_num : num_points_max'
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
      paragraph_text:
        seq:
          - id: unknown1
            size: 4
          - id: width
            type: coord
          - id: height
            type: coord
      polygon_coords:
        seq:
          - id: point_num
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
            value: 'point_num <= point_num ? point_num : num_points_max'
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
    enums:
      arg_type:
        10: line_style
        20: fill_style
        30: loda_coords
        100: waldo_trfd
        200: style
        1000:
          id: name
          doc-ref: https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_const.py#L41
        8000: opacity
        11000: polygon_transform
        12010:
          id: gradient
          doc-ref: https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_const.py#L46
        19130:
          id: page_size
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1817-L1818
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
  outl_chunk_data:
    seq:
      - id: line_id
        type: u4
      - if: _root.version >= 1300
        type: seek
        repeat: until
        repeat-until: _.id == 1
      - id: line_type
        type: u2
      - id: caps_type
        type: u2
      - id: join_type
        type: u2
      - id: unknown1
        if: _root.version < 1300 and _root.version >= 600
        size: 2
      - id: line_width
        type: coord
      - id: stretch_raw
        type: u2
      - id: unknown2
        if: _root.version >= 600
        size: 2
      - id: angle
        type: angle
      - id: unknown3
        size: '_root.version >= 1300 ? 46 : _root.version >= 600 ? 52 : 0'
      - id: color
        type: color
      - id: unknown4
        size: '_root.version < 600 ? 10 : 16'
      - id: num_dash_raw
        type: u2
      - size: 0
        if: ofs_dashes < 0
      - id: unknown5
        size: '_root.version < 600 ? 20 : 22'
      - id: start_marker_id
        type: u4
      - id: end_marker_id
        type: u4
    instances:
      num_dash:
        value: 'num_dash_raw > (_io.size - _io.pos) / 2 ? (_io.size - _io.pos) / 2 : num_dash_raw'
      ofs_dashes:
        value: _io.pos
      dashes:
        pos: ofs_dashes
        type: u2
        repeat: expr
        repeat-expr: num_dash
        # size: num_dash
    types:
      seek:
        seq:
          - id: id
            type: u4
          - id: lngth
            type: u4
          - id: unknown
            if: id != 1
            size: lngth

  fild_chunk_data:
    seq:
      - id: fill_id
        type: u4
      - id: unknown
        if: _root.version >= 1300
        size: 8
      - id: fill_type
        type: u2
      - type:
          switch-on: fill_type
          cases:
            1: solid
            2: gradient
            7: pattern
            9: bitmap
            10: full_color
            11: texture
            _: not_supported
    types:
      solid:
        seq:
          - id: unknown
            size: '_root.version >= 1300 ? 13 : 2'
          - id: color1
            type: color
      gradient:
        seq:
          - id: unknown1
            size: '_root.version >= 1300 ? 8 : 2'
          - id: type
            type: u1
          - id: unknown2
            size: '_root.version >= 1300 ? 17 : _root.version >= 600 ? 19 : 11'
          - id: edge_offset_16_bit
            if: '_root.version >= 1300 or _root.version < 600'
            type: s2
          - id: edge_offset_32_bit
            if: '_root.version < 1300 and _root.version >= 600'
            type: s4
          - id: angle
            type: angle
          - id: center_x_offset
            type:
              switch-on: _root.precision_16bit
              cases:
                true: s2
                _: s4
          - id: center_y_offset
            type:
              switch-on: _root.precision_16bit
              cases:
                true: s2
                _: s4
          - id: unknown3
            if: _root.version >= 600
            size: 2
          - id: mode_raw
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
          - id: mid_point_raw
            type: u1
          - id: unknown4
            size: 1
          - id: num_stops_raw
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
          - id: unknown5
            if: _root.version >= 1300
            size: 3
          - type: stops
            repeat: expr
            repeat-expr: num_stops
        types:
          stops:
            seq:
              - id: unknown1
                size: '_root.version >= 1400 ? 26 : _root.version >= 1300 ? 5 : 0'
              - id: offset_raw
                type:
                  switch-on: _root.precision_16bit
                  cases:
                    true: u2
                    _: u4
              - id: unknown2
                if: _root.version >= 1300
                size: 3
            instances:
              offset:
                value: '(offset_raw & 0xffff) / 100.0'
        instances:
          mode:
            value: 'mode_raw & 0xff'
          mid_point:
            value: mid_point_raw / 100.0
          num_stops:
            value: 'num_stops_raw & 0xffff'
      pattern:
        seq:
          - id: unknown1
            size: '_root.version >= 1300 ? 8 : 2'
          - id: pattern_id
            type: u4
          - id: tmp_width
            type:
              switch-on: _root.precision_16bit
              cases:
                true: s2
                _: s4
          - id: tmp_height
            type:
              switch-on: _root.precision_16bit
              cases:
                true: s2
                _: s4
          - id: tile_offset_x_raw
            if: _root.version < 900
            type: u2
          - id: tile_offset_y_raw
            if: _root.version < 900
            type: u2
          - id: unknown2
            if: _root.version >= 900
            size: 4
          - id: rcp_offset_raw
            type: u2
          - id: flags
            type: u1
          - id: unknown3
            size: '_root.version >= 1300 ? 6 : 1'
          - id: color1
            type: color
          - id: unknown4
            size: '_root.version >= 1600 ? 31 : _root.version >= 1300 ? 10 : 0'
          - id: color2
            type: color
        instances:
          tile_offset_x:
            value: '_root.version < 900 ? (tile_offset_x_raw / 100.0) : 0.0'
          tile_offset_y:
            value: '_root.version < 900 ? (tile_offset_y_raw / 100.0) : 0.0'
          rcp_offset:
            value: 'rcp_offset_raw / 100.0'
          pattern_width:
            value: >-
              ((flags & 0x04) != 0) and (_root.version < 900)
                ? tmp_width / 100.0
                  : tmp_width / (_root.version < 600 ? 1000.0 : 254000.0)
          pattern_height:
            value: >-
              ((flags & 0x04) != 0) and (_root.version < 900)
                ? tmp_height / 100.0
                  : tmp_height / (_root.version < 600 ? 1000.0 : 254000.0)
          is_relative:
            value: '((flags & 0x04) != 0) and (_root.version < 900) ? true : false'
      bitmap:
        seq:
          - type: image_fill_data
        instances:
          fill_type_bitmap:
            value: '_root.version < 600 ? 10 : _parent.fill_type'
      full_color:
        seq:
          - type: image_fill_data
      texture:
        seq:
          - type: image_fill_data
            if: _root.version >= 600
          - type: image_fill_data_old
            if: _root.version < 600
        types:
          image_fill_data_old:
            seq:
              - id: unknown1
                size: 2
              - id: pattern_id
                type: u4
            instances:
              pattern_width:
                value: 1.0
              pattern_height:
                value: 1.0
              is_relative:
                value: true
              tile_ooffset_x:
                value: 0.0
              tile_offset_y:
                value: 0.0
              rcp_offset:
                value: 0.0
              flags:
                value: 0
        instances:
          fill_type_texture:
            value: '_root.version < 600 ? 10 : _parent.fill_type'
      image_fill_data:
        seq:
          - type: skip_x3_optional
            if: _root.version >= 1300
          - id: unknown1
            if: _root.version < 1300
            size: 2
          - id: pattern_id_raw1
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
          - id: tmp_width
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
          - id: tmp_height
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
          - id: tile_offset_x_raw
            if: _root.version < 900
            type: u2
          - id: tile_offset_y_raw
            if: _root.version < 900
            type: u2
          - id: unknown2
            if: _root.version >= 900
            size: 4
          - id: rcp_offset_raw
            type: u2
          - id: flags
            type: u1
          - id: unknown3
            size: '_root.version >= 1300 ? 17 : 21'
          - id: pattern_id_raw2
            if: _root.version >= 600
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
        instances:
          tile_offset_x:
            value: '_root.version < 900 ? (tile_offset_x_raw / 100.0) : 0.0'
          tile_offset_y:
            value: '_root.version < 900 ? (tile_offset_y_raw / 100.0) : 0.0'
          rcp_offset:
            value: 'rcp_offset_raw / 100.0'
          pattern_width:
            value: >-
              ((flags & 0x04) != 0) and (_root.version < 900)
                ? tmp_width / 100.0
                  : tmp_width / (_root.version < 600 ? 1000.0 : 254000.0)
          pattern_height:
            value: >-
              ((flags & 0x04) != 0) and (_root.version < 900)
                ? tmp_height / 100.0
                  : tmp_height / (_root.version < 600 ? 1000.0 : 254000.0)
          is_relative:
            value: '((flags & 0x04) != 0) and (_root.version < 900) ? true : false'
          pattern_id:
            value: '_root.version >= 600 ? pattern_id_raw2 : pattern_id_raw1'
      skip_x3_optional:
        seq:
          - type: skip
            repeat: until
            repeat-until: _.go_out
        types:
          skip:
            seq:
              - id: length
                if: lookahead == 0x640
                type: u4
              - id: unknown1
                if: lookahead == 0x640
                size: length
              - id: unknown2
                if: lookahead == 0x514
                size: 4
            instances:
              go_out:
                value: 'lookahead != 0x640 and lookahead != 0x514'
              lookahead:
                pos: _io.pos
                type: u4
  arrw_chunk_data: {}
  flgs_chunk_data: {}
  mcfg_chunk_data:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2190
    # mostly reverse-engineered from generated files using CorelDRAW 9
    seq:
      - id: unknown0
        size: len_unknown0
      - id: old_page_size
        if: v < 400
        type: old_page_size
      - id: page_size
        if: v >= 400
        type: page_size
      # FIXME: starting from here, the positions are completely off in newer CDR
      # versions (so it's obviously reading garbage), there's probably some
      # unknown data to skip
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
    doc: |
      A pool of `u4` chunk sizes, repeating until the end of stream. Once you
      know the index into this pool, you would parse a `u4` integer at offset
      `chunk_size_idx * sizeof<u4>` in the `_io` substream of this type.

      Previously, this type looked like this:

      ```ksy
      seq:
        - id: sizes
          type: u4
          repeat: eos
      ````

      and one would access the size as `sizes[chunk_size_idx]`. However, this
      caused major issues e.g. when trying to dump all parsed data to JSON,
      because the entire array of sizes was copied into each chunk in the dump,
      since it had to be passed to all chunks as a parameter.

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
  angle:
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
            3.14159265358979323846 * raw / 1800.0 :
            3.14159265358979323846 * raw / 180000000.0
    -webide-representation: "{value:dec}"
  color:
    seq:
      - id: color_new_version
        if: _root.version >= 500
        type: color_newest
      - id: color_middle_version
        if: _root.version >= 400 and _root.version < 500
        type: color_middle
      - id: color_old_verison
        if: _root.version < 400
        type: color_old
    types:
      color_newest:
        seq:
          - id: color_model_raw
            type: u2
          - id: color_palette_raw
            if: 'color_model_raw != 0x1e'
            type: u2
          - id: unknown
            if: 'color_model_raw != 0x1e'
            size: 4
        instances:
          color_model:
            value: >-
                    (_root.version >= 1300 and color_model_raw == 0x01)
                      ? 0x19
                        : color_model_raw == 0x1e ? 0x19 : color_model_raw
          color_palette:
            value: >-
                    color_model_raw == 0x1e
                      ? 0x1e : color_palette_raw
      color_middle:
        seq:
          - id: color_model
            type: u2
          - id: c
            type: u2
          - id: m
            type: u2
          - id: y
            type: u2
          - id: k
            type: u2
          - id: unknown
            size: 2
      color_old:
        seq:
          - id: color_model
            type: u1
          - id: color_value
            type: u4
  not_supported: {}
