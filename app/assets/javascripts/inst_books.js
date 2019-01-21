(function() {
  var textFile = null; // Temporary global variable used for download link.

  /*
   * Checks if a json file has been defined and, if not, prompts the user to select one.
   */
  $(document).ready(function() {
    loadJSON(jsonFile);
  })

  /*
   * Defines the div tag 'dialog' as a jquery ui dialog widget.
   */
  $(function() {
    $("#dialog").dialog({
      autoOpen: false
    });
  });

  /*
   * Defines the class 'datetimepicker' as a bootstrap datetimepicker.
   */
   $(document).on('focus', '.timemodal', function() {
	$(this).parent().css("position", "relative");
    $(this).parent().datetimepicker({
      showClose: true,
      sideBySide: true,
      keepInvalid: true,
	    allowInputToggle: true,
      format: "YYYY-MM-DD HH:MM"
    });
   });

  /*
   * Defines the class 'datetimepicker' as a bootstrap datetimepicker.
   */
  $(document).on('click', '.input-group-addon', function() {
    $(this).parent().css("position", "relative");
    $(this).parent().datetimepicker({
      showClose: true,
      sideBySide: true,
	    keepInvalid: true,
	    allowInputToggle: true,
      format: "YYYY-MM-DD HH:MM"
    });
	$(this).parent().data("DateTimePicker").show();
  });

  /*
   * Sets the value attribute of an input tag when the user changes it.
   */
  $(document).on('blur', ':input', function() {
    $(this).attr('value', $(this).val());
  });

  /*
   * Sets the data-key attribute of a select tag when the user changes it.
   */
  $(document).on('blur', 'select', function() {
    $(this).attr('data-key', $(this).val());
  });

  /*
   * Sets the data-key attribute of a form tag when the user changes it.
   */
  $(document).on('blur', '#odsa_content form', function() {
    $(this).attr('data-key', $("input[name=\"" + $(this).attr('data-name') + "\"]:checked").val());
  });

  /*
   * Sends the chapter name to the chapter due date modal when the appropriate
   * button is clicked.
   */
  $(document).on('click', '.chapterLoad', function() {
    $('#chapterSoft').attr('data-chapter', $(this).attr('data-chapter'));
    $('#chapterHard').attr('data-chapter', $(this).attr('data-chapter'));
  });

  /*
   * Sets all of the section due dates to the values set in the chapter due date
   * modal.
   */
  $(document).on('click', '#chapterSubmit', function() {
    var chapterTitle = $('#chapterSoft').attr('data-chapter');
    var checkChapter = '[data-chapter=\"' + chapterTitle + '\"]';
    $(checkChapter + '[data-type="soft"]').val($('#chapterSoft').val());
    //$(checkChapter + '[data-type="hard"]').val($('#chapterHard').val());
  });

  /*
   * The click event for the 'Show Options' button.
   */
  $(document).on('click', '#toggle', function() {
    $('#options').toggle();
    if ($('#options').is(':visible')) {
      $('#toggle').html("Hide Options");
    } else {
      $('#toggle').html("Show Options");
    }
  });

  /*
   * The click event for the 'New Book' button.
   */
  $(document).on('click', '#new', function() {
    newJSON();
  });

  /*
   * The click event for the 'Save Book' button.
   */

  /* The old version that saves the book as a downloadable file. Used for testing.
   $(document).on('click', '#odsa-save', function() {
     var download = document.getElementById('downloadLink');

     var json = buildJSON();

     download.href = makeFile(json);
     //download.href = makeFile(JSON.stringify(jsonFile));
     alert("Ready for Download!");
     $('#downloadLink').toggle();
   });
   */

  $(document).on('click', '#odsa-submit-co', function(e) {
    handleSubmit();
    e.preventDefault();
  });

  /*
   * The click even for the 'Undo Changes' button.
   */
  $(document).on('click', '#odsa-reset-co', function(e) {
    loadJSON(jsonFile);
    e.preventDefault();
  });

  /*
   * The click event for the 'Book Button' button.
   * This button loads the selected json book.
   */
  $(document).on('click', '#bookButton', function() {
    var jsonBook = $('#Book option:selected').val() + $('#Book option:selected').text();
  });

  /*
   * The click event for the 'Delete' buttons.
   */
  $(document).on('click', '.remove', function() {
    $(this).parent().parent().parent().remove();
  });

  /*
   * The click event for the collapsible lists.
   */
  $(document).on('click', '.odsa_collapse li a', function() {
    $(this).parent().children('ul').toggle();
    if ($(this).children('span').hasClass('glyphicon glyphicon-chevron-right')) {
      $(this).children('span').removeClass('glyphicon glyphicon-chevron-right');
      $(this).children('span').addClass('glyphicon glyphicon-chevron-down');
    } else if ($(this).children('span').hasClass('glyphicon glyphicon-chevron-down')) {
      $(this).children('span').removeClass('glyphicon glyphicon-chevron-down');
      $(this).children('span').addClass('glyphicon glyphicon-chevron-right');
    }
  });

  /*
   * Ajax call to the given directory to pull the names of all .json files.
   * The user is then prompted to select one and given the option to load it.
   */
  var listJSON = function(url) {
    $.ajax({
      url: url,
      success: function(data) {
        var output = "<select id=\"Book\">";
        $(data).find("a:contains(.json)").each(function() {
          output += "<option value=\"" + url + "\">" + $(this).attr("href") + "</option>";
        });
        output += "</select><button id=\"bookButton\">Select Book</button>";
        $('#dialog').html(output);
        $('#dialog').dialog("open");
      },
      error: function() {
        alert("error");
      }
    });
  };

  /*
   * Function to remove class declarations and ampersands from a given html string before
   * turning it into an array, splitting on the '<' character.
   */
  var prepArray = function(inputHTML) {
    inputHTML = inputHTML.replace(/&amp;/g, "&");
    inputHTML = inputHTML.replace(/ style="[^"]+"/g, "");
    inputHTML = inputHTML.replace(/ style=""/g, "");
    inputHTML = inputHTML.replace(/ class="[^"]+"/g, "");
    inputHTML = inputHTML.replace(/ class=""/g, "");
    inputHTML = inputHTML.replace(/ type="[^"]+"/g, "");
    inputHTML = inputHTML.replace(/ type=""/g, "");
    inputHTML = inputHTML.replace(/ size="[^"]+"/g, "");
    inputHTML = inputHTML.replace(/ size=""/g, "");
    inputHTML = inputHTML.replace(/ readonly=/g, "");
    inputHTML = inputHTML.replace(/ disabled=""/g, "");
    inputHTML = inputHTML.replace(/ hidden=""/g, "");
    var HTMLArray = inputHTML.split("<");
    return HTMLArray;
  }

  /*
   * Function to return the 'data-key' element of the given html string.
   */
  var pullData = function(dataString) {
    var value = "";
    if (dataString.includes("data-key")) {
      var stringStart = dataString.search("data-key=\"");
      var stringEnd = dataString.search("\">");
      value = dataString.slice(stringStart + 10, stringEnd);
    }
    return value;
  }

  /*
   * Function to return the 'value' element of the given html string.
   */
  var pullValue = function(dataString) {
    var value = "";
    if (dataString.includes("value")) {
      var stringStart = dataString.search("value=\"");
      var stringEnd = dataString.search("\">");
      value = dataString.slice(stringStart + 7, stringEnd);
    }
    return value;
  }

  /*
   * Function to take a text array and turn it into an html download object.
   */
  var makeFile = function(textArray) {
    if (textFile != null) {
      window.URL.revokeObjectURL(textFile);
    }
    var data = new Blob([textArray], {
      type: 'text/plain'
    });
    textFile = window.URL.createObjectURL(data);
    return textFile;
  }

  /*
   * Function to return the html to make a datetimepicker object.
   */
  var datepick = function(value, parent, mod, chapter) {
    //var html = "<input class=\"datetimepicker\" data-chapter=\"" + chapter + "\" data-type=\"soft\" type=\"text\" value=\"" + value + "\"/>";

    var html = "<div class='col-sm-3 input-group date datetimepicker'>";
    html += "<input class=\"form-control date-input\" data-source=\" Chapter: " + chapter + ", Module: " + mod + ", Section: " + parent + "\" data-chapter=\"" + chapter + "\" data-type=\"soft\" type=\"text\" value=\"" + value + "\" />";
    html += "<span class='input-group-addon'><span class='glyphicon glyphicon-calendar'></span></span>";
    html += "</div>";
    return html;
  }

  /*
   * Function to check if a given input is not a radio button.
   */
  var checkRadio = function(input) {
    if (input.includes("radio")) {
      return false;
    } else {
      return true;
    }
  }

  /*
   * Function to read in a json object and convert it into the
   * proper html to be dispayed to the user.
   */
  var encode = function(data) {
    Handlebars.registerHelper('pullModule', function(path) {
      return path.substr(path.indexOf("/") + 1);
    });

    Handlebars.registerHelper('hideExer', function(key) {
      if (key != "long_name" && key != "points" && key != "threshold") {
        return "hidden";
      }
    });

    Handlebars.registerHelper('hideSec', function(key) {
      if (key == "lms_assignment_id" || key == "lms_item_id" || key == "hard_deadline" || key == "showsection") {
        return "hidden";
      } else if (key.includes("CON")) {
        return "hidden";
      }
    });

    Handlebars.registerHelper('sameLine', function(key) {
      if(key == 'points' || key == 'threshold') {
        return "same-line";
      }
    });

	Handlebars.registerHelper('dropdown', function(key, canDelete) {
		var html = "<div class=\"dropdown instDropdown\">";
		html += "<button class=\"odsa_button ui-button ui-corner-all dropdown-toggle\" type=\"button\" data-toggle=\"dropdown\"><span class=\"glyphicon glyphicon-cog\"></span></button>";
		html += "<ul class=\"dropdown-menu pull-right\">";
		html += "<li class=\"due-date\"><a data-toggle=\"modal\" data-target=\"#chapterDue\" data-chapter=\"" + key + "\" class=\"chapterLoad\">Set Due Dates</a></li>";
		if(canDelete) {
			html += "<li class=\"remove\"><a>Delete Chapter</a></li>";
		}
		html += "</ul></div>";
		return new Handlebars.SafeString(html);
	});

    Handlebars.registerHelper('keyCheck', function(key) {
      if (key == "long_name") {
        return "long name";
      } else if (key == "resource_type") {
        return "resource type";
      } else if (key == "resource_name") {
        return "resource name";
      } else if (key == "exer_options") {
        return "exercise options";
      } else if (key == "learning_tool") {
        return "learning tool";
      } else if (key == "showsection") {
        return "show section";
      } else if (key == "lms_item_id") {
        return "lms item id";
      } else if (key == "lms_assignment_id") {
        return "lms assignment id";
      } else if (key == "soft_deadline" || key == "due_date") {
        //return "soft deadline";
        return "due date";
      } else if (key == "hard_deadline") {
        return "hard deadline";
      } else {
        return key;
      }
    });

    Handlebars.registerHelper('secCheck', function(key, value, parent, mod, chapter) {
      if (key == "required" || key == "showsection") {
        if (value == "true") {
          return new Handlebars.SafeString("<form data-name=\"" + parent + "\" data-key=\"true\"><label><input data-type=\"radio\" type=\"radio\" name=\"" + parent + "\" value=\"true\" checked>True</label><label><input data-type=\"radio\" type=\"radio\" name=\"" + parent + "\" value=\"false\">False</label></form>");
        } else {
          return new Handlebars.SafeString("<form data-name=\"" + parent + "\" data-key=\"false\"><label><input data-type=\"radio\" type=\"radio\" name=\"" + parent + "\" value=\"true\">True</label><label><input data-type=\"radio\" type=\"radio\" name=\"" + parent + "\" value=\"false\" checked>False</label></form>");
        }
      } else if (key == "lms_item_id" || key == "lms_assignment_id") {
        return new Handlebars.SafeString("<input value=\"null\" disabled>");
      } else if (key == "soft_deadline") {
        if (typeof(value) === "object") {
          value = null;
        }
        return new Handlebars.SafeString(datepick(value, parent, mod.long_name, chapter));
      } else if (key == "hard_deadline") {
        if (typeof(value) === "object") {
          value = null;
        }
        return new Handlebars.SafeString(datepick(value, parent, mod.long_name, chapter));
      } else if (typeof(value) === 'object') {
        return new Handlebars.SafeString("<input value=\"" + value + "\" hidden>");
      } else if (key == "long_name") {
        return new Handlebars.SafeString("<input value=\"" + value + "\" disabled>");
      } else {
        return new Handlebars.SafeString("<input value=\"" + value + "\">");
      }
    });

    Handlebars.registerHelper('exCheck', function(key, value, parent, parentOb, section, mod, chapter) {
      if (key == "points") {
        return new Handlebars.SafeString("<input class=\"points\" data-source=\" Chapter: " + chapter + ", Module: " + mod.long_name + ", Section: " + section + ", Exercise: " + parentOb.long_name + "\" value=\"" + value + "\">");
      } else if (key == "threshold") {
        if(parent.includes("CON")) {
          return new Handlebars.SafeString("<input value=\"" + value + "\">");
        } else {
          return new Handlebars.SafeString("<input class=\"threshold\" data-source=\" Chapter: " + chapter + ", Module: " + mod.long_name + ", Section: " + section + ", Exercise: " + parentOb.long_name + "\" value=\"" + value + "\">");
        }
      } else {
        return new Handlebars.SafeString("<input value=\"" + value + "\">");
      }
    });

    var hSource = "<ul class=\"odsa_ul\">" +
       "<li class='odsa_li' hidden> <a data-key=\"inst_book_id\"> instance book id: </a> <input value=\"{{inst_book_id}}\"> </li>" +
       "<li class='odsa_li'> <a data-key=\"title\"> title: </a> <input id=\"book-title\" value=\"{{title}}\"> </li>" +
       "<li class='odsa_li'> <a data-key=\"desc\">description: </a> <input id=\"book-desc\" value=\"{{desc}}\"> </li>" +
       "</ul>";
    var hTemplate = Handlebars.compile(hSource);
    var hhtml = hTemplate(data);
    $('#heading').html(hhtml);

    var oSource = "<ul class=\"odsa_ul\">" +
       "<li class='odsa_li' hidden> <a data-key=\"course_id\"> course id: </a> <input value=\"{{course_id}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"LMS_url\"> LMS url: </a> <input value=\"{{LMS_url}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"build_dir\"> build directory: </a> <input value=\"{{build_dir}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"code_dir\"> code directory: </a> <input value=\"{{code_dir}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"lang\"> language: </a> <input value=\"{{lang}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"code_lang\"> code language: </a> <input value=\"{}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"build_JSAV\"> build JSAV: </a> <input value=\"{{build_JSAV}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"tabbed_codeinc\"> tabbed code inc: </a> <input value=\"{{tabbed_codeinc}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"build_cmap\"> build cmap: </a> <input value=\"{{build_cmap}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"suppress_todo\"> suppress todo: </a> <input value=\"{{suppress_todo}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"assumes\"> assumes: </a> <input value=\"{{assumes}}\"> </li>" +
       "<li class='odsa_li' hidden> <a data-key=\"dispModComp\"> display Mod Comp: </a> <input value=\"{{dispModComp}}\"> </li>" +
       "</ul>";
    var oTemplate = Handlebars.compile(oSource);
    var ohtml = oTemplate(data);
    $('#options').html(ohtml);

    var cSource = "<h1> Chapters: </h1>" + // Header
      "{{#if last_compiled}} <ul class=\"odsa_ul odsa_collapse\"> {{else}} <ul class=\"odsa_ul odsa_collapse odsa_sortable\"> {{/if}}" + // Chapters Sortable
        "{{#each chapters}}" + // Open Chapters
          "<li class=\"odsa_li\">" + // Chapter Line Item
            "{{#unless ../last_compiled}} <span class=\"glyphicon glyphicon-th-list\"></span> {{/unless}}" + // Sortable Icon
            "<a data-key=\"{{@key}}\"> <span class=\"glyphicon glyphicon-chevron-right\"></span> <strong> Chapter: </strong> {{@key}} </a>" + // Chapter Title
            "{{#if ../last_compiled}} {{dropdown @key false}} {{else}} {{dropdown @key true}} {{/if}}" + // Dropdown Menu
            "{{#if ../last_compiled}} <ul class=\"odsa_ul odsa_collapse\"> {{else}} <ul class=\"odsa_ul odsa_collapse odsa_sortable\"> {{/if}}" + // Modules Sortable
            "{{#each .}}" + // Open Modules
              "{{#if long_name}}" + // Check Module Name
              "<li class=\"odsa_li\">" + // Module Line item
                "{{#unless ../../last_compiled}} <span class=\"glyphicon glyphicon-th-list\"></span> {{/unless}}" + // Sortable Icon
                "<a data-key=\"{{@key}}\"> {{#if sections}} <span class=\"glyphicon glyphicon-chevron-right\"></span> {{/if}} <strong> Module: </strong> {{long_name}} </a>" + // Module Title
                "<ul class=\"odsa_ul\">" + // Module Data
                  "<li class=\"odsa_li\" hidden> <a data-key=\"long_name\"></a> <input value=\"{{long_name}}\"> </li>" + // Module Long Name
                  "{{#if sections}}" + // Has Sections
                    "<li class=\"odsa_li\">" + // Module Sections
                    "<a data-key=\"sections\"> <span class=\"glyphicon glyphicon-chevron-right\"></span> Sections </a>" + // Section Header
                      "<ul class=\"odsa_ul\">" + // Section List
                      "{{#each sections}}" + // Open Sections
                        "<li class=\"odsa_li\">" + // Section Line item
                          "<a data-key=\"{{@key}}\"> <span class=\"glyphicon glyphicon-chevron-right\"></span> {{@key}} </a>" + // Section Name
                          "<ul class=\"odsa_ul\">" + // Section Data
                          "{{#each .}}" + // Open Section Data
                            "{{#if long_name}}" + // If Exercise
                              "<li class=\"odsa_li\">" + // Exercise Line item
                                "<a data-key=\"{{@key}}\"> <span class=\"glyphicon glyphicon-chevron-right\"></span> <strong> Exercise: </strong> {{long_name}} </a>" + // Exercise Title
                                "<ul class=\"odsa_ul\">" + // Exercise Data
                                "{{#each .}}" + // Open Exercise Data
                                  "<li class=\"odsa_li {{sameLine @key}}\" {{hideExer @key}}> <a data-key=\"{{@key}}\">" + // Exercise Data Line Item
                                    "{{keyCheck @key}}: </a> {{exCheck @key this @../key @../this @../../key @../../../this @../../../../key}}" + // Exercise Data Item
                                  "</li>" + // Close Exercise Data line Item
                                "{{/each}}" + // Close Exercise Data
                                "</ul>" + // Close Exercise Data
                              "</li>" + // Close Exercise Line Item
                            "{{else}}" + // If Not Exercise
                              "<li {{hideSec @key}}>" + // Section Data Line Item
                                "<a data-key=\"{{@key}}\"> {{keyCheck @key}}: </a> {{secCheck @key this @../key @../../../this @../../../key}}" + // Section Data Item
                              "</li>" + // Close Section Data Line Item
                            "{{/if}}" + // Close Exercise If
                          "{{/each}}" + // Close Section Data
                          "</ul>" + // Close Section Data
                        "</li>" + // Close Section Line Item
                      "{{/each}}" + // Close Sections
                      "</ul>" + // Close Sections
                    "</li>" + // Close Module Sections
                  "{{else}}" + // No Sections
                    "<li class=\"odsa_li\" hidden>" + //Module Sections
                      "<a data-key=\"sections\"> </a>" + // Section Header
                      "<ul class=\"odsa_ul\">" + // Section List
                      "</ul>" + // Close Section List
                    "</li>" + // Close Module Sections
                  "{{/if}}" + // Close Section Header If
                "</ul>" + // Close Module Data
              "</li>" + // Close Module Line Item
              "{{/if}}" + // Close Check Module Name
            "{{/each}}" + // Close Modules
            "</ul>" + // Close Modules
          "</li>" + // Close Chapter Line Item
        "{{/each}}" + // Close chapters
        "</ul>"; // Close Chapters

    var cTemplate = Handlebars.compile(cSource);
    var chtml = cTemplate(data);
    $('#chapters').html(chtml);
  }

  /*
   * Function to read in an array of html strings and convert it into a json
   * object.
   */
  var decode = function(fileArray) {
    var jsonString = "";
    var spacing = "  ";
    for (i = 0; i < fileArray.length; i++) {
      var line = "";
      if (fileArray[i].startsWith("a")) {
        var value = pullData(fileArray[i]);
        line = spacing + "\"" + value + "\": ";
      } else if (fileArray[i].startsWith("input") && checkRadio(fileArray[i])) {
        var value = pullValue(fileArray[i]);
        value = value.replace(/"="/g, '');
        value = value.replace(/"/g, '\\"');
        if (value === "true" || value === "false" || value === "null" || (!isNaN(parseFloat(value)) && !(value.includes("-")) && !(value.includes("/")))) {
          line = value;
        } else {
          line = "\"" + value + "\"";
        }
        if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
          line = line + ",";
        } else if ((i + 2 < fileArray.length) && fileArray[i + 2].startsWith("span")) {
          line = line + ",";
        }
      } else if (fileArray[i].startsWith("select") || fileArray[i].startsWith("form")) {
        var value = pullData(fileArray[i]);
        //line = "\"" + value + "\",";
        line = value + ",";
      } else if (fileArray[i].startsWith("button")) {
        i = i + 13;
      } else if (fileArray[i].startsWith("ul")) {
        if (fileArray[i + 1].startsWith("/ul")) {
          line = "{}";
          if ((i + 3 < fileArray.length) && (fileArray[i + 3].startsWith("li"))) {
            line += ",";
          }
          i++;
        } else {
          if (i != 1 && i != (fileArray.length - 1)) {
            line = "{ \n";
            spacing = spacing + "  ";
          }
        }
      } else if (fileArray[i].startsWith("/li")) {
        line = "\n";
      } else if (fileArray[i].startsWith("/ul")) {
        if (i != 1 && i != (fileArray.length - 1)) {
          spacing = spacing.slice(0, spacing.length - 2);
          if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
            line = spacing + "},";
          } else {
            line = spacing + "}";
          }
        }
      }
      jsonString += line;
    }
    return jsonString;
  }

  /*
   * Function to build a json file from the html on the page.
   */
  var buildJSON = function() {
    var json = "{\n";
    var spacing = "  ";

    var header = $('#heading').html();
    var headerArray = prepArray(header);
    json += decode(headerArray);
    json += ",";

    var options = $('#options').html();
    var optionArray = prepArray(options);
    json += decode(optionArray);
    json += ",";

    var chapters = $('#chapters').html();
    var chapterArray = prepArray(chapters);

    json += spacing + "\"chapters\": ";
    json += decode(chapterArray);
    json += "\n" + spacing + "}";

    json += "\n}";

    json = json.replace(/"sections": "null"/g, "\"sections\": {}");

    return json;
  }

  /*
   * Function to add the proper jquery ui classes to
   * the appropriate dynamic elements.
   */
  var addClasses = function() {
    $('#odsa_content').addClass("ui-widget-content");
    $('.odsa_button').addClass("ui-button ui-corner-all");
    $('input.odsa_in').addClass("ui-widget-content ui-corner-all");
    $('li.odsa_li').addClass("ui-widget-content ui-corner-all");
    $(".odsa_sortable").sortable();
  }

  /*
   * Function to set the default size of all text inputs.
   */
  var sizeInputs = function() {
	$('input:text').each(function(index, element) {
		if($(element).val().length > 10) {
			$(element).attr('size', $(element).val().length);
		} else {
			$(element).attr('size', 10);
		}
	});
  }

  /*
   * Function to build a new json book.
   */
  var newJSON = function() {
    var titleString = "<h1> Header: <button id=\"toggle\" class=\"odsa_button\"> Show Options </button> </h1> <ul class='odsa_ul'>";
    titleString += encode("file name", "");
    titleString += "</ul>";
    $('#title').html(titleString);

    var headerString = "<ul class='odsa_ul'>";
    headerString += encode("title", "");
    headerString += encode("desc", "");
    headerString += "</ul>";
    $('#heading').html(headerString);

    var optionString = "<ul class='odsa_ul'>";
    optionString += encode("build_dir", "Books");
    optionString += encode("code_dir", "SourceCode/");
    optionString += encode("lang", "en");
    optionString += encode("build_JSAV", "false");
    optionString += encode("suppress_todo", "true");
    optionString += encode("assumes", "recursion");
    optionString += encode("disp_mod_comp", "true");
    optionString += encode("glob_exer_options", {});
    optionString += "</ul>";
    $('#options').html(optionString);

    var chapterString = "<h1> Chapters: </h1> <ul class=\"odsaul odsa_collapse\">";
    chapterString += "</ul>";
    $('#chapters').html(chapterString);

    addClasses();
	  sizeInputs();
  }

  /*
   * Function to load an existing json book.
   */
  var loadJSON = function(jsonFile) {
    //var titleString = "<h1> Header: <button id=\"toggle\" class=\"odsa_button\"> Show Options </button> </h1>";
    var titleString = "<h1> Header: </h1>";
    $('#title').html(titleString);

    encode(jsonFile);

    addClasses();
	  sizeInputs();
  }

  /*
   * Function to send configuration to server.
   */
  var handleSubmit = function() {
    var messages,
      bookConfig = JSON.parse(buildJSON()),
      url = "/inst_books/update";

    messages = check_completeness();
    if (messages.length !== 0) {
      form_alert(messages, 'danger');
      $('#odsa-submit-co').prop('disabled', false);
      return;
    }

    jQuery.ajax({
      url: url,
      type: "POST",
      data: JSON.stringify({
        'inst_book': bookConfig
      }),
      contentType: "application/json; charset=utf-8",
      datatype: "json",
      xhrFields: {
        withCredentials: true
      },
      success: function(data) {
        form_alert([data['message']], 'success');
      },
      error: function(data) {
        form_alert(['Error occurred!'], 'danger');
      }
    });
  };

  /*
   * Function to build alerts for sending book to server.
   */
  var form_alert = function(messages, alertClass) {
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
    var alertClass = alertClass == 'danger' ? "alert-danger" : "alert-success";
    $('#alerts .alert').addClass(alertClass).css('display', 'block');
    return $('#alerts').css('display', 'block');
  };

  /*
   * Function to remove alerts for sending book to server.
   */
  var reset_alert_area = function() {
    var $alert_box;
    $('#alerts').find('.alert').alert('close');
    $alert_box = "<div class='alert alert-dismissable' role='alert'>" + "<button class='close' data-dismiss='alert' aria-label='Close'><i class='fa fa-times'></i></button>" + "<ul></ul>" + "</div>";
    return $('#alerts').append($alert_box);
  };

  /*
   * Function to validate user configuration before
   * sending book to server.
   */
  var check_completeness = function() {
    var messages;
    messages = [];
    if($('#book-title').val() === '') {
      messages.push('The book configuration needs a title.');
    }
    if($('#book-desc').val() === '') {
      messages.push('The book configuration needs a description.');
    }
    $('.points').each(function(index, element) {
      if($(element).val() != parseFloat($(element).val())) {
        messages.push('Points must be a numeric value. SOURCE: ' + $(element).attr('data-source'));
        return false;
      } else if($(element).val() < 0) {
		messages.push('Points must be a positive value. SOURCE: ' + $(element).attr('data-source'));
		return false;
	  }
    })
    $('.form-control').each(function(index, element) {
      if(!(/^\d\d\d\d-\d\d-\d\d \d\d:\d\d$/.test($(element).val())) && $(element).val() != 'null') {
        messages.push('Dates must be in the format YYYY-MM-DD HH:MM SOURCE: ' + $(element).attr('data-source'));
        return false;
      }
    })
    $('.threshold').each(function(index, element) {
      if($(element).val() > 10 || $(element).val() < 0) {
        messages.push('Thresholds must be between 1 and 10 or 0 and 1.0 SOURCE: ' + $(element).attr('data-source'));
        return false;
      } else if($(element).val() < 1 && $(element).val() != parseFloat($(element).val())) {
		messages.push('Thresholds between 0 and 1.0 must be a decimal. SOURCE: ' + $(element).attr('data-source'));
		return false;
	  } else if($(element).val() >= 1 && $(element).val() != parseInt($(element).val())) {
		messages.push('Thresholds between 1 and 10 must be an integer. SOURCE: ' + $(element).attr('data-source'));
		return false;
	  }
    })
    return messages;
  };

}).call(this);
