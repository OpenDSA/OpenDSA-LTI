(function() {
  var check_completeness, form_alert, handle_submit, init, reset_alert_area;

  $(document).ready(function() {

    $('#organization-select').change(function() { //change majors when user changes school
      return load_courses();
    });

    $('#lms-instance-select').change(function() { //change majors when user changes school
      return handle_lms_access();
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

  handle_lms_access = function() {
    if ($('#lms-instance-select').val()) {
      var request = "/lms_accesses/" + $('#lms-instance-select').val() + "/search";

      var aj = $.ajax({
        url: request,
        type: 'get',
        data: $(this).serialize()
      }).done(function(data) {
        if (data) {
          $("#lms-access-update-btn").show("slow");
          $("#lms-access-token").hide("slow");
        } else {
          $("#lms-access-update-btn").hide("slow");
          $("#lms-access-token").show("slow");
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
    $("#lms-access-update-btn").hide();
    $("#lms-access-token").hide();
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
    if ($('#lms-access-token').is(":visible")) {
      if ($('#lms-access-token').val() === '') {
        messages.push('You have to provide an access token for the selected Canvas instance.');
      }
    };
    if ($('#lms-course-id').val() === '') {
      messages.push('You have to write LMS course Id.');
    }
    if ($('#lms-course-name').val() === '') {
      messages.push('You have to write LMS course name.');
    }
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
    var lms_instance_id, lms_course_id, lms_course_name, organization_id, course_id, term_id, label, late_policy_id, inst_book_id, fd, messages, url;
    messages = check_completeness();
    if (messages.length !== 0) {
      form_alert(messages);
      $('#btn-submit-co').prop('disabled', false);
      return;
    }
    lms_instance_id = $('#lms-instance-select').val();
    lms_access_token = $('#lms-access-token').val();
    lms_course_id = $('#lms-course-id').val();
    lms_course_name = $('#lms-course-name').val();
    organization_id = $('#organization-select').val();
    course_id = $('#course-select').val();
    term_id = $('#term-select').val();
    label = $('#label').val();
    // late_policy_id = $('#late-policy-select').val();
    inst_book_id = $('#inst-book-select').val();
    fd = new FormData;
    fd.append('lms_instance_id', lms_instance_id);
    fd.append('lms_course_id', lms_course_id);
    fd.append('lms_course_name', lms_course_name);
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