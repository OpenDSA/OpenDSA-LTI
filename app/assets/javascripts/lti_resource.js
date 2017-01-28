(function() {
    // get the rst module name
    var getModName = function(mod_name) {
        var mod_name = mod_name || '';
        if (mod_name.indexOf('/') > -1) {
            return mod_name.split('/')[1]
        } else {
            return mod_name
        }
    };
    // prepare and send back the complete url used by canvas to configure lti launch
    var getResourceURL = function(obj) {
        if (!$.isEmptyObject(obj)) {
            var odsa_url = odsa_launch_url + '?' + $.param(obj);
            var urlParams = {
                'embed_type': 'basic_lti',
                'url': odsa_url
            };
            return return_url + '?' + $.param(urlParams);
        }
        return '';
    };

    $(function() {
        var book_name = jsonFile['title'];
        var chapters = [];
        // prepare tree data
        $.each(jsonFile['chapters'], function(ch_index, ch_obj) {
            var tree_ch_obj = {
                'text': ch_index,
                'children': []
            };
            $.each(ch_obj, function(mod_index, mod_obj) {
                if (mod_obj !== null && typeof mod_obj === 'object') {
                    var rst_file_name = getModName(mod_index);
                    if (mod_obj.hasOwnProperty('long_name')) {
                        var mod_name = mod_obj['long_name'];
                    } else {
                        var mod_name = rst_file_name;
                    }
                    var tree_mod_obj = {
                        'text': mod_name,
                        'children': []
                    };
                    if (mod_obj['sections'] != null) {
                        var sec_count = 0;
                        $.each(mod_obj['sections'], function(sec_index, sec_obj) {
                            if (sec_obj !== null && typeof sec_obj === 'object') {
                                var tree_sec_obj = {
                                    'text': sec_index,
                                    'type': 'section',
                                    'url_params': {
                                        'custom_inst_book_id': inst_book_id,
                                        'custom_inst_section_id': sec_obj['id'],
                                        'custom_section_file_name': rst_file_name + '-' + ("0" + sec_count).slice(-2),
                                        'custom_section_title': sec_index
                                    }
                                }
                                tree_mod_obj['children'].push(tree_sec_obj);
                                sec_count += 1;
                            }
                        });
                    }
                    tree_ch_obj['children'].push(tree_mod_obj);
                }
            });
            chapters.push(tree_ch_obj);
        });

        // insialize tree instance
        $('#using_json')

        // listen for select event
        .on('select_node.jstree', function(e, data) {
            var selected = data.instance.get_node(data.selected);
            if (selected.original.type === 'section') {
                console.log(getResourceURL(selected.original.url_params));
                window.location.href = getResourceURL(selected.original.url_params);
            }
        })

        .jstree({
            'core': {
                'data': [{
                    'text': book_name,
                    'state': {
                        'opened': true,
                        'selected': true
                    },
                    'children': chapters
                }]
            }
        });

        $(".test-class").click(function() {
            window.location.href = 'https://canvas.instructure.com/courses/1123090/external_content/success/external_tool_dialog?embed_type=basic_lti&url=https%3A%2F%2Fopendsax.cs.vt.edu%2Flti%2Flaunch%3Fa%3D1%26b%3D2';
        });
    })

}).call(this);