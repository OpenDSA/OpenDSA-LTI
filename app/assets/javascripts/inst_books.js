let textFile = null; // Temporary global variable used for download link.

let nextId = 0; // Global variable used for tracking input ids.

/*
 * Checks if a json file has been defined and, if not, prompts the user to select one.
 */
$(document).ready(() => {
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
 * Defines the class 'datepicker' as a jquery ui datepicker widget.
 */
$(document).on('focus', '.datepicker', function() {
  $(this).datepicker();
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
 * Currently, this saves the book as an html download object.
 */
/*
 $(document).on('click', '#odsa_save', function() {
   let json = buildJSON();
   let download = document.getElementById('downloadLink');
   let jsonOb = JSON.parse(json);
   json = JSON.stringify(jsonOb);
   download.href = makeFile(json);
   alert("Ready for Download!");
   $('#downloadLink').toggle();
 });
*/


$(document).on('click', '#odsa_save', function() {
  //bookConfig = buildJSON();
  //alert(JSON.parse(bookConfig));
  jQuery.ajax({
    url: "/inst_books/update",
    type: "POST",
    data: JSON.stringify({
      'inst_book': jsonFile
    }),
    contentType: "application/json; charset=utf-8",
    datatype: "json",
    xhrFields: {
      withCredentials: true
    },
    success: function(data) {
      console.dir(data);
      $('#save_message').text(data['message']);
    },
    error: function(data) {
      console.dir(data);
      $('#save_message').text("Error occurred!");
    }
  });
});


/*
 * The click event for the 'Book Button' button.
 * This button loads the selected json book.
 */
$(document).on('click', '#bookButton', function() {
  let jsonBook = $('#Book option:selected').val() + $('#Book option:selected').text();
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
const listJSON = (url) => {
  $.ajax({
    url: url,
    success: function(data) {
      let output = "<select id=\"Book\">";
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
const prepArray = (inputHTML) => {
  inputHTML = inputHTML.replace(/&amp;/g, "&");
  inputHTML = inputHTML.replace(/ style="[^"]+"/g, "");
  inputHTML = inputHTML.replace(/ style=""/g, "");
  inputHTML = inputHTML.replace(/ class="[^"]+"/g, "");
  inputHTML = inputHTML.replace(/ class=""/g, "");
  let HTMLArray = inputHTML.split("<");
  return HTMLArray;
}

/*
 * Function to return the 'value' element of the given html string.
 */
const pullValue = (inputString) => {
  let value = "";
  if (inputString.includes("value")) {
    let stringStart = inputString.search("value=\"");
    let stringEnd = inputString.search("\" type=");
    value = inputString.slice(stringStart + 7, stringEnd);
  } else {
    value = "";
  }
  return value;
}

/*
 * Function to take a key and a value and return it as a json object pair.
 */
const makePair = (key, value) => {
  if (value === "{}") {
    return "\"" + key + "\": " + value + ",\n";
  } else if (value === "true" || value === "false") {
    return "\"" + key + "\": " + value + ",\n";
  } else {
    return "\"" + key + "\": \"" + value + "\",\n";
  }
}

/*
 * Function to take a text array and turn it into an html download object.
 */
const makeFile = (textArray) => {
  if (textFile != null) {
    window.URL.revokeObjectURL(textFile);
  }
  const data = new Blob([textArray], {
    type: 'text/plain'
  });
  textFile = window.URL.createObjectURL(data);
  return textFile;
}

const dropdown = () => {
  let html = "<div class=\"dropdown\">";
  html += "<button class=\"odsa_button ui-button ui-corner-all dropdown-toggle\" type=\"button\" data-toggle=\"dropdown\"><span class=\"glyphicon glyphicon-cog\"></span></button>";
  html += "<ul class=\"dropdown-menu\">";
  html += "<li class=\"due-date\"><a>Set Due Dates</a></li>";
  html += "<li class=\"remove\"><a>Delete Chapter</a></li>";
  html += "</ul></div>";
  return html;
}

//odsa_save.odsa_button.ui-button.ui-corner-all

/*
 * Function to read in a json key and value pair and convert it into the
 * proper html to be dispayed to the user.
 */
const encode = (key, val, index = -100) => {
  let htmlKey = "";
  if (key.includes("'")) {
    htmlKey = key.replace("'", "&#39;");
  } else {
    htmlKey = key;
  }
  if (typeof val === 'object' && val !== null) {
    let output = "";
    if (index === 1) {
      //output += "<li class='odsa_li' id=\"" + htmlKey + "\"><span class='glyphicon glyphicon-th-list'></span><a><span class='glyphicon glyphicon-chevron-right'></span>" + key + "</a><button class=\"odsa_button remove\">Delete</button><ul class=\"contain odsa_sortable\">";
      output += "<li class='odsa_li' id=\"" + htmlKey + "\"><span class='glyphicon glyphicon-th-list'></span><a><span class='glyphicon glyphicon-chevron-right'></span>" + key + "</a>" + dropdown() + "<ul class=\"contain odsa_sortable\">";
      //output += "<li class='odsa_li' id=\"hard_deadline\">hard_deadline: <input type=\"text\" value=\"" + "use_bootstrap_datepicker_instead" + "\" class=\"datepicker odsa_in\" id=\"" + ++nextId + "\"> <br>";
      //output += "<li class='odsa_li' id=\"soft_deadline\">soft_deadline: <input type=\"text\" value=\"" + "use_bootstrap_datepicker_instead" + "\" class=\"datepicker odsa_in\" id=\"" + ++nextId + "\"> <br>";
    } else if (index === 2) {
      output += "<li class='odsa_li' id='" + htmlKey + "'><span class='glyphicon glyphicon-th-list'></span><a><span class='glyphicon glyphicon-chevron-right'></span>" + key + "</a><ul class=\"contain\">";
    } else if (index === 3) {
      output += "<li class='odsa_li' id=\"hard_deadline\">hard_deadline: <input type=\"text\" value=\"" + "use_bootstrap_datepicker_instead" + "\" class=\"datepicker odsa_in\" id=\"" + ++nextId + "\"> <br>";
      output += "<li class='odsa_li' id=\"soft_deadline\">soft_deadline: <input type=\"text\" value=\"" + "use_bootstrap_datepicker_instead" + "\" class=\"datepicker odsa_in\" id=\"" + ++nextId + "\"> <br>";
      output += "<li class='odsa_li' id=\"" + htmlKey + "\"><a><span class='glyphicon glyphicon-chevron-right'></span>" + key + "</a><ul class=\"contain\">";
    } else {
      output += "<li class='odsa_li' id='" + htmlKey + "'><a><span class='glyphicon glyphicon-chevron-right'></span>" + key + "</a><ul class=\"contain\">";
    }
    for (var entry in val) {
      output = output + encode(entry, val[entry], index + 1);
    }
    output += "</ul></li>";
    return output;
  } else {
    return "<li class='odsa_li' id=\"" + htmlKey + "\">" + key + ": <input type=\"text\" name=\"" + htmlKey + "\" value=\"" + val + "\" id=\"" + ++nextId + "\"></li>";
  }
}

/*
 * Function to read in an array of html strings and convert it into a json
 * object.
 */
const decode = (fileArray, chapter = true) => {
  let jsonString = "";
  let spacing = "  ";
  for (i = 0; i < fileArray.length; i++) {
    let line = "";
    if (fileArray[i].startsWith("li")) {
      let stringStart = fileArray[i].search("id=\"");
      let stringEnd = fileArray[i].search("\">");
      let value = fileArray[i].slice(stringStart + 4, stringEnd);
      line = spacing + "\"" + value + "\": ";
    } else if (fileArray[i].startsWith("input")) {
      let stringStart = fileArray[i].search("id=\"");
      let stringEnd = fileArray[i].search("\" type=");
      console.log(fileArray[i]);
      console.log(stringStart);
      console.log(stringEnd);
      let id = "#" + fileArray[i].slice(stringStart + 4, stringEnd);
      let value = $(id).val();
      if (value === "true" || value === "false") {
        if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
          line = value + ",";
        } else {
          line = value;
        }
      } else if (!isNaN(parseFloat(value))) {
        if (!value.includes("/")) {
          if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
            line = parseFloat(value) + ","
          } else {
            line = parseFloat(value);
          }
        } else {
          line = "\"" + value + "\",";
        }
      } else {
        //alert(fileArray[i + 2]);
        if ((!chapter) || (i + 2 < fileArray.length) && ((fileArray[i + 2].startsWith("li")) || (fileArray[i + 2].startsWith("/li")))) {
          line = "\"" + value + "\",";
        } else {
          line = "\"" + value + "\"";
        }
      }
    } else if (fileArray[i].startsWith("ul")) {
      if (fileArray[i + 1].startsWith("/ul")) {
        if ((!chapter) || (i + 3 < fileArray.length) && (fileArray[i + 3].startsWith("li"))) {
          line = "{},";
          i++;
        } else {
          line = "{}";
          i++;
        }
      } else {
        if (chapter || (i != 1 && i != (fileArray.length - 1))) {
          line = "{ \n";
          spacing = spacing + "  ";
        }
      }
    } else if (fileArray[i].startsWith("/li")) {
      line = "\n";
    } else if (fileArray[i].startsWith("/ul")) {
      if (chapter || (i != 1 && i != (fileArray.length - 1))) {
        spacing = spacing.slice(0, spacing.length - 2);
        if (chapter) {
          if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
            line = spacing + "},";
          } else {
            line = spacing + "}";
          }
        } else {
          line = spacing + "},";
        }
      }
    } else if (fileArray[i].startsWith("a")) {} else if (fileArray[i].startsWith("/a")) {} else {}
    jsonString += line;
  }
  return jsonString;
}

/*
 * Function to build a json file from the html on the page.
 */
const buildJSON = () => {
  //let fileName = "Download.json";
  //if ($('#1').val() != "") {
  //  fileName = $('#1').val();
  //}

  //$('#downloadLink').attr('download', fileName);

  let json = "{\n";
  let spacing = "  ";

  let header = $('#heading').html();
  let headerArray = prepArray(header);
  json += decode(headerArray, false);

  let options = $('#options').html();
  let optionArray = prepArray(options);
  json += decode(optionArray, false);

  let chapters = $('#chapters').html();
  chapters = chapters.replace(/readonly=/g, "");
  let chapterArray = prepArray(chapters);

  json += spacing + "\"chapters\": ";
  json += decode(chapterArray);

  json += "\n}";
  return json;
}

/*
 * Function to add the proper jquery ui classes to
 * the appropriate dynamic elements.
 */
const addClasses = function() {
  $('#odsa_content').addClass("ui-widget-content");
  $('.odsa_button').addClass("ui-button ui-corner-all");
  $('input.odsa_in').addClass("ui-widget-content ui-corner-all");
  $('li.odsa_li').addClass("ui-widget-content ui-corner-all");
  $(".odsa_sortable").sortable();
}

/*
 * Function to build a new json book.
 */
const newJSON = function() {
  let titleString = "<h1> Header: <button id=\"toggle\" class=\"odsa_button\"> Show Options </button> </h1> <ul class='odsa_ul'>";
  titleString += encode("file name", "");
  titleString += "</ul>";
  $('#title').html(titleString);

  let headerString = "<ul class='odsa_ul'>";
  headerString += encode("title", "");
  headerString += encode("desc", "");
  headerString += "</ul>";
  $('#heading').html(headerString);

  let optionString = "<ul class='odsa_ul'>";
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

  let chapterString = "<h1> Chapters: </h1> <ul class=\"odsaul odsa_collapse\">";
  chapterString += "</ul>";
  $('#chapters').html(chapterString);

  addClasses();
}

/*
 * Function to load an existing json book.
 */
const loadJSON = function(jsonFile) {

  let titleString = "<h1> Header: <button id=\"toggle\" class=\"odsa_button\"> Show Options </button> </h1> <ul class='odsa_ul'>";
  titleString += "</ul>"
  $('#title').html(titleString);

  let headerString = "<ul class='odsa_ul'>";
  headerString += encode("title", jsonFile['title']);
  headerString += encode("desc", jsonFile['desc']);
  headerString += "</ul>";
  $('#heading').html(headerString);

  let optionString = "<ul class='odsa_ul'>";
  $.each(jsonFile, function(key, val) {
    if (!(key === "title" || key === "desc" || key === "chapters")) {
      optionString += encode(key, val);
    }
  });
  optionString += "</ul>";
  $('#options').html(optionString);

  let chapterString = "<h1> Chapters: </h1> <ul class=\"odsa_ul odsa_collapse odsa_sortable\">";
  $.each(jsonFile['chapters'], function(key, val) {
    chapterString += encode(key, val, 1);
  });
  chapterString += "</ul>";
  $('#chapters').html(chapterString);

  addClasses();

}