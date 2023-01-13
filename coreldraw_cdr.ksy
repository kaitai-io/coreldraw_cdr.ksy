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
  bit-endian: le
doc: |
  A native file format of CorelDRAW.

  Some test files (but only old CDR versions, the latest ones are X3 and
  CorelDRAW X3 was released in 2006) are available here:
  <https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/testing%20base/>

doc-ref:
  - https://github.com/LibreOffice/libcdr/tree/master/src/lib

  # better not rely on it, much simpler and dumber than libcdr
  - https://github.com/sk1project/uniconvertor/tree/master/src/uc2/formats/cdr

  # incomplete, but specifies some chunks not found elsewhere
  - https://sourceforge.net/p/uniconvertor/code/HEAD/tree/formats/CDR/cdr_explorer/src/chunks.py

  # code isn't interesting, but there is a comment documenting previously
  # unknown chunks and mapping them to
  # https://community.coreldraw.com/sdk/api/draw equivalents
  - https://lists.inkscape.org/hyperkitty/list/inkscape-devel@lists.inkscape.org/message/JQYOMLQFCDEDHVDWZ5WDM7QBDFUFJXVD/attachment/2/cdr2svg.py.bz2

  # it might be a good idea to explore the official CorelDRAW API (and maybe
  # even play with it and generate various sample files), because it's very
  # likely that the properties available via the API will be projected into the
  # resulting .cdr file (and reverse enginnering of generated .cdr files is
  # easier when you know what to look for)
  - https://community.coreldraw.com/sdk/api/draw

  # focuses on CDR 4.0 only (which is a really old version), but many things
  # remained the same for the new versions, so it may also help reveal something
  - https://github.com/KDE/calligra/tree/filters-karbon-cdr/filters/karbon/cdr

  # incomplete, for basic overview only
  - https://github.com/photopea/CDR-specification
params:
  - id: streams
    type: io[]
seq:
  - id: riff_chunk
    type: riff_chunk_type
instances:
  version:
    value: riff_chunk.body.version
    # value: >-
    #   riff_chunk.body.chunks.chunks[0].chunk_id == 'vrsn'
    #     ? riff_chunk.body.chunks.chunks[0].body.as<vrsn_chunk_data>.version
    #     : riff_chunk.body.version
  precision_16bit:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2415-L2418
    value: _root.version < 600
