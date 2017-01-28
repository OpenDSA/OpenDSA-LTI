(function() {

    $(function() {
        book_name = jsonFile['title'];
        chapters = [];
        $.each(jsonFile['chapters'], function(ch_index, ch_obj) {
            tree_ch_obj = {
                'text': ch_index,
                'children': []
            };
            $.each(ch_obj, function(mod, mod_obj) {
                if (mod_obj !== null && typeof mod_obj === 'object') {
                    tree_ch_obj['children'].push(mod);
                }
            });
            chapters.push(tree_ch_obj);
        });
        $('#using_json').jstree({
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