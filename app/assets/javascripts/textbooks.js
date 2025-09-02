(function () {
    var check_completeness, form_alert, handle_submit, handle_generate_textbook, init, reset_alert_area, valid_token;

    $(document).ready(function () {

      $('#organization-select').change(function () {
        return load_courses();
      });

      $('#lms-instance-select').change(function () {
        return handle_lms_access();
      });

      $('#lms-access-token').change(function () {
        $("#lms-access-token-check").hide("slow");
        // return handle_access_token();

      });

      $('#btn-submit-co').click(function () {
        $(this).prop('disabled', true);
        return handle_submit();
      });

      $('#btn-gen-textbook').click(function () {
        console.log("here")
        $(this).prop('disabled', true);
        return handle_generate_textbook();
      });

      $('#display').click(function () {
        return handle_select_student();
        //return handle_display();
      });

      $('#inst-book-select').on('change', function () {
        var bookId = this[this.selectedIndex].value;
        if (!bookId) return;
        validate_book_config(bookId);
      });

      init();
    });

    load_courses = function () {
      var request = "/courses/" + $('#organization-select').val() + "/search";

      var aj = $.ajax({
        url: request,
        type: 'get',
        data: $(this).serialize()
      }).done(function (data) {
        change_courses(data);
      }).fail(function (data) {
        console.log('AJAX request has FAILED');
      });
    };

    handle_lms_access = function () {
      if ($('#lms-instance-select').val()) {
        var request = "/lms_accesses/" + $('#lms-instance-select').val() + "/search";

        var aj = $.ajax({
          url: request,
          type: 'get',
          data: $(this).serialize()
        }).done(function (data) {
          if (data) {
            if (data['access_token'] != null) {
              $('#lms-access-token').val(data['access_token']);
              // $("#lms-access-update-btn").show("slow");
              // $("#lms-access-token-group").hide("slow");
            } else {
              $('#lms-access-token').val('');
            }
            $("#lms-access-token-check").removeClass("fa-times");
            $("#lms-access-token-check").removeClass("fa-check");
            valid_token = data['valid_token'];
            if (data['valid_token']) {
              $("#lms-access-token-check").addClass("fa-check")
              $("#lms-access-token-desc").hide("slow");
            } else {
              $("#lms-access-token-check").addClass("fa-times")
              $("#lms-access-token-desc").show("slow");
            }
            $("#lms-access-token-check").show("slow");
          }
        }).fail(function (data) {
          console.log('AJAX request has FAILED');
        });
      }
    };

    //modify the course dropdown
    change_courses = function (data) {
      $("#course-select").empty();
      for (i = 0; i < data.length; i++) {
        $("#course-select").append(
          $("<option></option>").attr("value", data[i].id).text(data[i].number + ': ' + data[i].name)
        );
      }
    };

    init = function () {
      // $("#lms-access-update-btn").hide();
      $("#lms-access-token-check").hide();
      $("#lms-access-token-desc").hide();
      // $("#lms-access-token-group").hide();
    };

    form_alert = function (messages) {
      var alert_list, message, _fn, _i, _len;
      reset_alert_area();
      alert_list = $('#alerts').find('.alert ul');
      _fn = function (message) {
        return alert_list.append('<li>' + message + '</li>');
      };
      for (_i = 0, _len = messages.length; _i < _len; _i++) {
        message = messages[_i];
        _fn(message);
      }
      return $('#alerts').css('display', 'block');
    };

    reset_alert_area = function () {
      var alert_box;
      $('#alerts').find('.alert').alert('close');
      alert_box = "<div class='alert alert-danger alert-dismissable' role='alert'>" + "<button class='close' data-dismiss='alert' aria-label='Close'><i class='fa fa-times'></i></button>" + "<ul></ul>" + "</div>";
      return $('#alerts').append(alert_box);
    };

    check_completeness = function (isTextbook) {
      var messages;
      messages = [];

      if (!isTextbook){
        if (!valid_token) {
          messages.push('You have to provide an access token for the selected Canvas instance.');
        }
        if ($('#lms-course-num').val() === '') {
          messages.push('You have to write LMS course Id.');
        }
        if ($('#lms-instance-select').val() === '') {
          messages.push('One of the LMS instances has to be selected.');
        }
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

    validate_book_config = function (bookId) {
      $.ajax({
        url: '/inst_books/' + bookId + '/validate',
        type: 'get'
      }).done(function (data) {
        if (data.res.length > 0) {
          var msg = 'WARNING - the following modules are listed in the selected book configuration but no longer exist on the OpenDSA server:\n';
          for (var i = 0; i < data.res.length; i++) {
            msg += '\n\t- ' + data.res[i].name + ' (' + data.res[i].path + ')';
          }
          msg += '\n\nIf you create a course using this book configuration, THESE MODULES WILL NOT BE ACCESSIBLE. It is highly recommended that you create/use an updated book configuration.';
          alert(msg);
        }
      }).fail(function (error) {
        console.error('AJAX request has FAILED');
        console.error(error);
      });
    };

    handle_generate_textbook = function () {
      console.log("working on standalone textbook")
    var organization_id, course_id, term_id, label, inst_book_id, fd, messages, url;
    messages = check_completeness(true);
    if (messages.length !== 0) {
      form_alert(messages);
      $('#btn-gen-textbook').attr('disabled', false);
      return;
    }
    organization_id = $('#organization-select').val();
    course_id = $('#course-select').val();
    term_id = $('#term-select').val();
    label = $('#label').val();
    inst_book_id = $('#inst-book-select').val();
    fd = new FormData;
    fd.append('organization_id', organization_id);
    fd.append('course_id', course_id);
    fd.append('term_id', term_id);
    fd.append('label', label);
    fd.append('inst_book_id', inst_book_id);
    url = '/textbooks'
    return $.ajax({
      url: url,
      type: 'post',
      data: fd,
      processData: false,
      contentType: false,
      success: function (data) {
        return window.location.href = data['url'];
      }
    });
  };


    handle_submit = function () {
      var lms_instance_id, lms_course_num, lms_course_code, organization_id, course_id, term_id, label, late_policy_id, inst_book_id, fd, messages, url;
      messages = check_completeness(false);
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
        success: function (data) {
          return window.location.href = data['url'];
        }
      });
    };

    handle_select_student = function () {
      var messages = check_dis_completeness();
      if (messages.length !== 0) {
        alert(messages);
        return;
      }
      //GET /course_offerings/:user_id/course_offering_id/exercise_list
      var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + $('display').attr('name') + "/exercise_list";
      var aj = $.ajax({
        url: request,
        type: 'get',
        data: $(this).serialize()
      }).done(function (data) {
        if (data.odsa_exercise_progress.length === 0) {
          var p = '<p style="font-size:24px; align=center;"> Select a student name <p>';
          $('#log').html(p);
        } else {
          //$('#log').html(p);
          $('#log').append("<%= j render(:partial => 'views/lti/show_individual_exercise') %>");
        }
        change_courses(data);
      }).fail(function (data) {
        alert("failure")
        console.log('AJAX request has FAILED');
      });
    }

    handle_display = function () {
      var messages = check_dis_completeness();
      if (messages.length !== 0) {
        alert(messages);
        return;
      }
      //GET /course_offerings/:user_id/:inst_section_id/section
      var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + $('#comb').find('option:selected').val() + "/section";

      var aj = $.ajax({
        url: request,
        type: 'get',
        data: $(this).serialize()
      }).done(function (data) {
        if (data.odsa_exercise_progress.length === 0) {
          var p = '<p style="font-size:24px; align=center;"> You have not Attempted this exercise <p>';
          $('#log').html(p);
        } else {
          var header = '<p style="font-size:24px; align=center;"> OpenDSA Progres Table<p>';
          header += '<table>';
          header += '<tr>';
          var elem = '<tr>';
          header += buildProgressHeader();
          elem += getFieldMember(data.odsa_exercise_progress[0], data.odsa_exercise_attempts);
          var header1 = '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table <p>';
          header1 += '<table>';
          header1 += '<tr>';
          var elem1 = '<tr>';
          header1 += getAttemptHeader();
          var proficiencyFlag = -1;
          for (var i = 0; i < data.odsa_exercise_attempts.length; i++) {
            if (data.odsa_exercise_attempts[i].earned_proficiency != null && data.odsa_exercise_attempts[i].earned_proficiency && proficiencyFlag == -1) {
              proficiencyFlag = 1;
              elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag);
              proficiencyFlag = 2;
            } else {
              elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag);
            }
          }
          header1 += elem1;
          header += elem;
          header += '</table> ';
          header1 += '</table>';
          header += '<br>' + header1;
          $('#log').html(header);
        }
        change_courses(data);
      }).fail(function (data) {
        alert("failure")
        console.log('AJAX request has FAILED');
      });
    };

    getFieldMember = function (pData, attempts) {
      console.dir(pData)
      var member = '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.current_score + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.highest_score + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.total_correct + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + attempts.length + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.proficient_date.substring(0, 10) + " " + pData.proficient_date.substring(11, 16) + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.first_done.substring(0, 10) + " " + pData.first_done.substring(11, 16) + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.last_done.substring(0, 10) + " " + pData.last_done.substring(11, 16) + '</th>';
      return member;
    }

    buildProgressHeader = function () {
      var elem = '<tr> <th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Current Score </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Highest Score </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Tottal Correct </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Tottal Attempts </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Proficient Date </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> First Done </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Last Done </th> </tr>';
      return elem
    }

    getAttemptHeader = function () {
      var head = '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Question name </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Request Type </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Correct </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Worth Credit </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Done </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Taken (s)</th>';
      return head;
    }

    getAttemptMemeber = function (aData, j) {
      var memb = "";
      console.dir(aData.earned_proficiency + " and j = " + j)
      if (aData.earned_proficiency != null && j == 1) {
        memb += '<tr bgcolor="#FF0000"><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
      } else {
        memb += '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
      }
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.request_type + '</th>';
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.correct + '</th>';
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.worth_credit + '</th>';
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_done.substring(0, 10) + " " + aData.time_done.substring(11, 16) + '</th>';
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_taken + '</th>';

      return memb;


    }

    check_dis_completeness = function () {
      var messages;
      messages = [];
      var selectbar1 = $('#combobox').find('option:selected').text();
      //var selectbar2 = $('#comb').find('option:selected').text();
      // || selectbar2 === ''
      debugger;
      console.log(selectbar1)
      if (selectbar1 === '') {
        messages.push("You need to select a student or assignment =" + selectbar1);
        return messages;
      }
      return messages
    };

  }).call(this);
