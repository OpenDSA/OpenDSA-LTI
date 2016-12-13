(function() {
  var check_completeness, clear_student_search, disable_dates, form_alert, get_exercises, get_offerings, get_offerings_with_extensions, handle_submit, init, init_datepickers, init_exercises, init_row_datepickers, init_student_extensions, init_templates, remove_extensions_if_any, reset_alert_area, search_students, validate_workout_name;

  $(document).ready(function() {

    $('#organization-select').change(function() { //change majors when user changes school
      return load_courses();
    });

    $('#lms-instance-select').change(function() { //change majors when user changes school
      return handle_lms_access();
    });

    return $('#btn-submit-co').click(function() {
      return handle_submit();
    });
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
          $("#lms-access-update-btn").show();
          $("#lms-access-token").hide();
        } else {
          $("#lms-access-update-btn").hide();
          $("#lms-access-token").show();
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
  };

  remove_extensions_if_any = function(course_offering_id) {
    var extension, extensions, index, to_remove, _fn, _fn1, _i, _j, _len, _len1;
    extensions = $('#student-extension-fields tbody').find('tr');
    to_remove = [];
    _fn = function(extension) {
      var offering;
      offering = $(extension).data('course-offering-id');
      if (offering === course_offering_id) {
        return to_remove.push($(extension).index());
      }
    };
    for (_i = 0, _len = extensions.length; _i < _len; _i++) {
      extension = extensions[_i];
      _fn(extension);
    }
    if (to_remove.length > 0) {
      if (confirm('Removing this workout offering will also remove ' + to_remove.length + ' student extension(s).')) {
        _fn1 = function(index) {
          var id;
          id = $($(extensions)[index]).data('id');
          if ((id != null) && id !== '') {
            window.codeworkout.removed_extensions.push(id);
          }
          return $(extensions)[index].remove();
        };
        for (_j = 0, _len1 = to_remove.length; _j < _len1; _j++) {
          index = to_remove[_j];
          _fn1(index);
        }
        if (extensions.length === 0) {
          $('#extensions').css('display', 'none');
        }
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  };

  init_templates = function() {
    $.get(window.codeworkout.exercise_template_path, function(template, textStatus, jqXHr) {
      window.codeworkout.exercise_template = template;
      if ($('body').is('.workouts.edit') || $('body').is('.workouts.clone')) {
        return init_exercises();
      }
    });
    return $.get(window.codeworkout.extension_template_path, function(template, textStatus, jqXHr) {
      window.codeworkout.student_extension_template = template;
      if ($('body').is('.workouts.edit')) {
        return init_student_extensions();
      }
    });
  };

  clear_student_search = function() {
    $('#extension-modal #modal-header').empty();
    $('#extension-modal .msg').empty();
    $('#students').empty();
    return $('#terms').val('');
  };

  search_students = function(course_offering_id) {
    return $.ajax({
      url: '/course_offerings/' + course_offering_id + '/search_students',
      type: 'get',
      data: {
        terms: $('#terms').val()
      },
      cache: true,
      dataType: 'script',
      success: function(data) {}
    });
  };

  validate_workout_name = function() {
    var can_update, name_field;
    can_update = $('#workout-offering-fields').data('can-update');
    name_field = $('#wo-name');
    if (can_update === false) {
      if (name_field.val() === name_field.data('old-name')) {
        $('#clone-msg').css('display', 'block');
        return false;
      } else {
        $('#clone-msg').css('display', 'none');
        return true;
      }
    }
    return true;
  };

  init_student_extensions = function() {
    var extension, student_extensions, _i, _len, _results;
    student_extensions = $('#extensions').data('student-extensions');
    if (student_extensions) {
      if (student_extensions.length > 0) {
        $('#extensions').css('display', 'block');
      }
      _results = [];
      for (_i = 0, _len = student_extensions.length; _i < _len; _i++) {
        extension = student_extensions[_i];
        _results.push((function(extension) {
          var data, template;
          data = {
            id: extension.id,
            course_offering_id: extension.course_offering_id,
            course_offering_display: extension.course_offering_display,
            student_id: extension.student_id,
            student_display: extension.student_display,
            time_limit: extension.time_limit,
            opening_date: extension.opening_date,
            soft_deadline: extension.soft_deadline,
            hard_deadline: extension.hard_deadline
          };
          template = $(Mustache.render($(window.codeworkout.student_extension_template).filter('#extension-template').html(), data));
          $('#student-extension-fields tbody').append(template);
          return init_row_datepickers(template);
        })(extension));
      }
      return _results;
    }
  };

  init_exercises = function() {
    var exercise, exercises, _fn, _i, _len;
    exercises = $('#ex-list').data('exercises');
    if (exercises) {
      _fn = function(exercise) {
        var data;
        data = {
          id: exercise.id,
          exercise_workout_id: exercise.exercise_workout_id,
          name: exercise.name,
          points: exercise.points
        };
        return $('#ex-list').append(Mustache.render($(window.codeworkout.exercise_template).filter('#exercise-template').html(), data));
      };
      for (_i = 0, _len = exercises.length; _i < _len; _i++) {
        exercise = exercises[_i];
        _fn(exercise);
      }
      return $('#ex-list').removeData('exercises');
    }
  };

  init_datepickers = function() {
    var extension, extensions, offering, offerings, _fn, _i, _j, _len, _len1, _results;
    offerings = $('tr', '#workout-offering-fields tbody');
    _fn = function(offering) {
      return init_row_datepickers(offering);
    };
    for (_i = 0, _len = offerings.length; _i < _len; _i++) {
      offering = offerings[_i];
      _fn(offering);
    }
    extensions = $('tr', '#student-extension-fields tbody');
    _results = [];
    for (_j = 0, _len1 = extensions.length; _j < _len1; _j++) {
      extension = extensions[_j];
      _results.push((function(extension) {
        return init_row_datepickers(extension);
      })(extension));
    }
    return _results;
  };

  init_row_datepickers = function(row) {
    var hard_date, hard_datepicker, opening_date, opening_datepicker, soft_date, soft_datepicker;
    opening_datepicker = $('.input-group.opening-datepicker', $(row));
    soft_datepicker = $('.input-group.soft-datepicker', $(row));
    hard_datepicker = $('.input-group.hard-datepicker', $(row));
    if (opening_datepicker.val() === '' || (opening_datepicker.data('DateTimePicker').date() == null)) {
      opening_datepicker.datetimepicker({
        useCurrent: false
      });
    }
    if (soft_datepicker.val() === '' || (soft_datepicker.data('DateTimePicker').date() == null)) {
      soft_datepicker.datetimepicker({
        useCurrent: false,
        minDate: opening_datepicker.data('DateTimePicker').minDate()
      });
    }
    if (hard_datepicker.val() === '' || (hard_datepicker.data('DateTimePicker').date() == null)) {
      hard_datepicker.datetimepicker({
        useCurrent: false,
        minDate: soft_datepicker.data('DateTimePicker').minDate()
      });
    }
    opening_datepicker.on('dp.change', function(e) {
      if (e.date != null) {
        soft_datepicker.data('DateTimePicker').minDate(e.date);
        return disable_dates(hard_datepicker, soft_datepicker, opening_datepicker, 'minDate');
      }
    });
    soft_datepicker.on('dp.change', function(e) {
      if (e.date != null) {
        opening_datepicker.data('DateTimePicker').maxDate(e.date);
        return hard_datepicker.data('DateTimePicker').minDate(e.date);
      }
    });
    hard_datepicker.on('dp.change', function(e) {
      if (e.date != null) {
        soft_datepicker.data('DateTimePicker').maxDate(e.date);
        return disable_dates(opening_datepicker, soft_datepicker, hard_datepicker, 'maxDate');
      }
    });
    if ($('body').is('.workouts.edit')) {
      if ((opening_datepicker.data('date') != null) && opening_datepicker.data('date') !== '') {
        opening_date = moment.unix(parseInt(opening_datepicker.data('date')));
        opening_datepicker.data('DateTimePicker').defaultDate(opening_date);
      }
      if ((soft_datepicker.data('date') != null) && soft_datepicker.data('date') !== '') {
        soft_date = moment.unix(parseInt(soft_datepicker.data('date')));
        soft_datepicker.data('DateTimePicker').defaultDate(soft_date);
      }
      if ((hard_datepicker.data('date') != null) && hard_datepicker.data('date') !== '') {
        hard_date = moment.unix(parseInt(hard_datepicker.data('date')));
        hard_datepicker.data('DateTimePicker').defaultDate(hard_date);
      }
      disable_dates(opening_datepicker, soft_datepicker, hard_datepicker, 'maxDate');
      disable_dates(soft_datepicker, opening_datepicker, void 0, 'minDate');
      disable_dates(soft_datepicker, hard_datepicker, void 0, 'maxDate');
      return disable_dates(hard_datepicker, soft_datepicker, opening_datepicker, 'minDate');
    }
  };

  disable_dates = function(this_datepicker, preferred_datepicker, backup_datepicker, min_max) {
    var backup_date, preferred_date;
    preferred_date = preferred_datepicker != null ? preferred_datepicker.data('DateTimePicker').date() : void 0;
    backup_date = backup_datepicker != null ? backup_datepicker.data('DateTimePicker').date() : void 0;
    if (preferred_date != null) {
      return this_datepicker.data('DateTimePicker')[min_max](preferred_date);
    } else if (backup_date != null) {
      return this_datepicker.data('DateTimePicker')[min_max](backup_date);
    }
  };

  get_exercises = function() {
    var ex_id, ex_obj, ex_points, exercises, exs, i, position;
    exs = $('#ex-list li');
    exercises = {};
    i = 0;
    while (i < exs.length) {
      ex_id = $(exs[i]).data('id');
      ex_points = $(exs[i]).find('.points').val();
      if (ex_points === '') {
        ex_points = '0';
      }
      ex_obj = {
        id: ex_id,
        points: ex_points
      };
      position = i + 1;
      exercises[position.toString()] = ex_obj;
      i++;
    }
    return exercises;
  };

  get_offerings = function() {
    var offering_row, offering_rows, offerings, _fn, _i, _len;
    offerings = {};
    offering_rows = $('tr', '#workout-offering-fields tbody');
    _fn = function(offering_row) {
      var hard_datepicker, hard_deadline, offering, offering_fields, offering_id, opening_date, opening_datepicker, soft_datepicker, soft_deadline;
      offering_fields = $('td', $(offering_row));
      offering_id = $(offering_fields[0]).data('course-offering-id');
      if (offering_id !== '') {
        opening_datepicker = $('.opening-datepicker', $(offering_fields[1])).data('DateTimePicker').date();
        soft_datepicker = $('.soft-datepicker', $(offering_fields[2])).data('DateTimePicker').date();
        hard_datepicker = $('.hard-datepicker', $(offering_fields[3])).data('DateTimePicker').date();
        opening_date = opening_datepicker != null ? opening_datepicker.toDate().toString() : null;
        soft_deadline = soft_datepicker != null ? soft_datepicker.toDate().toString() : null;
        hard_deadline = hard_datepicker != null ? hard_datepicker.toDate().toString() : null;
        offering = {
          opening_date: opening_date,
          soft_deadline: soft_deadline,
          hard_deadline: hard_deadline,
          published: published,
          extensions: []
        };
        return offerings[offering_id.toString()] = offering;
      }
    };
    for (_i = 0, _len = offering_rows.length; _i < _len; _i++) {
      offering_row = offering_rows[_i];
      _fn(offering_row);
    }
    return offerings;
  };

  get_offerings_with_extensions = function() {
    var extension_row, extension_rows, offerings, _fn, _i, _len;
    offerings = get_offerings();
    extension_rows = $('tr', '#student-extension-fields tbody');
    _fn = function(extension_row) {
      var course_offering_id, extension, extension_fields, hard_datepicker, hard_deadline, opening_date, opening_datepicker, soft_datepicker, soft_deadline, student_id, time_limit;
      extension_fields = $('td', $(extension_row));
      student_id = $(extension_row).data('student-id');
      course_offering_id = $(extension_row).data('course-offering-id');
      time_limit = $('.time_limit', $(extension_fields[5])).val();
      opening_datepicker = $('.opening-datepicker', $(extension_fields[2])).data('DateTimePicker').date();
      soft_datepicker = $('.soft-datepicker', $(extension_fields[3])).data('DateTimePicker').date();
      hard_datepicker = $('.hard-datepicker', $(extension_fields[4])).data('DateTimePicker').date();
      opening_date = opening_datepicker != null ? opening_datepicker.toDate().toString() : null;
      soft_deadline = soft_datepicker != null ? soft_datepicker.toDate().toString() : null;
      hard_deadline = hard_datepicker != null ? hard_datepicker.toDate().toString() : null;
      extension = {
        student_id: student_id,
        time_limit: time_limit,
        opening_date: opening_date,
        soft_deadline: soft_deadline,
        hard_deadline: hard_deadline
      };
      return offerings[course_offering_id.toString()]['extensions'].push(extension);
    };
    for (_i = 0, _len = extension_rows.length; _i < _len; _i++) {
      extension_row = extension_rows[_i];
      _fn(extension_row);
    }
    return offerings;
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
      return;
    }
    lms_instance_id = $('#lms-instance-select').val();
    lms_course_id = $('#lms-course-id').val();
    lms_course_name = $('#lms-course-name').val();
    organization_id = $('#organization-select').val();
    course_id = $('#course-select').val();
    term_id = $('#term-select').val();
    label = $('#label').val();
    late_policy_id = $('#late-policy-select').val();
    inst_book_id = $('#inst-book-select').val();
    fd = new FormData;
    fd.append('lms_instance_id', lms_instance_id);
    fd.append('lms_course_id', lms_course_id);
    fd.append('lms_course_name', lms_course_name);
    fd.append('organization_id', organization_id);
    fd.append('course_id', course_id);
    fd.append('term_id', term_id);
    fd.append('label', label);
    fd.append('late_policy_id', late_policy_id);
    fd.append('inst_book_id', inst_book_id);
    url = '/course_offerings'
    return $.ajax({
      url: url,
      type: 'post',
      data: fd,
      processData: false,
      contentType: false,
      success: function(data) {
        console.log(data);
        return window.location.href = data['url'];
      }
    });
  };

}).call(this);