(function() {
    var check_completeness, form_alert, handle_submit, init, reset_alert_area, valid_token;

    $(document).ready(function() {

        $('#organization-select').change(function() {
            return load_courses();
        });

        $('#lms-instance-select').change(function() {
            return handle_lms_access();
        });

        $('#lms-access-token').change(function() {
            $("#lms-access-token-check").hide("slow");
            // return handle_access_token();

        });

        $('#btn-submit-co').click(function() {
            $(this).prop('disabled', true);
            return handle_submit();
        });

        init();
    });

    load_courses = function() {
        var request = "/courses/" + $('#organization-select').val() + "/search";

        var aj = $.ajax({
            url: request,
            type: 'get',
            data: $(this).serialize()
        }).done(function(data) {
            change_courses(data);
        }).fail(function(data) {
            console.log('AJAX request has FAILED');
        });
    };

    handle_access_token = function() {
        if ($('#lms-access-token').val()) {

            var request = $("#lms-instance-select option:selected").text() + "/api/v1/courses?access_token=" + $('#lms-access-token').val();
            console.log(request);
            $("#lms-access-token-check").removeClass("fa-times");
            $("#lms-access-token-check").removeClass("fa-check");
            $("#lms-access-token-check").addClass("fa-check")
                // $("#lms-access-token-check").hide("slow");
            var aj = $.ajax({
                url: request,
                type: 'get',
                data: $(this).serialize()
            }).done(function(data) {
                $("#lms-access-token-check").addClass("fa-check")
                $("#lms-access-token-check").show("slow");
                valid_token = true;
            }).fail(function(jqXHR, textStatus) {
                $("#lms-access-token-check").addClass("fa-times")
                $("#lms-access-token-check").show("slow");
                valid_token = false;
            });
        }
    };

    handle_lms_access = function() {
        if ($('#lms-instance-select').val()) {
            var request = "/lms_accesses/" + $('#lms-instance-select').val() + "/search";

            var aj = $.ajax({
                url: request,
                type: 'get',
                data: $(this).serialize()
            }).done(function(data) {
                if (data) {
                    if (data['access_token'] != null) {
                        $('#lms-access-token').val(data['access_token']);
                        // $("#lms-access-update-btn").show("slow");
                        // $("#lms-access-token-group").hide("slow");
                    }
                    $("#lms-access-token-check").removeClass("fa-times");
                    $("#lms-access-token-check").removeClass("fa-check");
                    valid_token = data['valid_token'];
                    if (data['valid_token']) {
                        $("#lms-access-token-check").addClass("fa-check")
                    } else {
                        $("#lms-access-token-check").addClass("fa-times")
                    }
                    $("#lms-access-token-check").show("slow");
                }
            }).fail(function(data) {
                console.log('AJAX request has FAILED');
            });
        }
    };

    //modify the course dropdown
    change_courses = function(data) {
        $("#course-select").empty();
        for (i = 0; i < data.length; i++) {
            $("#course-select").append(
                $("<option></option>").attr("value", data[i].id).text(data[i].number + ': ' + data[i].name)
            );
        }
    };

    init = function() {
        // $("#lms-access-update-btn").hide();
        $("#lms-access-token-check").hide();
        // $("#lms-access-token-group").hide();
    };

    form_alert = function(messages) {
        var alert_list, message, _fn, _i, _len;
        reset_alert_area();
        alert_list = $('#alerts').find('.alert ul');
        _fn = function(message) {
            return alert_list.append('<li>' + message + '</li>');
        };
        for (_i = 0, _len = messages.length; _i < _len; _i++) {
            message = messages[_i];
            _fn(message);
        }
        return $('#alerts').css('display', 'block');
    };

    reset_alert_area = function() {
        var alert_box;
        $('#alerts').find('.alert').alert('close');
        alert_box = "<div class='alert alert-danger alert-dismissable' role='alert'>" + "<button class='close' data-dismiss='alert' aria-label='Close'><i class='fa fa-times'></i></button>" + "<ul></ul>" + "</div>";
        return $('#alerts').append(alert_box);
    };

    check_completeness = function() {
        var messages;
        messages = [];
        if ($('#lms-instance-select').val() === '') {
            messages.push('One of the LMS instances has to be selected.');
        }
        if ($('#lms-access-token-group').is(":visible")) {
            if ($('#lms-access-token').val() === '') {
                messages.push('You have to provide an access token for the selected Canvas instance.');
            }
        };
        if ($('#lms-course-num').val() === '') {
            messages.push('You have to write LMS course Id.');
        }
        // if ($('#lms-course-code').val() === '') {
        //   messages.push('You have to write LMS course name.');
        // }
        if ($('#organization-select').val() === '') {
            messages.push('One of the organizations has to be selected.');
        }
        if ($('#course-select').val() === '') {
            messages.push('One of the courses has to be selected.');
        }
        if ($('#term-select').val() === '') {
            messages.push('One of the terms has to be selected.');
        }
        if ($('#label').val() === '') {
            messages.push('You have to write a label.');
        }
        if ($('#inst-book-select').val() === '') {
            messages.push('One of book instances has to be selected.');
        }
        return messages;
    };

    handle_submit = function() {
        var lms_instance_id, lms_course_num, lms_course_code, organization_id, course_id, term_id, label, late_policy_id, inst_book_id, fd, messages, url;
        messages = check_completeness();
        if (messages.length !== 0) {
            form_alert(messages);
            $('#btn-submit-co').prop('disabled', false);
            return;
        }
        lms_instance_id = $('#lms-instance-select').val();
        lms_access_token = $('#lms-access-token').val();
        lms_course_num = $('#lms-course-num').val();
        // lms_course_code = $('#lms-course-code').val();
        organization_id = $('#organization-select').val();
        course_id = $('#course-select').val();
        term_id = $('#term-select').val();
        label = $('#label').val();
        // late_policy_id = $('#late-policy-select').val();
        inst_book_id = $('#inst-book-select').val();
        fd = new FormData;
        fd.append('lms_instance_id', lms_instance_id);
        fd.append('lms_access_token', lms_access_token);
        fd.append('lms_course_num', lms_course_num);
        // fd.append('lms_course_code', lms_course_code);
        fd.append('organization_id', organization_id);
        fd.append('course_id', course_id);
        fd.append('term_id', term_id);
        fd.append('label', label);
        // fd.append('late_policy_id', late_policy_id);
        fd.append('inst_book_id', inst_book_id);
        url = '/course_offerings'
        return $.ajax({
            url: url,
            type: 'post',
            data: fd,
            processData: false,
            contentType: false,
            success: function(data) {
                return window.location.href = data['url'];
            }
        });
    };

}).call(this);