types:
  riff_chunk_type:
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
  chunks_normal:
    # Defined this type to be consistent with the inconsistent `cmpr` chunk
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
        type: chunks_normal
        size-eos: true
    instances:
      version:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L38-L49
        value: >-
          c == 0x20
            ? 300 :
          c < 0x31
            ? 0 :
          c < 0x3a
            ? 100 * (c - 0x30) :
          c < 0x41
            ? 0 :
          c < 0x49
            ? 100 * (c - 0x37) :
          c == 0x49
            ? 0
            : 100 * (c - 0x38)
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
      body_external:
        io: _root.streams[stream_number.as<s4>]
        pos: ofs_body_external.as<u4>
        size: len_body
        type: chunk_body
        if: is_body_external
      len_body:
        value: 'has_redir_data ? len_body_redir.as<u4> : _io.size'
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
            _: chunk_data_common(_parent._parent.chunk_id)
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
            _: chunk_data_common(chunk_id)
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
  chunk_data_common:
    params:
      - id: chunk_id
        type: str
    seq:
      - id: body
        size-eos: true
        type:
          switch-on: chunk_id
          cases:
            '"DISP"': disp_chunk_data
            '"loda"': loda_chunk_data
            '"lobj"': loda_chunk_data
            '"fver"': fver_chunk_data
            '"vrsn"': vrsn_chunk_data
            '"trfd"': trfd_chunk_data
            '"outl"': outl_chunk_data
            '"fild"': fild_chunk_data # since CDR 700: `_root.version >= 700`
            '"fill"': fild_chunk_data # before CDR 700: `_root.version < 700`
            # '"arrw"': arrw_chunk_data
            '"flgs"': flgs_chunk_data
            # '"ptrt"': ptrt_chunk_data
            '"usdn"': usdn_chunk_data
            '"mcfg"': mcfg_chunk_data
            '"bmp "': bmp_chunk_data
            # '"bmpf"': bmpf_chunk_data
            # '"ppdt"': ppdt_chunk_data
            # '"ftil"': ftil_chunk_data
            # '"iccd"': iccd_chunk_data
            '"bbox"': bbox_chunk_data
            '"obbx"': obbx_chunk_data
            '"spnd"': spnd_chunk_data
            '"uidr"': uidr_chunk_data
            # '"vpat"': vpat_chunk_data
            '"font"': font_chunk_data
            '"stlt"': stlt_chunk_data
            '"txsm"': txsm_chunk_data
            '"urls"': urls_chunk_data
            # '"udta"': udta_chunk_data
            # '"styd"': styd_chunk_data

  fver_chunk_data:
    seq:
      - id: full_version
        type: u2
        doc: e.g. `1800` - same as `_root.riff_chunk.body.version` or `<vrsn_chunk_data>.version`
      - id: version_patch
        type: u2
        doc: seems to be always `1`
      - id: version_minor
        type: u2
        doc: seems to be always `0`
      - id: version_major
        type: u2
        doc: e.g. `18` for a CDR 18.0
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
          switch-on: 'form_type == "stlt" and _root.version < 700 ? "" : form_type'
          cases:
            '"cmpr"': cmpr_special_chunk
            '"stlt"': stlt_chunk_data
            _: chunks_normal
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
          switch-on: 'form_type == "stlt" and _root.version < 700 ? "" : form_type'
          cases:
            '"stlt"': stlt_chunk_data
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
        enum: chunk_types
      arg_offsets:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1751-L1753
        pos: start_of_args
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        repeat: expr
        repeat-expr: num_of_args + 1
      arg_types:
        doc: in reverse order against arg_offsets (arg_offsets[0] corresponds to arg_types[num_of_args - 1] and vice versa)
        doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1754-L1756
        pos: start_of_arg_types
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        repeat: expr
        repeat-expr: num_of_args
      args:
        type: 'arg(arg_offsets[_index], arg_offsets[_index + 1] - arg_offsets[_index], arg_types[(num_of_args.as<s4> - 1) - _index])'
        repeat: expr
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
          - id: ofs_body
            type: u4
          - id: len_body
            type: u4
          - id: type_raw
            type: u4
        instances:
          # not using an enum parameter to achieve better experience in the Web IDE
          type:
            value: type_raw
            enum: arg_type
          body:
            pos: ofs_body
            size: len_body
            type:
              switch-on: type
              cases:
                'arg_type::loda_coords': loda_coords
                'arg_type::fill_style': fill_style
                'arg_type::line_style': line_style
                'arg_type::style': style
                'arg_type::name': name
                'arg_type::polygon_transform': polygon_transform
                'arg_type::opacity': opacity
                'arg_type::page_size': page_size
                'arg_type::guid_layer': guid

      loda_coords:
        seq:
          - id: chunk
            type:
              switch-on: _parent._parent.chunk_type
              cases:
                'chunk_types::spline': spline
                'chunk_types::rectangle': rectangle
                'chunk_types::ellipse': ellipse
                'chunk_types::line_and_curve': line_and_curve
                'chunk_types::path': path
                'chunk_types::artistic_text': artistic_text
                'chunk_types::bitmap': bitmap
                'chunk_types::paragraph_text': paragraph_text
                'chunk_types::polygon_coords': polygon_coords

      fill_style:
        seq:
          - id: waldo
            type: waldo_fill
            if: _root.version < 400
          - id: fill_id
            type: u4
            if: _root.version >= 400
        types:
          waldo_fill:
            seq:
              - id: fill_type
                type: u1
              - id: style
                type:
                  switch-on: fill_type
                  cases:
                    1: solid
                    2: gradient # linear gradient
                    4: gradient # radial gradient
                    7: pattern
                    10: full_color
            types:
              solid:
                seq:
                  - id: color
                    type: color
              pattern:
                seq:
                  - id: pattern_id
                    type:
                      switch-on: _root.version < 300
                      cases:
                        true: u2
                        _: u4
                  - id: data
                    type: pattern_data
                  - id: color1
                    type: color
                  - id: color2
                    type: color
              full_color:
                seq:
                  - id: pattern_id
                    type: u2
                  - id: data
                    type: pattern_data
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
                        true: s2
                        _: s4
                  - id: center_y_offset
                    if: _root.version >= 200
                    type:
                      switch-on: _root.precision_16bit
                      cases:
                        true: s2
                        _: s4
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
          - id: waldo
            type: waldo_outl
            if: _root.version < 400
          - id: outl_id
            type: u4
            if: _root.version >= 400
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
              - id: num_dashes
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
                repeat-expr: num_dashes
      style:
        seq:
          - id: style_id
            type:
              switch-on: _root.precision_16bit
              cases:
                true: u2
                _: u4
      name:
        doc-ref: https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l305
        seq:
          - id: value_old
            size-eos: true
            type: strz
             # not accurate, but best we can do here (in fact, it reflects the
             # https://en.wikipedia.org/wiki/Windows_code_page#ANSI_code_page
             # based on the currently set system locale, at least on Windows)
            encoding: windows-1252
            if: _root.version < 1200
          - id: value_new
            size-eos: true
            # FIXME: should be `type: strz` but Kaitai Struct doesn't support it for
            # UTF-16 yet, see https://github.com/kaitai-io/kaitai_struct/issues/187
            type: str
            encoding: UTF-16LE
            if: _root.version >= 1200
        instances:
          value:
            # a poor man's workaround for `value_new` not being properly parsed
            # as null-terminated (but I believe this actually works fine for
            # .cdr files generated by CorelDRAW)
            value: |
              _root.version >= 1200 ? (
                value_new.substring(value_new.length - 1, value_new.length) == [0x00, 0x00].to_s('UTF-16LE')
                  ? value_new.substring(0, value_new.length - 1)
                  : value_new
              ) : value_old

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
            size: '_root.version < 1300 ? 10 : 14'
          - id: value_raw
            type: u2
        instances:
          value:
            value: value_raw / 1000.0
      page_size:
        seq:
          - id: width
            type: coord
          - id: height
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
            value: 'cx < 0 ? -cx : cx'
          ry:
            value: 'cy < 0 ? -cy : cy'
          pie:
            value: pie_raw != 0
      line_and_curve:
        seq:
          - id: num_points_raw
            type: u4
          - id: points
            type: points_list(num_points_raw)
      path:
        seq:
          - id: unknown1
            size: 4
          - id: num_points_raw1
            type: u2
          - id: num_points_raw2
            type: u2
          - id: unknown2
            size: 16
          - id: points
            type: points_list((num_points_raw1 + num_points_raw2).as<u4>)
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
                  _root.version < 400 ? 8
                    : _root.version >= 800 and _root.version < 900 ? 12
                      : 20
          - id: num_points_raw
            type: u4
          - id: points
            type: points_list(num_points_raw)
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
          - id: num_points_raw
            type: u4
          - id: points
            type: points_list(num_points_raw)
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
        2000:
          id: palt
          doc-ref: https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_const.py#L42
        8000: opacity
        8005:
          id: contnr
          doc-ref: https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l486
        11000: polygon_transform
        12010:
          id: gradient
          doc-ref: https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_const.py#L46
        12030:
          id: rotate
          doc-ref: https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l485
        19130:
          id: page_size
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1817-L1818
        40050:
          id: guid_layer
          doc-ref: |
            randomly generated for each layer (in fact, if you create two
            identical empty CorelDRAW documents using the same steps and save
            them into different .cdr files, these GUIDs would likely be the only
            thing in which these .cdr files differ, and is also the reason why
            they don't have exactly the same file size due to compression), in
            particular for the "Guides", "Desktop" and "Document Grid" layers in
            the master page which are then referenced in content pages via the
            same GUID
      chunk_types:
        0x01: rectangle
        0x02: ellipse
        0x03: line_and_curve
        0x04: artistic_text
        0x05: bitmap
        0x06: paragraph_text
        0x14: polygon_coords
        0x25: path
        0x26: spline

  trfd_chunk_data:
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
    instances:
      arg_offsets:
        doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1336-L1338
        pos: start_of_args
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
        repeat: expr
        repeat-expr: num_of_args
      trafos:
        type: trafo_wrapper(arg_offsets[_index])
        repeat: expr
        repeat-expr: num_of_args
    types:
      trafo_wrapper:
        params:
          - id: offs
            type: u4
        instances:
          tmp_type:
            pos: 'offs + (_root.version >= 1300 ? 8 : 0)'
            type: u2
          is_trafo:
            value: tmp_type == 0x08 and _root.version >= 500
            doc: 'note: only supporting `_root.version >= 500` for now'
          body:
            pos: 'offs + (_root.version >= 1300 ? 8 : 0) + tmp_type._sizeof'
            type: trafo
            if: is_trafo
      trafo:
        doc: |
          See <https://developer.mozilla.org/en-US/docs/Web/CSS/transform-function/matrix#syntax>
          for an explanation of matrix parameter labels.
        doc-ref: https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_utils.py#L29
        seq:
          - id: unknown1
            if: _root.version >= 600
            size: 6
          - id: a
            -orig-id: m11 # UniConvertor
            type: f8
          - id: c
            -orig-id: m12 # UniConvertor
            type: f8
          - id: tx_raw
            type: f8
          - id: b
            -orig-id: m21 # UniConvertor
            type: f8
          - id: d
            -orig-id: m22 # UniConvertor
            type: f8
          - id: ty_raw
            type: f8
        instances:
          tx:
            value: 'tx_raw / (_root.version < 600 ? 1000.0 : 254000.0)'
          ty:
            value: 'ty_raw / (_root.version < 600 ? 1000.0 : 254000.0)'

  outl_chunk_data:
    seq:
      - id: outl_id
        type: u4
      - id: skips
        if: _root.version >= 1300
        type: skip
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
        size: |
          _root.version >= 1300 ? 46
            : _root.version >= 600 ? 52
              : 0
      - id: color
        type: color
      - id: unknown4
        size: '_root.version < 600 ? 10 : 16'
      - id: num_dashes_raw
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
      ofs_dashes:
        value: _io.pos
      dashes:
        pos: ofs_dashes
        type: u2
        repeat: expr
        repeat-expr: num_dashes
      num_dashes:
        value: 'num_dashes_raw <= num_dashes_max ? num_dashes_raw : num_dashes_max'
      num_dashes_max:
        value: (_io.size - _io.pos) / sizeof<u2>
      stretch:
        value: stretch_raw / 100.0
    types:
      skip:
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
      - id: since_version
        type: u4
        valid: 1300
        if: _root.version >= 1300
      - id: len_body
        type: u4
        valid:
          min: fill_type._sizeof
        if: _root.version >= 1300
      - id: fill_type
        type: u2
        enum: fill_types
      - id: fill
        size: '_root.version >= 1300 ? len_body.as<u4> - fill_type._sizeof : _io.size - _io.pos'
        type:
          switch-on: fill_type
          cases:
            fill_types::uniform: solid
            fill_types::fountain: gradient
            # 7: pattern
            # 9: image_fill_data # bitmap
            # 10: image_fill_data # full color
            # 11: texture
      - id: fild_rest
        size-eos: true
        valid:
          any-of:
            - '[].as<bytes>'
            - '[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]'

    enums:
      # CorelDRAW 7: PROGRAMS/DRAW_SCR.HLP 'GetFillType'
      # CorelDRAW 9: Programs/Draw_scr.hlp 'GetFillType'
      # ~~CorelDRAW 10: Programs/DRAW10VBA.HLP 'cdrFillType'~~: WRONG!
      #    -> those are not the values that actually get stored in .cdr files,
      #       even new versions (tested in CorelDRAW X7) use the "old" values
      # ~~<https://community.coreldraw.com/sdk/api/draw/17/e/cdrfilltype>~~: WRONG as well!
      fill_types:
        0:
          id: none
          -orig-id: DRAW_FILL_NONE # CorelDRAW 9: Draw/Scripts/Scripts/drwconst.csi
        1:
          id: uniform
          -orig-id: DRAW_FILL_UNIFORM
        2:
          id: fountain
          -orig-id: DRAW_FILL_FOUNTAIN
        6:
          id: postscript
          -orig-id: DRAW_FILL_POSTSCRIPT
        7:
          id: two_color_i7
          -orig-id: DRAW_FILL_TWO_COLOR
          doc: |
            used in older versions of CorelDRAW (e.g. CorelDRAW 10)
        8:
          id: two_color_i8
          doc: |
            used for newly applied "Two-color pattern fill" in recent versions
            of CorelDRAW (e.g. CorelDRAW X7)
        9:
          id: color_bitmap
          -orig-id: DRAW_FILL_COLOR_BITMAP
        10:
          id: vector
          -orig-id: DRAW_FILL_COLOR_VECTOR
        11:
          id: texture
          -orig-id: DRAW_FILL_COLOR_TEXTURE

    types:
      solid:
        seq:
          - id: unknown1
            size: 2
            if: _root.version < 1300
          - id: since_version
            type: u4
            valid: 1300
            if: _root.version >= 1300
          - id: len_properties
            type: u4
            if: _root.version >= 1300
          - id: properties
            size: '_root.version >= 1300 ? len_properties.as<u4> : _io.size - _io.pos'
            type: property_list
          - id: solid_rest
            size-eos: true
            valid:
              any-of:
                - '[].as<bytes>'
                - '[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]'
        types:
          property_list:
            seq:
              - id: color_old
                type: color
                if: _root.version < 1300
              - id: items
                type: property
                repeat: until
                repeat-until: _.type == property_type::end
                if: _root.version >= 1300
              - id: unknown1
                type: u2
                valid:
                  any-of:
                    - 0 # usual value
                    - 36 # CorelDRAW 7: TUTORS/DRAW/FISHEYE.CDR
                    - 127 # sample '22.cdr'
              - id: unknown_id
                size: 2
                if: _root.version >= 600
              - id: overprint_raw
                type:
                  switch-on: _root.precision_16bit
                  cases:
                    true: u2
                    _: u4
                valid:
                  any-of:
                    - 0
                    - 1 # CorelDRAW 7: DRAW/SAMPLES/{7EFFECTS.CDR,CAMERA.CDR}, CorelDRAW 8: DRAW/SAMPLES/CAMERA.CDR
                    - 13 # CorelDRAW 7: TUTORS/DRAW/FISHEYE.CDR
                doc: |
                  see <https://community.coreldraw.com/talk/coreldraw_graphics_suite_x5/f/coreldraw-x5/37492/coreldraw-x5-icons-inside-color-indicator-what-do-they-mean>
                  for how this is displayed in CorelDRAW
              - id: unknown_angle
                type: angle
                valid:
                  expr: |
                    _.value_deg == 45.0
                    or _.value_deg == 10.0
                    or _.value_deg == 0.0
                    or _.value_deg == 0.0001
                doc: |
                  seen values:

                  * 45.0 - usual value (by far the most common),
                  * 10.0 - CorelDRAW 7: DRAW/SAMPLES/WISHLIST.CDR,
                  * 0.0:
                    - CorelDRAW 7: DRAW/SAMPLES/CAMERA.CDR
                    - CorelDRAW 8: DRAW/SAMPLES/{CAMERA.CDR,DRAW QUICK REF.CDR}
                    - CorelDRAW 8: TUTORS/DRAW/HTMLDOCS/HTMLPICS/{CALENDAR.CDR,DRTUT5_COLOR_STYLES.CDR}
                    - CorelDRAW 9: Draw/Samples/Layout.cdr
                    - CorelDRAW 11: Draw/Samples/Sample1.cdr
                  * 0.0001 (`64 00 00 00` or 100 raw) - CorelDRAW 7: TUTORS/DRAW/FISHEYE.CDR
              - id: unknown4
                type: u4
                valid:
                  any-of:
                    - 60 # usual value
                    - 0
                    - 100 # CorelDRAW 7: DRAW/SAMPLES/COLORSTY/*.CDR (not all, but 45 out of 85 files)
                    - 44 # CorelDRAW 7: TUTORS/DRAW/FISHEYE.CDR
            instances:
              overprint:
                value: overprint_raw != 0

          property:
            seq:
              - id: type
                type: u1
                enum: property_type
              - id: len_body
                type: u4
                valid:
                  eq: |
                    type == property_type::color
                      ? 12 :
                    type == property_type::palette_guid
                      ? 16 :
                    type == property_type::end
                      ? 0 :
                      len_body
              - id: body
                size: len_body
                type:
                  switch-on: type
                  cases:
                    property_type::color: color
                    property_type::special_palette_color_lab: color
                    property_type::palette_guid: guid
                    property_type::special_palette_color_part1: special_palette_color_part1
                    property_type::special_palette_color_part2: special_palette_color_part2
                    property_type::special_palette_color_id: palette_color_id
                    property_type::special_palette_color_name: palette_color_name
                if: type != property_type::end
          palette_color_id:
            seq:
              - id: id
                type: u2
              - id: rest
                size-eos: true
                valid:
                  eq: '[].as<bytes>'
          palette_color_name:
            seq:
              - id: name
                type: color_name
              - id: rest
                size-eos: true
                valid:
                  eq: '[].as<bytes>'
          special_palette_color_part1:
            seq:
              - id: palette_guid
                type: guid
              - id: name
                type: color_name
              - id: special_pal_p1_rest
                size-eos: true
          special_palette_color_part2:
            seq:
              # this `name_raw` is actually null-terminated, unlike the others
              - id: name_raw
                type: color_name
              - id: special_pal_p2_rest
                size-eos: true
            instances:
              name:
                # assumes `_root.version >= 1200`
                value: |
                  name_raw.name.substring(name_raw.name.length - 1, name_raw.name.length) == [0x00, 0x00].to_s('UTF-16LE')
                    ? name_raw.name.substring(0, name_raw.name.length - 1)
                    : name_raw.name
          color_name:
            seq:
              - id: char_len_name
                type: u4
              - id: name
                size: char_len_name * 2
                type: str
                encoding: UTF-16LE
        enums:
          property_type:
            0x00: end
            0x01: color
            0x03: special_palette_color_part2
            0x06:
              id: special_palette_color_lab
              doc: |
                in addition to the standard `property_type::color` which seems to be using
                `color_model::bgr_tint` (whenever found in the same solid fill as
                `property_type::special_palette_color_lab`), this property appears only
                for "special palette" colors (as all
                `property_type::special_palette_color_*` properties) and uses
                `color_model::lab_offset_128` (at least in samples I've seen).

                This kind of makes sense because RGB is a device-dependent color model,
                whereas L*a*b* (stored in this property) is device-independent (so it's
                not redundant to include both). The L*a*b* color also doesn't seem to be
                affected by the "Tint", whereas the `color_model::bgr_tint` color in
                `property_type::color` holds tint and factors the tint into the RGB value.
            0x07:
              id: palette_guid
              doc: |
                the set of used values is shared among colors and files (i.e. this GUID is
                *not* randomly generated, but reused), the most common are 16 zero bytes
                (`00000000-0000-0000-0000-000000000000`) which seem to be only used for
                `color_palette::user`, followed by the second most common
                `CB 19 CD CC 75 46 5E 4A 8B DA D0 BB BA AB 8A F0`
                (`cccd19cb-4675-4a5e-8bda-d0bbbaab8af0`; if you search for this GUID [on
                Google](https://www.google.com/search?q=cccd19cb-4675-4a5e-8bda-d0bbbaab8af0),
                you actually get some results, which is interesting) only used for
                `color_palette::user` colors using the CMYK color model
                (`color_model::cmyk100` or `color_model::cmyk255_i3`).

                You can also find `74 CD 6C FC A8 10 52 41 89 01 A5 1F AC B4 77 85`
                (`fc6ccd74-10a8-4152-8901-a51facb47785`) in a few sample files, only used
                for `color_model::spot` colors with `color_palette::pantone_coated`.
            0x08: special_palette_color_part1
            0x0b: special_palette_color_id
            0x0c: special_palette_color_name
      gradient:
        seq:
          - id: unknown1
            size: '_root.version >= 1300 ? 8 : 2'
          - id: type
            type: u1
          - id: unknown2
            size: |
              _root.version >= 1300 ? 17
                : _root.version >= 600 ? 19
                  : 11
          - id: edge_offset
            type:
              switch-on: _root.version >= 600 and _root.version < 1300
              cases:
                true: s4
                _: s2
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
          - id: stops
            type: stop
            repeat: expr
            repeat-expr: num_stops
          - id: unknown6
            size: 3
            if: _root.version >= 1300
          - id: trafo
            type: transformation
            # FIXME: `version >= 1600` may not be accurate due to a lack of available
            # sample files (but it's not present in 1500 and it is present in 1700)
            if: _root.version >= 1600 and (_io.size - _io.pos) >= sizeof<transformation>
        instances:
          mode:
            value: 'mode_raw & 0xff'
          mid_point:
            value: mid_point_raw / 100.0
          num_stops:
            value: 'num_stops_raw & 0xffff'
        types:
          stop:
            seq:
              # Byte size of one `stop` entry in each CDR version for which I
              # had sample files with gradients:
              #   CDR 500: 14
              #   CDR 600: 16
              #   CDR 1200: 16
              #   CDR 1300: 24 (analysis: `16 + 8 = 16 + (5 + 3)`)
              #   CDR 1400: 24
              #   CDR 1500: 45 (analysis: `16 + 29 = 16 + (26 + 3)`)
              #   CDR 2300: 45
              - size: 0
                if: ofs_start < 0
              - id: color
                type: color
              - id: unknown1
                # Note: in the libcdr code (see `doc-ref`), `26` has been used
                # already for `version >= 1400` (not `version >= 1500`), but
                # this does not match sample files with `version == 1400` (see
                # the above overview of `stop` sizes per CDR version)
                size: |
                  _root.version >= 1500 ? 26
                    : _root.version >= 1300 ? 5
                      : 0
                doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L1470-L1473
              - id: offset_raw
                type:
                  switch-on: _root.precision_16bit
                  cases:
                    true: u2
                    _: u4
              - id: unknown2
                if: _root.version >= 1300
                size: 3
              - size: 0
                valid:
                  expr: |
                    _io.pos - ofs_start == (
                      _root.version < 600 ? 14 :
                      [16, 24, 24, 45][
                        [
                          [0, (_root.version - 1200) / 100].max,
                          3
                        ].min
                      ]
                    )
            instances:
              ofs_start:
                value: _io.pos
              offset:
                value: '(offset_raw & 0xffff) / 100.0'
          transformation:
            seq:
              - id: offset_x_rel
                type: f8
                doc: horizontal offset of the fill center relative to the object center
              - id: offset_y_rel
                type: f8
                doc: vertical offset of the fill center relative to the object center
              - id: width_rel
                type: f8
                doc: width of the fill relative to the object width
              - id: height_rel
                type: f8
                doc: height of the fill relative to the object height
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
            size: |
              _root.version >= 1600 ? 31
                : _root.version >= 1300 ? 10
                  : 0
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
              is_relative
                ? tmp_width / 100.0
                : tmp_width / (_root.version < 600 ? 1000.0 : 254000.0)
          pattern_height:
            value: >-
              is_relative
                ? tmp_height / 100.0
                : tmp_height / (_root.version < 600 ? 1000.0 : 254000.0)
          is_relative:
            value: '((flags & 0x04) != 0) and (_root.version < 900)'
      texture:
        seq:
          - id: data
            type: image_fill_data
            if: _root.version >= 600
      image_fill_data:
        seq:
          - id: skip_x3
            type: skip_x3_optional
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
            valid: pattern_id_raw1
        instances:
          tile_offset_x:
            value: '_root.version < 900 ? (tile_offset_x_raw / 100.0) : 0.0'
          tile_offset_y:
            value: '_root.version < 900 ? (tile_offset_y_raw / 100.0) : 0.0'
          rcp_offset:
            value: 'rcp_offset_raw / 100.0'
          pattern_width:
            value: >-
              is_relative
                ? tmp_width / 100.0
                : tmp_width / (_root.version < 600 ? 1000.0 : 254000.0)
          pattern_height:
            value: >-
              is_relative
                ? tmp_height / 100.0
                : tmp_height / (_root.version < 600 ? 1000.0 : 254000.0)
          is_relative:
            value: '((flags & 0x04) != 0) and (_root.version < 900)'
          pattern_id:
            value: '_root.version >= 600 ? pattern_id_raw2 : pattern_id_raw1'
      skip_x3_optional:
        seq:
          - id: skips
            type: skip
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
                size: length.as<u4>
              - id: unknown2
                if: lookahead == 0x514
                size: 4
            instances:
              go_out:
                value: 'lookahead != 0x640 and lookahead != 0x514'
              lookahead:
                pos: _io.pos
                type: u4
  # arrw_chunk_data: {}
  flgs_chunk_data:
    seq:
      - id: flags
        size: 4
    instances:
      chunk_type:
        value: flags[3] & 0xff
        enum: chunk_types
      is_master_page:
        value: flags[2] != 0
        if: chunk_type == chunk_types::page
        doc: flags[2] is `0x00` or `0x01`
        doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRContentCollector.cpp#L195
      layer_type:
        value: flags[0] & 0xff
        enum: layer_types
        if: chunk_type == chunk_types::layer
    enums:
      # https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l490
      layer_types:
        0x00: layer
        0x08: desktop
        0x0a: guides
        0x1a: grid
      # https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l926
      chunk_types:
        0x08: object
        0x10: group
        0x90: page
        0x98: layer

  # ptrt_chunk_data:
  #   seq:
  #     - id: groups
  #       size: 4
  #       repeat: expr
  #       repeat-expr: 4

  usdn_chunk_data:
    doc: |
      'usdn' = *U*nique *S*tatic i*D*e*N*tifier (probably)
    seq:
      - id: static_id
        -orig-id:
          - CDRStaticID # CorelDRAW 10: "Tools > Object Data Manager"
          - StaticID # https://community.coreldraw.com/sdk/api/draw/17/p/shape.staticid
        type: u4
        doc: |
          CorelDRAW 10 displays this field under the name `CDRStaticID` in
          "Tools > Object Data Manager". In CorelDRAW X7, it is hidden (no
          longer visible in Object Data Manager) but still used, as explained at
          <https://product.corel.com/help/CorelDRAW/540223850/Main/EN/Documentation/wwhelp/wwhimpl/js/html/wwhelp.htm#href=CorelDRAW-Setting-up-the-project-database.html>:

          > By default, CorelDRAW creates four data fields: **Name**, **Cost**,
          **Comments**, and **CDRStaticID**. The first three fields can be
          edited or deleted as required. The **CDRStaticID** field is hidden; it
          is used by CorelDRAW to identify objects, and it can't be edited or
          deleted.

          At the moment I don't know exactly from which version of CorelDRAW it
          is hidden (just that it was visible in CorelDRAW 10 and hidden in X7)
          or if there is another place where it can be displayed in recent
          versions.

          Nevertheless, it's accessible to macros as `Shape.StaticID`:
          <https://community.coreldraw.com/sdk/api/draw/17/p/shape.staticid>
          (so you can at least write a simple macro to show it)

  mcfg_chunk_data:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/4b28c1a10f06e0a610d0a740b8a5839dcec9dae4/src/lib/CDRParser.cpp#L2190
    # mostly reverse-engineered from generated files using CorelDRAW 9
    seq:
      - id: unknown0
        size: len_unknown0
      - id: page_size_old
        if: v < 400
        type: old_page_size
      - id: page_size
        if: v >= 400
        type: new_page_size
      # # FIXME: starting from here, the positions are completely off in newer CDR
      # # versions (so it's obviously reading garbage), there's probably some
      # # unknown data to skip
      # - id: unknown1
      #   type: u2
      # - id: orientation
      #   type: u2
      #   enum: orientation
      # - id: unknown2
      #   size: 12
      # - id: show_page_border
      #   type: u2
      #   enum: boolean
      # - id: layout
      #   type: u2
      #   enum: layout
      # - id: facing_pages
      #   type: u2
      #   enum: boolean
      # - id: start_on
      #   type: u2
      #   enum: start_on
      # - id: offset_x
      #   type: coord
      # - id: offset_y
      #   type: coord
      # - id: grid_freq_horz
      #   type: f4
      # - id: grid_freq_vert
      #   type: f4
      # - id: unit_horz
      #   doc: Also the default drawing unit
      #   type: u2
      #   enum: unit
      # - id: unit_vert
      #   type: u2
      #   enum: unit
      # - id: unit_unknown
      #   doc: No idea what is this used for, cannot make different from `unit_horz`
      #   type: u2
      #   enum: unit
      # - id: scale_factor
      #   type: f4
      # - id: scale_unit
      #   type: u2
      #   enum: unit
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
        value: 'v < 400 ? (page_size_old.x1.value - page_size_old.x0.value) : page_size.width.value'
      height:
        value: 'v < 400 ? (page_size_old.y1.value - page_size_old.y0.value) : page_size.height.value'
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
      new_page_size:
        seq:
          - id: width
            type: coord
          - id: height
            type: coord
    # enums:
    #   orientation:
    #     0: portrait
    #     1: landscape
    #   layout:
    #     1: full_page
    #     2: book
    #     3: booklet
    #     4: tent
    #     5: side_folded_card
    #     6: top_folded_card
    #   boolean:
    #     0: false
    #     1: true
    #   start_on:
    #     0: right_side
    #     1: left_side
    #   unit:
    #     1: inch
    #     2: milimeter
    #     3: picas_point
    #     4: point
    #     5: centimeter
    #     6: pixel
    #     7: feet
    #     8: mile
    #     9: meter
    #     10: kilometer
    #     12: ciceros_didot
    #     13: didot
    #     16: yard
  bmp_chunk_data:
    seq:
      - id: image_id
        type:
          switch-on: _root.precision_16bit
          cases:
            true: u2
            _: u4
      - size: '_root.version < 600 ? 14 : _root.version < 700 ? 46 : 50'
      - id: color_model
        type: u4
      - size: 4
      - id: width
        type: u4
      - id: height
        type: u4
      - size: 4
      - id: bpp
        type: u4
      - size: 4
      - id: bmp_size
        type: u4
      - size: 32
      - id: palette
        if: 'bpp < 24 and color_model != 5 and color_model != 6'
        type: palette_type
      - id: bitmap
        size: bmp_size
    types:
      palette_type:
        seq:
          - id: unknown
            size: 2
          - id: num_colors_raw
            type: u2
          - id: colors
            type: color_rgb
            repeat: expr
            repeat-expr: num_colors
        instances:
          num_colors:
            value: 'num_colors_raw <= num_colors_max ? num_colors_raw : num_colors_max'
          num_colors_max:
            value: '(_io.size - _io.pos) / sizeof<color_rgb>'
        types:
          color_rgb:
            seq:
              - id: b
                type: u1
              - id: g
                type: u1
              - id: r
                type: u1
            instances:
              color_value:
                 value: 'b | (g << 8) | (r << 16)'

  # bmpf_chunk_data: {}
  # ppdt_chunk_data: {}
  # ftil_chunk_data: {}
  # iccd_chunk_data: {}
  bbox_chunk_data:
    doc: |
      bounding box -
      [Shape.GetBoundingBox(,False)](https://community.coreldraw.com/sdk/api/draw/17/m/shape.getboundingbox)
    doc-ref: https://lists.inkscape.org/hyperkitty/list/inkscape-devel@lists.inkscape.org/message/JQYOMLQFCDEDHVDWZ5WDM7QBDFUFJXVD/attachment/2/cdr2svg.py.bz2
    seq:
      - id: p0_x
        type: coord
      - id: p0_y
        type: coord
      - id: p1_x
        type: coord
      - id: p1_y
        type: coord
  obbx_chunk_data:
    doc: |
      outline bounding box -
      [Shape.GetBoundingBox(,True)](https://community.coreldraw.com/sdk/api/draw/17/m/shape.getboundingbox)
    doc-ref: https://lists.inkscape.org/hyperkitty/list/inkscape-devel@lists.inkscape.org/message/JQYOMLQFCDEDHVDWZ5WDM7QBDFUFJXVD/attachment/2/cdr2svg.py.bz2
    seq:
      - id: p0_x
        type: coord
      - id: p0_y
        type: coord
      - id: p1_x
        type: coord
      - id: p1_y
        type: coord

      - id: p2_x
        type: coord
      - id: p2_y
        type: coord
      - id: p3_x
        type: coord
      - id: p3_y
        type: coord
  spnd_chunk_data:
    seq:
      - id: spnd
        type: u4
  uidr_chunk_data:
    seq:
      - id: color_id
        type: u4
      - id: user_id
        type: u4
      - id: unknown1
        size: 36
      - id: color
        type: color
  # vpat_chunk_data: {}
  font_chunk_data:
    seq:
      - id: font_id
        type: u2
      - id: font_encoding
        type: u2
        enum: text_encoding
      - size: 14
      - id: font_name
        size-eos: true
  stlt_chunk_data:
    doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L2194
    seq:
      - id: num_records
        type: u4
      - id: mapping_section
        type: mappings
        if: num_records != 0
      - id: records
        type: record
        repeat: expr
        repeat-expr: num_records
    types:
      mappings:
        seq:
          - id: num_fills_raw
            type: u4
          - id: fills
            size: fill_size
            type: entry
            repeat: expr
            repeat-expr: num_fills

          - id: num_outls_raw
            type: u4
          - id: outls
            type: entry
            repeat: expr
            repeat-expr: num_outls

          - id: num_fonts_raw
            type: u4
          - id: fonts
            type: font
            repeat: expr
            repeat-expr: num_fonts

          - id: num_aligns_raw
            type: u4
          - id: aligns
            type: entry
            repeat: expr
            repeat-expr: num_aligns

          - id: num_intervals
            type: u4
          - id: intervals
            type: interval
            repeat: expr
            repeat-expr: num_intervals

          - id: num_set5s
            type: u4
          - id: set5s_raw
            size: 152 * num_set5s

          - id: num_tabs
            type: u4
          - id: tabs_raw
            size: 784 * num_tabs

          - id: num_bullets
            type: u4
          - id: bullets
            type: bullet
            repeat: expr
            repeat-expr: num_bullets

          - id: num_indents_raw
            type: u4
          - id: indents
            type: indent
            repeat: expr
            repeat-expr: num_indents

          # NOTE: libcdr spells this "hypens" (see https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L2316),
          # but I can't find that spelling in any English dictionary
          - id: num_hyphens
            type: u4
          - id: hyphens_raw
            size: '(32 + (_root.version >= 1300 ? 4 : 0)) * num_hyphens'

          - id: num_dropcaps
            type: u4
          - id: dropcaps_raw
            size: 28 * num_dropcaps

          - id: num_set11s
            type: u4
            if: has_set11s
          - id: set11s_raw
            size: 12 * num_set11s.as<u4>
            if: has_set11s
        instances:
          num_fills:
            value: 'num_fills_raw <= num_fills_max ? num_fills_raw : num_fills_max'
          num_fills_max:
            value: '((_io.size - _io.pos) / fill_size).as<u4>'
          fill_size:
            value: 'sizeof<entry> + (_root.version >= 1300 ? 48 : 0)'

          num_outls:
            value: 'num_outls_raw <= num_outls_max ? num_outls_raw : num_outls_max'
          num_outls_max:
            value: '((_io.size - _io.pos) / sizeof<entry>).as<u4>'

          num_fonts:
            value: 'num_fonts_raw <= num_fonts_max ? num_fonts_raw : num_fonts_max'
          num_fonts_max:
            value: '((_io.size - _io.pos) / font_size).as<u4>'
          font_size:
            value: |
              sizeof<u4> +
              sizeof<u2> * 2 +
              8 +
              (_root.precision_16bit ? sizeof<s2> : sizeof<s4>) +
              (_root.version < 1000 ? 12 : 20) * 2

          num_aligns:
            value: 'num_aligns_raw <= num_aligns_max ? num_aligns_raw : num_aligns_max'
          num_aligns_max:
            value: '((_io.size - _io.pos) / sizeof<entry>).as<u4>'

          num_indents:
            value: 'num_indents_raw <= num_indents_max ? num_indents_raw : num_indents_max'
          num_indents_max:
            value: '((_io.size - _io.pos) / indent_size).as<u4>'
          indent_size:
            # NOTE: the original `indentSize` expression
            # (https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRParser.cpp#L2303)
            # is apparently incorrect - the `+ 12` is missing there
            value: 'sizeof<u4> + 12 + (_root.precision_16bit ? sizeof<s2> : sizeof<s4>) * 3'

          has_set11s:
            value: _root.version > 800
      entry:
        seq:
          - id: id
            type: u4
          - size: 4
          - id: value
            type: u4
      font:
        seq:
          - id: id
            type: u4
          - size: '_root.version < 1000 ? 12 : 20'
          - id: value
            type: u2
          - id: font_encoding
            type: u2
            enum: text_encoding
          - size: 8
          - id: font_size
            type: coord
          - size: 8
          - id: style_flags
            type: text_style_flags
          - size: 8
            if: '_root.version >= 1000'
      interval:
        seq:
          - id: id
            type: u4
          - size: 8
          - id: inter_char_spacing_raw
            type: u4
          - size: 8
          - id: inter_line_spacing_raw
            type: u4
          - size: 24
        instances:
          inter_line_spacing:
            value: 'inter_line_spacing_raw / 1000000.0'
          inter_char_spacing:
            value: 'inter_char_spacing_raw / 1000000.0'
      bullet:
        seq:
          - size: 40
          - size: 4
            if: _root.version > 1300

          - id: indicator_x3
            type: u4
            if: _root.version >= 1300
          - size: 'indicator_x3 != 0 ? 68 : 12'
            if: _root.version >= 1300

          - size: 20
            if: _root.version < 1300
          - size: 8
            if: _root.version < 1300 and _root.version >= 1000
          - id: indicator_before_x3
            type: u4
            if: _root.version < 1300
          - size: 8
            if: _root.version < 1300 and indicator_before_x3 != 0
          - size: 8
            if: _root.version < 1300
      indent:
        seq:
          - id: id
            type: u4
          - size: 12
          - id: right
            type: coord
          - id: first
            type: coord
          - id: left
            type: coord
      record:
        seq:
          - id: num
            type: u4
          - id: style_id
            type: u4
          - id: parent_id
            type: u4
          - size: 8
          - id: char_len_name
            type: u4
          - id: name_old
            size: char_len_name * 1
            type: strz
             # not accurate, but best we can do here (in fact, it reflects the
             # https://en.wikipedia.org/wiki/Windows_code_page#ANSI_code_page
             # based on the currently set system locale, at least on Windows)
            encoding: windows-1252
            if: _root.version < 1200
          - id: name_new
            size: char_len_name * 2
            type: str
            encoding: UTF-16LE
            if: _root.version >= 1200
          - id: fill_id
            type: u4
          - id: outl_id
            type: u4
          - id: ext_font_properties_1
            type: extended_font_properties_1
            if: num > 1
          - id: ext_font_properties_2
            type: extended_font_properties_2
            if: num > 2
        instances:
          name:
            value: '_root.version >= 1200 ? name_new : name_old'
      extended_font_properties_1:
        seq:
          - id: font_rec_id
            type: u4
          - id: align_id
            type: u4
          - id: interval_id
            type: u4
          - id: set5_id
            type: u4
          - id: set11_id
            type: u4
            if: _parent._parent.mapping_section.has_set11s
      extended_font_properties_2:
        seq:
          - id: tab_id
            type: u4
          - id: bullet_id
            type: u4
          - id: indent_id
            type: u4
          - id: hyphen_id
            type: u4
          - id: drop_cap_id
            type: u4
  txsm_chunk_data:
    seq:
      - id: body
        type:
          switch-on: '_root.version < 500 ? 0 : (_root.version < 600 ? 5 : (_root.version < 700 ? 6 : (_root.version >= 1600 ? 16 : 7)))'
          cases:
            0: txsm_0
            5: txsm_5
            6: txsm_6
            7: txsm_7
            16: txsm_16
    types:
      txsm_0:
        seq: []
      txsm_5:
        seq: []
      txsm_6:
        seq: []
      txsm_7:
        seq:
          - id: frame_flag_raw
            type: u4
          - size: 32
          - size: 1
            if: _root.version >= 1500
          - type: skip_1
            # libcdr checks for versions <= 700 instead, which is odd because it would include
            # version 700 but not minor version updates like 701. The simplest explanation is that
            # it's supposed to be < 800.
            if: _root.version < 800
          - id: num_frames
            type: u4
          - id: frames
            type: frame
            repeat: expr
            repeat-expr: num_frames
          - id: num_paragraphs
            type: u4
          - id: paragraphs
            type: paragraph
            repeat: expr
            repeat-expr: num_paragraphs
        instances:
          frame_flag:
            value: frame_flag_raw != 0
        types:
          skip_1:
            seq:
              - id: text_on_path_raw
                type: u4
              - size: 32
                if: text_on_path
            instances:
              text_on_path:
                value: text_on_path_raw != 0
          frame:
            seq:
              - id: frame_id
                type: u4
              - size: 48
              - type: skip_2
                if: _root.version > 700
              - size: |
                  _root.version >= 1500
                    ? 40 :
                  _root.version >= 1400
                    ? 36 :
                  _root.version >= 801
                    ? 34 :
                  _root.version == 800
                    ? 32 :
                  _root.version >= 700
                    ? 36
                    : 0
                if: not _parent.frame_flag
              - size: 4
                if: _parent.frame_flag and _root.version >= 1500
            types:
              skip_2:
                seq:
                  - id: text_on_path_raw
                    type: u4
                  - type: skip_3
                    if: text_on_path
                  - size: 8
                    if: not text_on_path and _root.version >= 1500
                instances:
                  text_on_path:
                    value: text_on_path_raw != 0
                types:
                  skip_3:
                    seq:
                      - size: 4
                      - size: 8
                        if: _root.version > 1200
                      - size: 28
                      - size: 8
                        if: _root.version >= 1500
          paragraph:
            seq:
              - id: style_id
                type: u4
              - size: 1
              - size: 1
                if: _root.version > 1200 and _parent.frame_flag
              - id: num_styles
                type: u4
              - id: styles
                type: style
                repeat: expr
                repeat-expr: num_styles
              - id: num_chars
                type: u4
              - id: char_descriptions
                type: char_description
                repeat: expr
                repeat-expr: num_chars
              - id: num_bytes_in_text_raw
                type: u4
                if: _root.version >= 1200
              - id: text_data
                size: num_bytes_in_text
              - id: has_path_raw
                type: u1
              - size: num_chars * 24
                if: has_path
            instances:
              num_bytes_in_text:
                value: '_root.version >= 1200 ? num_bytes_in_text_raw : num_chars'
              has_path:
                value: has_path_raw != 0
            types:
              style:
                seq:
                  - id: num_chars
                    type: u2
                  - id: has_font
                    type: b1 # 0x01
                  - id: has_style_flags
                    type: b1 # 0x02
                  - id: has_font_size
                    type: b1 # 0x04
                  - id: has_unknown # "// assumption" in libcdr
                    type: b1 # 0x08
                  - id: has_offset_x
                    type: b1 # 0x10
                  - id: has_offset_y
                    type: b1 # 0x20
                  - id: has_font_color
                    type: b1 # 0x40
                  - id: has_outl_id
                    type: b1 # 0x80
                  - id: fl3_maybe
                    type: u1
                    if: _root.version >= 800
                  - id: font
                    type: font_data
                    if: has_font
                  - id: style_flags
                    type: text_style_flags
                    if: has_style_flags
                  - id: font_size
                    type: coord
                    if: has_font_size
                  - size: 4
                    if: has_unknown
                  - size: 4
                    if: has_offset_x
                  - size: 4
                    if: has_offset_y
                  - id: font_color
                    type: font_color_data
                    if: has_font_color
                  - id: outl_id
                    type: u4
                    if: has_outl_id
                  - id: url_properties
                    type: url_props
                    if: (fl3 & 0x02) != 0
                  - id: language
                    type: text_language
                    if: (fl3 & 0x08) != 0
                  - type: skip_5
                    if: (fl3 & 0x20) != 0
                instances:
                  fl3:
                    value: '_root.version >= 800 ? fl3_maybe : 0'
                types:
                  font_data:
                    seq:
                      - id: font_id
                        type: u2
                      - id: encoding
                        type: u2
                        enum: text_encoding
                  font_color_data:
                    seq:
                      - id: fill_id
                        type: u4
                      - size: 48
                        if: _root.version >= 1300
                  skip_5:
                    seq:
                      - size: '_root.version >= 1500 ? 52 : 4'
                        if: flag != 0
                    instances:
                      ofs_flag:
                        value: _io.pos
                      flag:
                        pos: ofs_flag
                        type: u1
      txsm_16:
        seq:
          - id: frame_flag_raw
            type: u4
          - size: 32
          # In most cases, this field is set to 1700 or 1800. The only other value I have seen so
          # far is 1600, and the presence of that value seems to correlate with a different layout
          # in 'paragraph.'
          - id: style_layout_version
            type: u2
          - size: 3
          - id: num_frames
            type: u4
          - id: frames
            type: frame
            repeat: expr
            repeat-expr: num_frames
          - id: num_paragraphs
            type: u4
          - id: paragraphs
            type: paragraph
            repeat: expr
            repeat-expr: num_paragraphs
        instances:
          frame_flag:
            value: frame_flag_raw != 0
        types:
          frame:
            seq:
              - id: frame_id
                type: u4
              - size: 48
              - id: text_on_path_raw
                type: u4
              - size: 40
                if: text_on_path
              - size: 8
              - type: skip
                if: not _parent.frame_flag
            instances:
              text_on_path:
                value: text_on_path_raw != 0
          paragraph:
            seq:
              - id: style_id
                type: u4
              - size: 1
              - id: flag
                type: u1
                if: _parent.frame_flag
              # This section of unknown use is not accounted for by libcdr, but it might have something to do with
              # curved text.
              # The size and condition below are a guess based on just one sample input file.
              - size: 64
                if: flag == 1
              - id: paragraph_style
                type: style_string
                if: _parent.style_layout_version < 1700
              - id: default_style
                type: style_string
              - id: num_records
                type: u4
              - id: style_records
                type: style_record
                repeat: expr
                repeat-expr: num_records
              - id: num_chars
                type: u4
              - id: char_descriptions
                type: char_description
                repeat: expr
                repeat-expr: num_chars
              - id: num_bytes_in_text
                type: u4
              - id: text_data
                size: num_bytes_in_text
              - id: has_path_raw
                type: u1
              - size: num_chars * 24
                if: has_path
            instances:
              has_path:
                value: has_path_raw != 0
          style_record:
            seq:
              - id: st_flag_1
                type: u2
              - id: st_flag_2
                type: u2
              - id: st_flag_3
                type: u2
              - id: url_properties
                type: url_props
                if: st_flag_2 == 0x3fff and (st_flag_3 & 0x11) == 0x11
              - id: language
                type: text_language
                if: (st_flag_3 & 0x04) != 0
              - id: style
                type: style_string
                if: st_flag_2 != 0 or (st_flag_3 & 0x04) != 0
          skip:
            seq:
              - size: 16
              - id: t_len
                type: u4
              - size: '_root.version > 1600 ? t_len : t_len * 2'
      char_description:
        seq:
          - id: flags
            type: u2
          - id: style_override_idx_raw
            type: u1
          - size: 1 # usually 0x00, but can also be 0x20, 0x40 or 0x60
          - size: 4
            if: _root.version >= 1200
        instances:
          style_override_idx:
            value: style_override_idx_raw >> 1
      url_props:
        seq:
          - id: url_id_len
            type: u4
          - id: url_id_old
            size: url_id_len * 2
            type: str
            encoding: UTF-16LE
            if: _root.version < 1700
          - id: url_id_new
            size: url_id_len
            type: str
            encoding: ASCII
            if: _root.version >= 1700
        instances:
          url_id_raw:
            value: '_root.version < 1700 ? url_id_old : url_id_new'
          url_id:
            value: url_id_raw.to_i
      text_language:
        seq:
          - id: value_old
            size: 4
            type: strz
            encoding: ASCII
            if: _root.version < 1300

          - id: value_new_len
            type: u4
            if: _root.version >= 1300
          - id: value_new
            size: value_new_len.as<u4> * 2
            type: str
            encoding: UTF-16LE
            if: _root.version >= 1300
            doc-ref: https://www.ibm.com/docs/en/cics-ts/5.5?topic=development-national-language-codes-application
        instances:
          value:
            value: '_root.version >= 1300 ? value_new : value_old'
  urls_chunk_data:
    seq:
      - id: text
        type: text_type
    types:
      text_type:
        seq:
          - id: value_old
            size-eos: true
            type: strz
            # not accurate, but best we can do here (in fact, it reflects the
            # https://en.wikipedia.org/wiki/Windows_code_page#ANSI_code_page
            # based on the currently set system locale, at least on Windows)
            encoding: windows-1252
            if: _root.version < 1200
          - id: value_new
            size-eos: true
            # FIXME: should be `type: strz` but Kaitai Struct doesn't support it for
            # UTF-16 yet, see https://github.com/kaitai-io/kaitai_struct/issues/187
            type: str
            encoding: UTF-16LE
            if: _root.version >= 1200
        instances:
          value:
            # a poor man's workaround for `value_new` not being properly parsed
            # as null-terminated (but I believe this actually works fine for
            # .cdr files generated by CorelDRAW)
            value: |
              _root.version >= 1200 ? (
                value_new.substring(value_new.length - 1, value_new.length) == [0x00, 0x00].to_s('UTF-16LE')
                  ? value_new.substring(0, value_new.length - 1)
                  : value_new
              ) : value_old
  # udta_chunk_data: {}
  # styd_chunk_data: {}

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

  guid:
    -webide-representation: "{value:uuid=ms}"
    seq:
      - id: value
        size: 16
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
          raw / (_root.precision_16bit ? 1000.0 : 254000.0)
    -webide-representation: "{value:dec}"
  points_list:
    params:
      - id: num_points_raw
        type: u4
    seq:
      - size: 0
        if: ofs_points < 0
      - id: points
        type: point(point_types[_index])
        repeat: expr
        repeat-expr: num_points
    instances:
      ofs_points:
        value: _io.pos
      point_types:
        pos: ofs_points + point_size * num_points
        type: u1
        repeat: expr
        repeat-expr: num_points
      num_points:
        value: 'num_points_raw <= num_points_max ? num_points_raw.as<s4> : num_points_max'
      num_points_max:
        value: '(_io.size - _io.pos) / (point_size + sizeof<u1>)'
      point_size:
        value: '(_root.precision_16bit ? sizeof<s2> : sizeof<s4>) * 2'
    types:
      point:
        params:
          - id: type
            type: u1
        seq:
          - id: x
            type: coord
          - id: y
            type: coord
        instances:
          unknown_flag:
            value: (type & 0b0000_0001) != 0
            doc: |
              in 41 sample .cdr files in various CDR versions covering the entire range
              from 1100 to 2400, this has always had the same value throughout the file -
              for 39 files `false`, only for 2 files `true` (both in version 1300, but
              other 4 files also in version 1300 were using `false`)
          char_start:
            value: (type & 0b0000_0010) != 0
            doc-ref: https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l396
          can_modify:
            value: (type & 0b0000_0100) != 0
            doc: |
              According to sample files:

              * for `operations::move_to` it's been always `true` in all 41 samples that I had;

              * for `operations::line_to` it's `true` for the normal `is_closing_path == false`
              point, but `false` for the explicit close path segment with `is_closing_path == true`
              (CDR doesn't have auto-closing paths, they are closed explicitly);

              * for `operations::cubic_bezier_to`, `false` only appears with `is_closing_path ==
              true`, `true` comes only with `is_closing_path == false` for all .cdr files with
              `unknown_flag == false` (i.e. the vast majority of .cdr files);

                in the 2 samples in version 1300 with `unknown_flag == true` (see the description of
                `unknown_flag`), most `can_modify == true` points have `is_closing_path == false` as
                usual, but occasionally there is a point with `can_modify == true` and
                `is_closing_path == true`, every time at the very end of `points`;

              * for `operations::control_point` it's `false` in 99% of cases;

                only 1 sample (in version 1400) out of 41 had a `chunk_types::line_and_curve` object
                (the first 'LIST:obj ' chunk of the content page) where all points except the last
                one (which was the only "close path" segment, i.e. a `operations::line_to` point
                with `is_closing_path == true` and the `x`, `y` coordinates the same as the initial
                `operations::move_to` point of the subpath) had `can_modify` set to `true`, but it
                is apparently rare.
            doc-ref: https://sourceforge.net/p/uniconvertor/code/145/tree/formats/CDR/cdr_explorer/src/chunks.py#l398
          is_closing_path:
            value: (type & 0b0000_1000) != 0
            doc: |
              According to sample files:

              * for `operations::move_to` it's `true` in closed subpaths, `false` in open subpaths;

              * for `operations::line_to` and `operations::cubic_bezier_to` it's `true` if the
              segment closes the current subpath (meaning that the `x`, `y` coordinates of such
              `operations::{line_to,cubic_bezier_to}` point with `is_closing_path == true` are
              always the same as in the initial `operations::move_to` point with `is_closing_path ==
              true` of the subpath), `false` otherwise;

              * for `operations::control_point` it's always `false`.
          continuation:
            value: (type & 0b0011_0000) >> 4
            enum: continuations
          operation:
            value: (type & 0b1100_0000) >> 6
            enum: operations
        enums:
          operations:
            0b00: move_to
            0b01: line_to
            0b10:
              id: cubic_bezier_to
              doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CommonParser.cpp#L116-L127
            0b11: control_point
          continuations:
            0b00: angle
            0b01: smooth
            0b10: symmetrical
  angle:
    seq:
      - id: raw
        type:
          switch-on: _root.precision_16bit
          cases:
            true: s2
            _: s4
    instances:
      value_deg:
        value: >-
          _root.precision_16bit
            ? raw / 10.0
            : raw / 1000000.0
      value_rad:
        value: (value_deg / 180.0) * 3.14159265358979323846
      value_rad_rem:
        value: value_rad % (2 * 3.14159265358979323846)
      value_rad_normalized:
        value: 'value_rad_rem + (value_rad_rem < 0 ? 2 * 3.14159265358979323846 : 0)'
    -webide-representation: "{value_deg:dec}°"
  color:
    seq:
      - id: color_since_v5
        if: _root.version >= 500
        type: color_new
      - id: color_v4
        if: _root.version >= 400 and _root.version < 500
        type: color_middle
      - id: color_before_v4
        if: _root.version < 400
        type: color_old
    types:
      color_new:
        seq:
          - id: color_model
            type: u2
            enum: color_model
          - id: color_palette
            type: u2
            enum: color_palette
          - id: unknown
            size: 4
          - id: color_value
            type: u1
            repeat: expr
            repeat-expr: 4
      color_middle:
        seq:
          - id: color_model
            type: u2
            enum: color_model
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
        instances:
          color_value:
            value: '[(c & 0xff).as<u1>, (m & 0xff).as<u1>, (y & 0xff).as<u1>, (k & 0xff).as<u1>].as<u1[]>'
      color_old:
        seq:
          - id: color_model
            type: u1
            enum: color_model
          - id: color_value
            type: u1
            repeat: expr
            repeat-expr: 4
    enums:
      # https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRCollector.cpp#L336-L582
      # https://github.com/sk1project/uniconvertor/blob/973d5b6f/src/uc2/formats/cdr/cdr_const.py#L62-L82
      # https://community.coreldraw.com/sdk/api/draw/17/e/cdrcolortype
      color_model:
        1: pantone
        2: cmyk100
        3: cmyk255_i3
        4: cmy
        5: bgr
        6: hsb
        7: hls
        8: bw
        9: grayscale
        11: yiq255
        12:
          id: lab_signed_int8
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRCollector.cpp#L541-L554
        13:
          id: index
          doc-ref: CorelDRAW 9 Draw_scr.hlp
          doc: no longer present in CorelDRAW 10 DRAW10VBA.HLP
        14: pantone_hex
        15:
          id: hexachrome
          doc-ref: CorelDRAW 9 Draw_scr.hlp
          doc: no longer present in CorelDRAW 10 DRAW10VBA.HLP
        17: cmyk255_i17
        18:
          id: lab_offset_128
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRCollector.cpp#L555-L568
        20: registration
        21:
          id: bgr_tint
          # NOTE: libcdr treats color model `21` (0x15) as CMYK100
          # (https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRCollector.cpp#L339),
          # but that is clearly wrong according to sample files
          doc: |
            Seen only in `fild_chunk_data::solid` in a `property_type::color`
            property for "special palette" colors so far.

            color_value[0]: Blue (0..255)
            color_value[1]: Green (0..255)
            color_value[2]: Red (0..255)
            color_value[3]: Tint (0..100) - as in `color_model::spot`

            However, note that "Tint" has already been factored into the RGB
            value, so it's apparently just for reference.
        22:
          id: user_ink
          doc-ref: https://community.coreldraw.com/sdk/api/draw/17/e/cdrcolortype
        25: spot
        26:
          id: multi_channel
          doc-ref: https://community.coreldraw.com/sdk/api/draw/17/e/cdrcolortype
        99:
          id: mixed
          doc-ref: https://community.coreldraw.com/sdk/api/draw/17/e/cdrcolortype
      # CorelDRAW 9: Programs/Draw_scr.hlp, Programs/Data/*.{cpl,pcp}
      # CorelDRAW 10: Programs/DRAW10VBA.HLP, Programs/Data/*.cpl
      # CorelDRAW 11: Programs/DRAW11VBA.HLP, Programs/Data/*.cpl
      # CorelDRAW X7:
      #   - https://community.coreldraw.com/sdk/api/draw/17/e/cdrpaletteid
      #   - Color/Palettes/**/*.xml
      color_palette:
        0: custom
        1:
          id: trumatch
          doc: TRUMATCH Colors # palette name
        2:
          id: pantone_process
          -orig-id:
            - PANTONE PROCESS # CorelDRAW 9 Draw_scr.hlp
            - pantone # palette file name (without the .cpl/.xml extension)
          doc: PANTONE(r) process coated
        3:
          id: pantone_corel8
          -orig-id:
            - PANTONE SPOT # CorelDRAW 9 Draw_scr.hlp
            - cdrPANTONECorel8 # CorelDRAW 10 DRAW10VBA.HLP
            - pantone8
          doc: PANTONE MATCHING SYSTEM - Corel 8
        4:
          id: image
          -orig-id: IMAGE # CorelDRAW 9 Draw_scr.hlp, no longer in CorelDRAW 10 DRAW10VBA.HLP
        5:
          id: user
          -orig-id: USER # CorelDRAW 9 Draw_scr.hlp, no longer in CorelDRAW 10 DRAW10VBA.HLP
        6:
          id: custom_fixed
          -orig-id: CUSTOMFIXED # CorelDRAW 9 Draw_scr.hlp, no longer in CorelDRAW 10 DRAW10VBA.HLP
        7:
          id: uniform
          -orig-id:
            - RGBSTANDARD # CorelDRAW 9 Draw_scr.hlp
            - cdrUniform # CorelDRAW 10 DRAW10VBA.HLP
            - rgbstd
          doc: Uniform Colors
        8:
          id: focoltone
          -orig-id:
            - focolton
          doc: FOCOLTONE Colors
        9:
          id: spectra_master
          -orig-id:
            - DUPONT # CorelDRAW 9 Draw_scr.hlp
            - cdrSpectraMaster # CorelDRAW 10 DRAW10VBA.HLP
            - dupont
          doc: SpectraMaster(r) Colors
        10:
          id: toyo
          doc: TOYO COLOR FINDER
        11:
          id: dic
          doc: DIC Colors
        12:
          id: pantone_hex_coated_corel10
          -orig-id:
            - cdrPANTONEHexCoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panhexc
          doc: PANTONE Hexachrome Coated - Corel 10
        13:
          id: lab
          -orig-id:
            - labpal
          doc: Lab Colors
        14:
          id: netscape
          -orig-id:
            - NETSCAPE # CorelDRAW 9 Draw_scr.hlp
            - cdrNetscapeNavigator # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - netscape # netscape.cpl is present in CorelDRAW 9, but not anymore in CorelDRAW 10
        15:
          id: explorer
          -orig-id:
            - EXPLORER # CorelDRAW 9 Draw_scr.hlp
            - cdrInternetExplorer # CorelDRAW 10 DRAW10VBA.HLP
            - explorer # explorer.cpl is present in CorelDRAW 9, but not anymore in CorelDRAW 10
          doc: no longer present in CorelDRAW 11 DRAW11VBA.HLP
        16: user_inks
        17:
          id: pantone_coated_corel10
          -orig-id:
            - cdrPANTONECoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panguidc
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L2348
          doc: PANTONE MATCHING SYSTEM Coated - Corel 10
        18:
          id: pantone_uncoated_corel10
          -orig-id:
            - cdrPANTONEUncoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panguidu
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L2630
          doc: PANTONE MATCHING SYSTEM Uncoated - Corel 10
        20:
          id: pantone_metallic_corel10
          -orig-id:
            - cdrPANTONEMetallic # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panmetlu
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L2912
          doc: PANTONE Metallic Colors Unvarnished - Corel 10
        21:
          id: pantone_pastel_coated_corel10
          -orig-id:
            - cdrPANTONEPastelCoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panpastc
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L2982
          doc: PANTONE Pastel Colors Coated - Corel 10
        22:
          id: pantone_pastel_uncoated_corel10
          -orig-id:
            - cdrPANTONEPastelUncoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panpastu
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L3032
          doc: PANTONE Pastel Colors Uncoated - Corel 10
        23:
          id: hks
          -orig-id: HKS(r) Colors
        24:
          id: pantone_hex_uncoated_corel10
          -orig-id:
            - cdrPANTONEHexUncoated # CorelDRAW 10 DRAW10VBA.HLP, no longer in CorelDRAW 11 DRAW11VBA.HLP
            - panhexu
          doc: PANTONE Hexachrome Uncoated - Corel 10
        25:
          id: web_safe
          -orig-id:
            - WebSafe # file name
          doc: Web-safe Colors
        26:
          id: hks_k
          -orig-id:
            - HKS_K # file name
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L3960
        27:
          id: hks_n
          -orig-id:
            - HKS_N # file name
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L4002
        28:
          id: hks_z
          -orig-id:
            - HKS_Z # file name
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L4044
        29:
          id: hks_e
          -orig-id:
            - HKS_E # file name
          doc-ref: https://github.com/LibreOffice/libcdr/blob/b14f6a1f17652aa842b23c66236610aea5233aa6/src/lib/CDRColorPalettes.h#L4086
        30:
          id: pantone_metallic
          -orig-id:
            - panmetlc
          doc: PANTONE(r) metallic coated
        31:
          id: pantone_pastel_coated
          -orig-id:
            - panpasc
          doc: PANTONE(r) pastel coated
        32:
          id: pantone_pastel_uncoated
          -orig-id:
            - panpasu
          doc: PANTONE(r) pastel uncoated
        33:
          id: pantone_hex_coated
          -orig-id:
            - panhexac
          doc: PANTONE(r) hexachrome(r) coated
        34:
          id: pantone_hex_uncoated
          -orig-id:
            - PANTONE(r) hexachrome(r) uncoated
            - panhexau
        35:
          id: pantone_matte
          -orig-id:
            - pantonem
          doc: PANTONE(r) solid matte
        36:
          id: pantone_coated
          -orig-id:
            - pantonec
          doc: PANTONE(r) solid coated
        37:
          id: pantone_uncoated
          -orig-id:
            - pantoneu
          doc: PANTONE(r) solid uncoated
        38:
          id: pantone_process_coated_euro
          -orig-id:
            - paneuroc
          doc: PANTONE(r) process coated EURO
        39:
          id: pantone_solid2process_euro
          -orig-id:
            - pans2pec
          doc: PANTONE(r) solid to process EURO
        40:
          id: svg_named_colors
          -orig-id:
            - cdrSVGPalette
            - SVGColor # file name (SVGColor.xml)
          doc: SVG Colors
  text_style_flags:
    doc-ref: https://community.coreldraw.com/sdk/api/draw/17/c/structfontproperties
    seq:
      - id: emphasis_raw
        type: u2
      - id: unknown
        type: b2
      - id: underline
        type: b3
        enum: font_line
      - id: overline
        type: b3
        enum: font_line
      - id: strike_through_line
        type: b3
        enum: font_line
      - id: position
        type: b2
        enum: font_position
      - type: b3
    instances:
      italic:
        value: emphasis_raw == 0x0080 or emphasis_raw == 0x2000
      bold:
        value: emphasis_raw == 0x1000 or emphasis_raw == 0x2000
    enums:
      # https://community.coreldraw.com/sdk/api/draw/17/e/cdrfontline
      font_line:
        0: none
        1: single_thin
        2: single_thin_word
        3: single_thick
        4: single_thick_word
        5: double_thin
        6: double_thin_word
        7: mixed
      # NOTE: https://community.coreldraw.com/sdk/api/draw/17/e/cdrfontposition has subscript at 1
      # and superscript at 2, but that doesn't agree with sample files - the interpretation below
      # does.
      font_position:
        0: none
        1: superscript
        2: subscript
  style_string:
    seq:
      - id: len_raw
        type: u4
      - id: value
        size: len
    instances:
      len:
        value: '_root.version < 1700 ? len_raw * 2 : len_raw'
enums:
  text_encoding:
    0x00: latin                     # cp1252
    0x01: system_default
    0x02: symbol
    0x4d: apple_roman               # cp10000 ?
    0x80: japanese_shift_jis        # cp932
    0x81: korean_hangul             # cp949
    0x82: korean_johab              # cp1361
    0x86: chinese_simplified_gbk    # cp936
    0x88: chinese_traditional_big5  # cp950
    0xa1: greek                     # cp1253
    0xa2: turkish                   # cp1254
    0xa3: vietnamese                # cp1258
    0xb1: hebrew                    # cp1255
    0xb2: arabic                    # cp1256
    0xba: baltic                    # cp1257
    0xcc: cyrillic                  # cp1251
    0xde: thai                      # cp874
    0xee: latin_ii_central_european # cp1250
    0xff: oem_latin_i
