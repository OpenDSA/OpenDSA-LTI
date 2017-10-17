$(function() {
  $.widget("custom.combobox", {
    _create: function() {
      this.wrapper = $("<span>")
        .addClass("custom-combobox")
        .addClass("custom-comb")
        .insertAfter(this.element);

      this.element.hide();
      this._createAutocomplete();
      this._createShowAllButton();
    },

    _createAutocomplete: function() {
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
        autocompleteselect: function(event, ui) {
          ui.item.option.selected = true;
          this._trigger("select", event, {
            item: ui.item.option
          });
        },

        autocompletechange: "_removeIfInvalid"
      });
    },

    _createShowAllButton: function() {
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
        .on("mousedown", function() {
          wasOpen = input.autocomplete("widget").is(":visible");
        })
        .on("click", function() {
          input.trigger("focus");

          // Close if already visible
          if (wasOpen) {
            return;
          }

          // Pass empty string as value to search for, displaying all results
          input.autocomplete("search", "");
        });
    },

    _source: function(request, response) {
      var matcher = new RegExp($.ui.autocomplete.escapeRegex(request.term), "i");
      response(this.element.children("option").map(function() {
        var text = $(this).text();
        if (this.value && (!request.term || matcher.test(text)))
          return {
            label: text,
            value: text,
            option: this
          };
      }));
    },

    _removeIfInvalid: function(event, ui) {

      // Selected an item, nothing to do
      if (ui.item) {
        return;
      }

      // Search for a match (case-insensitive)
      var value = this.input.val(),
        valueLowerCase = value.toLowerCase(),
        valid = false;
      this.element.children("option").each(function() {
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
      this._delay(function() {
        this.input.tooltip("close").attr("title", "");
      }, 2500);
      this.input.autocomplete("instance").term = "";
    },

    _destroy: function() {
      this.wrapper.remove();
      this.element.show();
    }
  });



});

