$(function () {
  //////////////////////
  // Exercises Lookup //
  //////////////////////
  $.widget("custom.combobox", {
    _create: function () {
      this.wrapper = $("<span>")
        .addClass("custom-combobox")
        .addClass("custom-comb")
        .insertAfter(this.element);

      this.element.hide();
      this._createAutocomplete();
      this._createShowAllButton();
    },

    _createAutocomplete: function () {
      var selected = this.element.children(":selected"),
        value = selected.val() ? selected.text() : "";

      this.input = $("<input>")
        .appendTo(this.wrapper)
        .val(value)
        .attr("title", "")
        .addClass("custom-combobox-input ui-widget ui-widget-content ui-state-default ui-corner-left")
        .addClass("custom-comb-input ui-widget ui-widget-content ui-state-default ui-corner-left")
        .autocomplete({
          delay: 0,
          minLength: 0,
          source: $.proxy(this, "_source")
        })
        .tooltip({
          classes: {
            "ui-tooltip": "ui-state-highlight"
          }
        });

      this._on(this.input, {
        autocompleteselect: function (event, ui) {
          ui.item.option.selected = true;
          this._trigger("select", event, {
            item: ui.item.option
          });
        },

        autocompletechange: "_removeIfInvalid"
      });
    },

    _createShowAllButton: function () {
      var input = this.input,
        wasOpen = false;

      $("<a>")
        .attr("tabIndex", -1)
        .attr("title", "Show All Items")
        .tooltip()
        .appendTo(this.wrapper)
        .button({
          icons: {
            primary: "ui-icon-triangle-1-s"
          },
          text: false
        })
        .removeClass("ui-corner-all")
        .addClass("custom-combobox-toggle ui-corner-right")
        .addClass("custom-comb-toggle ui-corner-right")
        .on("mousedown", function () {
          wasOpen = input.autocomplete("widget").is(":visible");
        })
        .on("click", function () {
          input.trigger("focus");

          // Close if already visible
          if (wasOpen) {
            return;
          }

          // Pass empty string as value to search for, displaying all results
          input.autocomplete("search", "");
        });
    },

    _source: function (request, response) {
      var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
      response(this.element.children("option").map(function () {
        var text = $(this).text();
        if (this.value && (!request.term || matcher.test(text)))
          return {
            label: text,
            value: text,
            option: this
          };
      }));
    },

    _removeIfInvalid: function (event, ui) {

      // Selected an item, nothing to do
      if (ui.item) {
        return;
      }

      // Search for a match (case-insensitive)
      var value = this.input.val(),
        valueLowerCase = value.toLowerCase(),
        valid = false;
      this.element.children("option").each(function () {
        if ($(this).text().toLowerCase() === valueLowerCase) {
          this.selected = valid = true;
          return false;
        }
      });

      // Found a match, nothing to do
      if (valid) {
        return;
      }

      // Remove invalid value
      this.input
        .val("")
        .attr("title", value + " didn't match any item")
        .tooltip("open");
      this.element.val("");
      this._delay(function () {
        this.input.tooltip("close").attr("title", "");
      }, 2500);
      this.input.autocomplete("instance").term = "";
    },

    _destroy: function () {
      this.wrapper.remove();
      this.element.show();
    }
  });

  $(function () {
    // $("#tools-accordion").accordionjs({ closeAble: true });
    $("#combobox").combobox();
    $("#toggle").on("click", function () {
      $("#combobox").toggle();
    });

    $("#comb").combobox();
    $("#toggle").on("click", function () {
      $("#comb").toggle();
    });

    $('#select').click(function () {
      $('#log').html("");
      $('#display_table').html("");
      return handle_select_student();
      //handle_select_student();
      //handle_display()
    });

    function clearContainers() {
      $('#overview-container').css('display', 'none');
      $('#detail-container').css('display', 'none');
      $('#mst-container').css('display', 'none');
      $('#log').html('');
      $('#display_table').html('');
    }

    $('#ex-btn-multi').on('click', function () {
      clearContainers()
      $('#overview-container').css('display', '');
      console.log('multi')
    });

    $('#ex-btn-single').on('click', function () {
      clearContainers()
      $('#detail-container').css('display', '');
      console.log('single')
    });


    //
    // selectize code
    //
    $selectize_students = $('#select-for-students')
      .selectize({
        persist: false,
        valueField: 'id',
        labelField: 'name',
        searchField: ['first_name', 'last_name'],
        sortField: [
          { field: 'first_name', direction: 'asc' },
          { field: 'last_name', direction: 'asc' }
        ],
        options: window.ODSA_DATA.student_list,
        render: {
          item: function (item, escape) {
            var name = $.trim((item.first_name || '') + ' ' + (item.last_name || ''))
            return '<div>' +
              (name ? '<span class="name">' + escape(name) + '</span>' : '') +
              '</div>';
          },
          option: function (item, escape) {
            var name = $.trim((item.first_name || '') + ' ' + (item.last_name || ''))
            return '<div>' +
              '<span class="label">' + escape(name) + '</span>' +
              '</div>';
          }
        }
      })

    var selectize_students = $selectize_students[0].selectize;

    $('select#select-for-students.selectized')
      .each(function () {
        var $input = $(this);

        var update = function (e) {
          console.log($input.val())
        }
        $(this).on('change', update);
      });



    $('#btn-select-module').on('click', handle_module_display);

    $('#btn-module-csv').on('click', function () {
      var headers = $('#mst-header-row')[0];
      var tbody = $('#mst-body')[0];
      var csv = table2csv(headers, tbody, [[/ \(\?\)/g, '']]);

      var dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(csv);
      var modules = $('#select-module')[0];
      var selectedModule = modules.options[modules.selectedIndex].innerText
        .replace('-', '_')
        .replace(/\./g, '-')
        .replace(/\s/g, '');

      var exportName = selectedModule + '_' + getTimestamp(new Date());
      var downloadAnchorNode = document.createElement('a');
      downloadAnchorNode.setAttribute("href", dataStr);
      downloadAnchorNode.setAttribute("download", exportName + ".csv");
      downloadAnchorNode.style.display = 'none';
      document.body.appendChild(downloadAnchorNode);
      downloadAnchorNode.click();
      downloadAnchorNode.remove();
    });
  });

  function getTimestamp(date, format) {
    var format = format || "yyyy-mm-dd"
    var month = date.getMonth() + 1;
    if (month < 10) month = '0' + month;
    var day = date.getDate();
    if (day < 10) day = '0' + day;
    var hour = date.getHours();
    if (hour < 10) hour = '0' + hour;
    var minute = date.getMinutes();
    if (minute < 10) minute = '0' + minute;
    var second = date.getSeconds();
    if (second < 10) second = '0' + second;

    if (format == 'yyyymmdd') {
      return [date.getFullYear(), month, day].join('');
    } else {
      return [date.getFullYear(), month, day].join('-');
    }
  }

  function table2csv(headers, body, replacements) {
    if (!replacements) replacements = [];
    var csv = '';
    for (var i = 0; i < headers.children.length; i++) {
      var cell = headers.children[i];
      var text = cell.innerText;
      for (var j = 0; j < replacements.length; j++) {
        var replacement = replacements[j];
        text = text.replace(replacement[0], replacement[1]);
      }
      csv += '"' + text + '",';
    }
    csv += '\n';

    for (var i = 0; i < body.children.length; i++) {
      var row = body.children[i];
      for (var j = 0; j < row.children.length; j++) {
        var cell = row.children[j];
        csv += '"' + cell.innerText + '",';
      }
      csv += '\n';
    }
    return csv;
  }

  function handle_module_display() {
    var messages = check_dis_completeness("modules_table");
    if (messages.length !== 0) {
      alert(messages);
      $('#display_table').html('');
      return;
    }

    $('#spinner').css('display', '');
    $.ajax({
      url: "/course_offerings/" + ODSA_DATA.course_offering_id + "/modules/" + $('#select-module').val() + "/progresses",
      type: 'get'
    })
      .done(function (data) {

        var exHeader = $('#exercise-info-header');
        var headers = $('#mst-header-row');
        var tbody = $('#mst-body');
        var exInfoColStartIdx = 8;
        headers.children().slice(exInfoColStartIdx).remove();
        tbody.empty();

        // create a column for each exercise
        var points_possible = 0;
        for (var i = 0; i < data.exercises.length; i++) {
          var ex = data.exercises[i];
          ex.points = parseFloat(ex.points);
          points_possible += ex.points;
          headers.append('<th>' + ex.inst_exercise.name + ' (' + ex.points + 'pts)</th>');
        }
        exHeader.attr('colSpan', data.exercises.length);

        var enrollments = {};
        for (i = 0; i < data.enrollments.length; i++) {
          var enrollment = data.enrollments[i];
          enrollments[enrollment.user_id] = enrollment;
        }

        // create a row for each student
        var html = '';
        for (i = 0; i < data.students.length; i++) {
          var student = data.students[i];
          var have_ex_data = false;
          if (enrollments[student.id]) {
            student = enrollments[student.id].user;
            have_ex_data = true;
          }
          html += '<tr>';
          html += '<td>' + student.first_name + '</td>';
          html += '<td>' + student.last_name + '</td>';
          html += '<td>' + student.email + '</td>';
          if (have_ex_data) {
            var eps = student.odsa_exercise_progresses;
            var mp = student.odsa_module_progresses[0];
            var latest_proficiency = new Date(0);
            var exhtml = '';
            // match up exercises and exercise progresses
            for (var j = 0; j < data.exercises.length; j++) {
              var found = false;
              var ex = data.exercises[j];
              for (var k = 0; k < eps.length; k++) {
                if (ex.id === eps[k].inst_book_section_exercise_id) {
                  if (eps[k].highest_score >= ex.threshold) {
                    exhtml += '<td class="success">' + ex.points + '</td>';
                    var pdate = new Date(eps[k].proficient_date);
                    if (pdate > latest_proficiency) {
                      latest_proficiency = pdate;
                    }
                  }
                  else {
                    exhtml += '<td>0</td>';
                  }
                  found = true;
                  break;
                }
              }
              if (!found) {
                exhtml += '<td>0</td>';
              }
            }
            html += '<td>' + parseFloat((mp.highest_score * points_possible).toFixed(2)) + '</td>';
            html += '<td>' + points_possible + '</td>';
            html += '<td>' + (mp.created_at ? new Date(mp.created_at).toLocaleString() : 'N/A') + '</td>';
            html += '<td>' + (mp.proficient_date ? new Date(mp.proficient_date).toLocaleString() : 'N/A') + '</td>';
            html += '<td>' + (latest_proficiency.getTime() > 0 ? latest_proficiency.toLocaleString() : 'N/A') + '</td>';
            html += exhtml;
          }
          else {
            // student has not attempted any exercise in this module
            html += '<td>0</td> <td>' + points_possible + '</td> <td>N/A</td> <td>N/A</td> <td>N/A</td>';
            for (var j = 0; j < data.exercises.length; j++) {
              html += '<td>0</td>';
            }
          }
          html += '</tr>';
        }
        tbody.append(html);
        $('#mst-container').css('display', '');
      }).fail(function (error) {
        console.log(error);
        try {
          alert('ERROR: ' + JSON.parse(error.responseText).message)
        }
        catch (ex) {
          alert("Failed to retrieve module progress data.\n" + error.responseText);
        }
      }).always(function () {
        $('#spinner').css('display', 'none');
      });
  }

  window.handle_display = function () {
    var messages = check_dis_completeness("table");
    if (messages.length !== 0) {
      alert(messages);
      $('#display_table').html('');
      return;
    }
    //GET /course_offerings/:user_id/:inst_section_id
    var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + $('#comb').find('option:selected').val() + "/section";
    $('#spinner').css('display', '');
    var aj = $.ajax({
      url: request,
      type: 'get',
      data: $(this).serialize()
    }).done(function (data) {
      if (data.odsa_exercise_progress.length == 0 || data.odsa_exercise_attempts.length == 0) {
        var p = '<p style="font-size:24px; align=center;"> You have not Attempted this exercise <p>';
        $('#display_table').html(p);
      } else if (data.odsa_exercise_attempts[0].pe_score != null || data.odsa_exercise_attempts[0].pe_steps_fixed != null) {

        var khan_ac_exercise = true;
        var header = '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
        header += '<table class="table"><thead>';
        var elem = '<tbody>';
        header += buildProgressHeader(khan_ac_exercise) + "</thead>";
        elem += getFieldMember(data.inst_section, data.odsa_exercise_progress[0], data.odsa_exercise_attempts, data.inst_book_section_exercise, khan_ac_exercise);
        var header1 = '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table' + data.odsa_exercise_attempts[0].question_name + '<p>';
        header1 += '<table class="table"><thead>';
        var elem1 = '<tbody>';
        header1 += getAttemptHeader(khan_ac_exercise) + "</thead>";
        var proficiencyFlag = -1;
        for (var i = 0; i < data.odsa_exercise_attempts.length; i++) {
          if (data.odsa_exercise_attempts[i].earned_proficiency != null && data.odsa_exercise_attempts[i].earned_proficiency && proficiencyFlag == -1) {
            proficiencyFlag = 1;
            elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag, khan_ac_exercise);
            proficiencyFlag = 2;
          } else {
            elem1 += getAttemptMemeber(data.odsa_exercise_attempts[i], proficiencyFlag, khan_ac_exercise);
          }
        }
        header1 += elem1;
        header += elem;
        header += '</tbody></table> ';
        header1 += '</tbody></table>';
        header += '<br>' + header1;
        $('#display_table').html(header);
      } else {

        var header = '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
        header += '<table class="table table-bordered"><thead>';
        var elem = '<tbody>';
        header += buildProgressHeader() + '</thead>';
        elem += getFieldMember(data.inst_section, data.odsa_exercise_progress[0], data.odsa_exercise_attempts, data.inst_book_section_exercise);
        var header1 = '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table <p>';
        header1 += '<table class="table table-bordered table-hover"><thead>';
        var elem1 = '<tbody>';
        header1 += getAttemptHeader() + '</thead>';
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
        header += '</tbody></table> ';
        header1 += '</tbody></table>';
        header += '<br>' + header1;
        $('#display_table').html(header);
      }

      //change_courses(data);
    }).fail(function (data) {
      alert("failure");
      console.log('AJAX request has FAILED');
    }).always(function () {
      $('#spinner').css('display', 'none');
    });
  }

  function getFieldMember(sData, pData, attempts, instBookSecEx, khan_ex) {
    // console.dir(pData)
    var member = '<tr>';
    var pointsEarned = pData.proficient_date ? instBookSecEx.points : 0;
    if (khan_ex == null || khan_ex == false) {
      member += '<td>' + pData.current_score + '</td>';
      member += '<td>' + pData.highest_score + '</td>';
    }
    member += '<td>' + pData.total_correct + '</td>';
    member += '<td>' + attempts.length + '</td>';
    member += '<td>' + pointsEarned + '</td>';
    member += '<td>' + instBookSecEx.points + '</td>';
    if (pData.proficient_date != null) {
      member += '<td>' + pData.proficient_date.substring(0, 10) + " " + pData.proficient_date.substring(11, 16) + '</td>';
    } else {
      member += '<td>N/A</td>';
    }
    member += '<td>' + pData.first_done.substring(0, 10) + " " + pData.first_done.substring(11, 16) + '</td>';
    member += '<td>' + pData.last_done.substring(0, 10) + " " + pData.last_done.substring(11, 16) + '</td>';
    //member += '<td>' + sData.lms_posted + '</td>';
    //member += '<td>' + sData.time_posted + '</td>';
    return member;
  }

  function buildProgressHeader(khan_ex) {
    var elem = '<tr>';
    if (khan_ex == null || khan_ex == false) {
      elem += '<th>Current Score</th>';
      elem += '<th>Highest Score</th>';
    }
    elem += '<th>Total Correct</th>';
    elem += '<th>Total Attempts</th>';
    elem += '<th>Points Earned</th>';
    elem += '<th>Points Possible</th>';
    elem += '<th>Proficient Date</th>';
    elem += '<th>First Done</th>';
    elem += '<th>Last Done</th>';
    //elem += '<th>Posted to Canvas?</th>';
    //elem += '<th>Time Posted</th></tr>';

    return elem;
  }

  function getAttemptHeader(khan_ex) {
    var head = '<tr>';
    if (khan_ex == null || khan_ex == false) {
      head += '<th>Question name</th>';
      head += '<th>Request Type</th>';
    } else {
      head += '<th>Pe Score</th>';
      head += '<th>Pe Steps</th>';
    }
    head += '<th>Correct</th>';
    head += '<th>Worth Credit</th>';
    head += '<th>Time Done</th>';
    head += '<th>Time Taken (s)</th>';
    return head;
  }

  function getAttemptMemeber(aData, j, khan_ex) {
    var memb = "<tr>";
    //console.dir(aData.earned_proficiency + " and j = " + j)
    if (khan_ex == null || khan_ex == false) {
      memb = '';
      if (aData.earned_proficiency != null && j == 1) {
        memb += '<tr class="success"><td>' + aData.question_name + '</td>';
      } else {
        memb += '<tr><td>' + aData.question_name + '</td>';
      }
      memb += '<td>' + aData.request_type + '</td>';
    } else {
      memb += '<td>' + aData.pe_score + '</td>';
      memb += '<td>' + aData.pe_steps_fixed + '</td>';
    }

    memb += '<td>' + aData.correct + '</td>';
    memb += '<td>' + aData.worth_credit + '</td>';
    memb += '<td>' + aData.time_done.substring(0, 10) + " " + aData.time_done.substring(11, 16) + '</td>';
    memb += '<td>' + aData.time_taken + '</td>';

    return memb;


  }

  function handle_select_student() {
    var messages = check_dis_completeness("individual_student");
    if (messages.length !== 0) {
      alert(messages);
      return;
    }
    //GET /course_offerings/:user_id/course_offering_id/exercise_list
    var al = $('#combobox').find('option:selected').val();
    var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + document.getElementById('select').name + "/exercise_list";
    $('#spinner').css('display', '');
    var aj = $.ajax({
      url: request,
      type: 'get',
      data: $(this).serialize()
    }).done(function (data) {
      if (data.odsa_exercise_attempts.length === 0) {
        var p = '<p style="font-size:24px; align=center;"> Select a student name <p>';
        $('#log').html(p);
      } else {
        //$('#log').html(p);

        //$('#log').html("<%= j render(partial: 'show_individual_exercise') %>")
        //<%= escape_javascript(render(:partial => 'lti/show_individual_exercise.html.haml')) %>");
        //.append("<%= j render(:partial => 'views/lti/show_individual_exercise') %>");
        //var elem = '<div class="ui-widget">';
        var elem = '<label class="control-label col-lg-2 col-sm-3">Select Exercise:</label>';
        elem += '<div class="col-xs-6"><select id="comb" class="form-control">';
        //elem += '<% @exercise_list.each do |k, q| %>';
        //elem += '<% if q[1] %>';
        var keys = Object.keys(data.odsa_exercise_attempts);
        var attempt_flag = false;
        for (var i = 0; i < keys.length; i++) {
          var exercise = data.odsa_exercise_attempts[keys[i]];
          if (exercise.length > 1) {
            attempt_flag = true
            elem += ' <option value="' + keys[i] + '">';
            elem += '<strong>' + exercise[0] + '</strong>';
            elem += '</option>';
          }
        }
        if (!attempt_flag) {
          elem += ' <option value="No_attempt">';
          elem += '<strong> No Attempts Made</strong>';
          elem += '</option>';
        }
        elem += '</select></div>';
        if (attempt_flag) {
          elem += '<input class="btn btn-primary" id="display" onclick="handle_display()" name="display" type="button" value="Display Detail"></input>';
        }
        $('#log').html(elem);

      }
      //change_courses(data);
    }).fail(function (data) {
      alert("failure");
      console.log('AJAX request has FAILED');
    }).always(function () {
      $('#spinner').css('display', 'none');
    });
  }

  function check_dis_completeness(flag) {
    var messages;
    messages = [];
    var selectbar1 = $('#combobox').find('option:selected').text();
    switch (flag) {
      case 'individual_student':
        if (selectbar1 === '') {
          messages.push("You need to select a student");
          return messages;
        }
        break;
      case 'table':
        var selectbar2 = $('#comb').find('option:selected').text();
        if (selectbar1 === '' || selectbar2 === '') {
          messages.push("You need to select a student or assignment");
          return messages;
        }
        break;
      case 'modules_table':
        if (!$("#select-module").val()) {
          messages.push('You need to select a module');
          return messages;
        }
        break;
      default:
        console.log("unknown error from odsa_tools.js module");
        alert("unknown error from odsa_tools.js module, written by: Souleymane Dia");
    }

    return messages;
  }
});
