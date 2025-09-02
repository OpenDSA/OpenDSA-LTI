(function () {
  console.dir("lti js")
  $(document).ready(function () {
    $('#display').click(function () {
      return handle_display();
    });

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

    $("#combobox").combobox();
    $("#toggle").on("click", function () {
      $("#combobox").toggle();
    });
    $("#comb").combobox();
    $("#toggle").on("click", function () {
      $("#comb").toggle();
    });
  });


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
    elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Last Done </th>';
    //elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Posted to Canvas </th>';
    //elem += '<th style="border: 1px solid #dddddd;text-align: left; padding: 8px;"> Time Posted </th> </tr>';
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
    var selectbar2 = $('#comb').find('option:selected').text();
    if (selectbar1 === '' || selectbar2 === '') {
      messages.push("You need to select a student or assignment");
      return messages;
    }
    return messages
  };

}).call(this);