(function() {

  console.dir("lti tablejs")

  $(document).ready(function() {
    $("#combobox").combobox();
    $("#toggle").on("click", function() {
      $("#combobox").toggle();
    });

    $("#comb").combobox();
    $("#toggle").on("click", function() {
      $("#comb").toggle();
    });

    $('#select').click(function() {
      console.log("clicked registered");
      return handle_select_student();
      //handle_select_student();
      //handle_display()
    });
    /*$('#display').click(function() {
      console.log("clicked registered");
      return handle_display();
    });*/

  });


  handle_display = function() {
    var messages = check_dis_completeness("table");
    if (messages.length !== 0) {
      alert(messages);
      $('#display_table').html('');
      return;
    }
    debugger;
    //GET /course_offerings/:user_id/:inst_section_id
    var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + $('#comb').find('option:selected').val();

    var aj = $.ajax({
      url: request,
      type: 'get',
      data: $(this).serialize()
    }).done(function(data) {
      if (data.odsa_exercise_progress.length == 0 || data.odsa_exercise_attempts.length == 0) {
        var p = '<p style="font-size:24px; align=center;"> You have not Attempted this exercise <p>';
        $('#display_table').html(p);
      } else if (data.odsa_exercise_attempts[0].pe_score != null || data.odsa_exercise_attempts[0].pe_steps_fixed != null) {

        var khan_ac_exercise = true;
        var header = '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
        header += '<table>';
        header += '<tr>';
        var elem = '<tr>';
        header += buildProgressHeader(khan_ac_exercise);
        elem += getFieldMember(data.inst_section, data.odsa_exercise_progress[0], data.odsa_exercise_attempts, khan_ac_exercise);
        var header1 = '<p style="font-size:24px; align=center;"> OpenDSA Attempt Table' + data.odsa_exercise_attempts[0].question_name + '<p>';
        header1 += '<table>';
        header1 += '<tr>';
        var elem1 = '<tr>';
        header1 += getAttemptHeader(khan_ac_exercise);
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
        header += '</table> ';
        header1 += '</table>';
        header += '<br>' + header1;
        $('#display_table').html(header);
      } else {

        var header = '<p style="font-size:24px; align=center;"> OpenDSA Progress Table<p>';
        header += '<table>';
        header += '<tr>';
        var elem = '<tr>';
        header += buildProgressHeader();
        elem += getFieldMember(data.inst_section, data.odsa_exercise_progress[0], data.odsa_exercise_attempts);
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
        $('#display_table').html(header);
      }

      //change_courses(data);
    }).fail(function(data) {
      alert("failure")
      console.log('AJAX request has FAILED');
    });
  };

  getFieldMember = function(sData, pData, attempts, kahn_ex) {
    // console.dir(pData)
    var member = '<tr>';
    if (kahn_ex == null || kahn_ex == false) {
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.current_score + '</th>';
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.highest_score + '</th>';
    }
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.total_correct + '</th>';
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + attempts.length + '</th>';
    if (pData.proficient_date != null) {
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.proficient_date.substring(0, 10) + " " + pData.proficient_date.substring(11, 16) + '</th>';
    } else {
      member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> N/A</th>';
    }
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.first_done.substring(0, 10) + " " + pData.first_done.substring(11, 16) + '</th>';
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + pData.last_done.substring(0, 10) + " " + pData.last_done.substring(11, 16) + '</th>';
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + sData.lms_posted + '</th>';
    member += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + sData.time_posted + '</th>';
    return member;
  }

  buildProgressHeader = function(kahn_ex) {
    var elem = '<tr>';
    if (kahn_ex == null || kahn_ex == false) {
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Current Score </th>';
      elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Highest Score </th>';
    }
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Total Correct </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Total Attempts </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Proficient Date </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> First Done </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Last Done </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Posted to Canvas? </th>';
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Posted </th> </tr>';

    return elem
  }
  getAttemptHeader = function(kahn_ex) {
    var head = '<tr>';
    if (kahn_ex == null || kahn_ex == false) {
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Question name </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Request Type </th>';
    } else {
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Pe Score </th>';
      head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Pe Steps </th>';
    }
    head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Correct </th>';
    head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Worth Credit </th>';
    head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Done </th>';
    head += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Taken (s)</th>';
    return head;
  }
  getAttemptMemeber = function(aData, j, kahn_ex) {
    var memb = "<tr>";
    //console.dir(aData.earned_proficiency + " and j = " + j)
    if (kahn_ex == null || kahn_ex == false) {
      memb = '';
      if (aData.earned_proficiency != null && j == 1) {
        memb += '<tr bgcolor="#008000"><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
      } else {
        memb += '<tr><th style="border: 1px solid #dddddd;text-align: left; padding: 8px;">' + aData.question_name + '</th>';
      }
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.request_type + '</th>';
    } else {
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.pe_score + '</th>';
      memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.pe_steps_fixed + '</th>';
    }

    memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.correct + '</th>';
    memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.worth_credit + '</th>';
    memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_done.substring(0, 10) + " " + aData.time_done.substring(11, 16) + '</th>';
    memb += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> ' + aData.time_taken + '</th>';

    return memb;


  }
  handle_select_student = function(){
        var messages = check_dis_completeness("individual_student");
        if (messages.length !== 0) {
            alert(messages);
            return;
        }
        //GET /course_offerings/:user_id/course_offering_id/exercise_list
        var al = $('#combobox').find('option:selected').val();
        var request = "/course_offerings/" + $('#combobox').find('option:selected').val() + "/" + document.getElementById('select').name + "/exercise_list";
        var aj = $.ajax({
            url: request,
            type: 'get',
            data: $(this).serialize()
        }).done(function(data) {
            if (data.odsa_exercise_attempts.length === 0) {
                var p = '<p style="font-size:24px; align=center;"> Select a student name <p>';
                $('#log').html(p);
            } else {
                //$('#log').html(p);

                //$('#log').html("<%= j render(partial: 'show_individual_exercise') %>")
                  //<%= escape_javascript(render(:partial => 'lti/show_individual_exercise.html.haml')) %>");
                //.append("<%= j render(:partial => 'views/lti/show_individual_exercise') %>");
                //var elem = '<div class="ui-widget">';
                var elem = '<label><strong>Select Exercise </strong></label>';
                elem += '<select id="comb">';
                //elem += '<% @exercise_list.each do |k, q| %>';
                //elem += '<% if q[1] %>';
                var keys = Object.keys(data.odsa_exercise_attempts);
                
                for (var i = 0; i < keys.length; i++){
                  var exercise = data.odsa_exercise_attempts[keys[i]];
                  if (exercise.length > 1){
                    elem += ' <option value="' + keys[i] + '">';
                    elem += '<strong>' + exercise[0] + '</strong>';
                    elem += '</option>';
                  }
                }
                elem += '</select>';
                elem += '<button class="btn btn-primary" id="display" onclick="handle_display()" name="display" style="float:right;">Display Detail </button>';
                //elem += '</div>';
                //elem += '<button class="btn btn-primary" id="submit">Submit</button>';                  
                $('#log').html(elem);
               /* var aj = $.ajax({
                    url: '/course_offerings/indAssigment/assignmentList/student/exercise',
                    type: 'get',
                    data_none: $(this).serialize()
                }).done(function(data_none) {
                    console.log(" redered the individual attempt");
                  }).fail(function(data) {
                    alert("fail from the inner render")
                    console.log('AJAX request has FAILED');
                  });*/
        }
        //change_courses(data);
        }).fail(function(data) {
            alert("failure")
            console.log('AJAX request has FAILED');
        });1
    }

  check_dis_completeness = function(flag) {
    var messages;
    messages = [];
    var selectbar1 = $('#combobox').find('option:selected').text();
    if (flag === 'individual_student'){
      if (selectbar1 === '' ){
        messages.push("You need to select a student");
      return messages;
      }
    }else if ("table"){
      var selectbar2 = $('#comb').find('option:selected').text();
      if (selectbar1 === '' || selectbar2 === '') {
        messages.push("You need to select a student or assignment");
        return messages;
      }
      return messages
    }else{
      console.log ("unknown error from lti_table.js module")
      alert ("unknown error from lti_table.js module, written by: Souleymane Dia")
    }
    return messages
  };

}).call(this);