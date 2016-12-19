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
 * Defines the class 'datetimepicker' as a bootstrap datetimepicker.
 */
$(document).on('focus', '.datetimepicker', function() {
  $(this).datetimepicker();
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
 *
 */
$(document).on('click', '.chapterLoad', function() {
	$('#chapterSoft').attr('data-chapter', $(this).attr('data-chapter'));
	$('#chapterHard').attr('data-chapter', $(this).attr('data-chapter'));
});

/*
 *
 */
$(document).on('click', '#chapterSubmit', function() {
	var chapterTitle = $('#chapterSoft').attr('data-chapter');
	var checkChapter = '[data-chapter=\"' + chapterTitle + '\"]';
	$(checkChapter + '[data-type="soft"]').val($('#chapterSoft').val());
	$(checkChapter + '[data-type="hard"]').val($('#chapterHard').val());
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
   let download = document.getElementById('downloadLink');
   
   let json = buildJSON();

   download.href = makeFile(json);
   alert("Ready for Download!");
   $('#downloadLink').toggle();
 });
*/

$(document).on('click', '#odsa_save', function() {
  var bookConfig = JSON.parse(buildJSON());
  
  /*
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
  */

  jQuery.ajax({
    url: "/inst_books/update",
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
      console.dir(data);
      $('#save_message').text(data['message']);
    },
    error: function(data) {
      console.dir(data);
      //$('#save_message').text("Error occurred!");
      $('#save_message').html(data['responseText']);
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
  inputHTML = inputHTML.replace(/ type="[^"]+"/g, "");
  inputHTML = inputHTML.replace(/ type=""/g, "");
  inputHTML = inputHTML.replace(/ readonly=/g, "");
  let HTMLArray = inputHTML.split("<");
  return HTMLArray;
}

/*
 * Function to return the 'data-key' element of the given html string.
 */
const pullData = ( dataString ) => {
  let value = "";
  if (dataString.includes("data-key")) {
    let stringStart = dataString.search("data-key=\"");
    let stringEnd = dataString.search("\">");
    value = dataString.slice(stringStart + 10, stringEnd);
  }
  return value;
}

/*
 * Function to return the 'value' element of the given html string.
 */
const pullValue = ( dataString ) => {
  let value = "";
  if (dataString.includes("value")) {
    let stringStart = dataString.search("value=\"");
    let stringEnd = dataString.search("\">");
    value = dataString.slice(stringStart + 7, stringEnd);
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

const datepick = () => {
  let html = "<div class=\"col-sm-6\"><div class=\"form-group\"><div class=\"datetimepicker\" input-group date\">";
  html += "<input class=\"form-control\" type=\"text\" /><span class=\"input-group-addon\"><span class=\"glyphicon glyphicon-calendar>";
  html += "</span></span></div></div></div>";
  return html;
}

const dropdown = () => {
  let html = "<div class=\"dropdown instDropdown\">";
  html += "<button class=\"odsa_button ui-button ui-corner-all dropdown-toggle\" type=\"button\" data-toggle=\"dropdown\"><span class=\"glyphicon glyphicon-cog\"></span></button>";
  html += "<ul class=\"dropdown-menu pull-right\">";
  html += "<li class=\"due-date\"><a data-toggle=\"modal\" data-target=\"#chapterDue\" data-chapter=\"{{@key}}\" class=\"chapterLoad\">Set Due Dates</a></li>";
  html += "<li class=\"remove\"><a>Delete Chapter</a></li>";
  html += "</ul></div>";
  return html;
}

/*
 * Function to read in a json key and value pair and convert it into the
 * proper html to be dispayed to the user.
 */
const encode = ( data ) => {
		Handlebars.registerHelper('pullModule', function(path) {
			return path.substr(path.indexOf("/") + 1);
		});
		
		Handlebars.registerHelper('keyCheck', function(key) {
			if(key == "long_name") {
				return "long name";
			} else if(key == "resource_type") {
				return "resource type";
			} else if(key == "resource_name") {
				return "resource name";
			} else if(key == "exer_options") {
				return "exercise options";
			} else if(key == "learning_tool") {
				return "learning tool";
			} else if(key == "soft_deadline") {
        return "soft deadline";
      } else if(key == "hard_deadline") {
        return "hard deadline";
      } else {
				return key;
			}
		});
		
		Handlebars.registerHelper('valCheck', function(key, value, chapter) {
			if(key == "required") {
				if(value == "true") {
					return new Handlebars.SafeString("<select data-key=\"" + value + "\"><option value=\"true\">true</option><option value=\"false\">false</option></select>");
				} else {
					return new Handlebars.SafeString("<select data-key=\"" + value + "\"><option value=\"true\">true</option><option value=\"false\">false</option></select>");
				}
			} else if(key == "soft_deadline") {
        return new Handlebars.SafeString("<input data-chapter=\"" + chapter + "\" data-type=\"soft\" type=\"text\" value=\"" + $.datepicker.formatDate('mm/dd/yy', new Date()) + " 12:00 AM\" class=\"datetimepicker\">");
      } else if(key == "hard_deadline") {
        return new Handlebars.SafeString("<input data-chapter=\"" + chapter + "\" data-type=\"hard\" type=\"text\" value=\"" + $.datepicker.formatDate('mm/dd/yy', new Date()) + " 12:00 AM\" class=\"datetimepicker\">");
      } else if(typeof(value) === 'object') {
				return new Handlebars.SafeString("<input value=\"{}\">");
			} else {
				return new Handlebars.SafeString("<input value=\"" + value + "\">");
			}
		});
  
    var hSource = "<ul class='odsa_ul'>" +
                  "<li class='odsa_li'><a data-key=\"inst_book_id\">instance book id: </a><input value=\"{{inst_book_id}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"title\">title: </a><input value=\"{{title}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"desc\">description: </a><input value=\"{{desc}}\"></li>" +
                  "</ul>";
    var hTemplate = Handlebars.compile(hSource);
    var hhtml = hTemplate(data);
    $('#heading').html(hhtml);
 
    var oSource = "<ul class='odsa_ul'>" +
                  "<li class='odsa_li'><a data-key=\"course_id\">course id: </a><input value=\"{{course_id}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"LMS_url\">LMS url: </a><input value=\"{{LMS_url}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"build_dir\">build directory: </a><input value=\"{{build_dir}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"code_dir\">code directory: </a><input value=\"{{code_dir}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"lang\">language: </a><input value=\"{{lang}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"code_lang\">code language: </a><input value=\"{}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"build_JSAV\">build JSAV: </a><input value=\"{{build_JSAV}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"tabbed_codeinc\">tabbed code inc: </a><input value=\"{{tabbed_codeinc}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"build_cmap\">build cmap: </a><input value=\"{{build_cmap}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"suppress_todo\">suppress todo: </a><input value=\"{{suppress_todo}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"assumes\">assumes: </a><input value=\"{{assumes}}\"></li>" +
                  "<li class='odsa_li'><a data-key=\"dispModComp\">display Mod Comp: </a><input value=\"{{dispModComp}}\"></li>" +
                  "</ul>";
    var oTemplate = Handlebars.compile(oSource);
    var ohtml = oTemplate(data);
    $('#options').html(ohtml);
  
		var cSource = "<h1> Chapters: </h1> <ul class=\"odsa_ul odsa_collapse odsa_sortable\"> {{#each chapters}}" + // List
				   "<li class='odsa_li'><span class='glyphicon glyphicon-th-list'></span><a data-key=\"{{@key}}\"><span class='glyphicon glyphicon-chevron-right'></span> <strong> Chapter: </strong> {{@key}} </a>" + dropdown() + // Chapters
				   "<ul class=\"odsa_ul odsa_collapse odsa_sortable\"> {{#each .}}" + // Chapters
				   "{{#if long_name}} <li class='odsa_li'><span class='glyphicon glyphicon-th-list'></span><a data-key=\"{{@key}}\"><span class='glyphicon glyphicon-chevron-right'></span> <strong> Module: </strong> {{long_name}} </a><ul class=\"odsa_ul\"> {{#each sections}}" + // Modules
				   "<li class='odsa_li'><a data-key=\"{{@key}}\"><span class='glyphicon glyphicon-chevron-right'></span> <strong> Section: </strong> {{@key}} </a> <ul class=\"odsa_ul\"> {{#each .}}" + // Sections
				   "{{#if long_name}} <li class='odsa_li'><a data-key=\"{{@key}}\"><span class='glyphicon glyphicon-chevron-right'></span> <strong> Exercise: </strong> {{long_name}} </a> <ul class=\"odsa_ul\"> {{#each .}}" + // Exercises
				   "<li class='odsa_li'><a data-key=\"{{@key}}\"> {{keyCheck @key}}: </a> {{valCheck @key this @../../../key}} </li>" + // Exercise Data
				   "{{/each}} </ul></li>" + // Close Exercise Data
				   "{{else}} <li><a data-key=\"{{@key}}\"> {{keyCheck @key}}: </a> {{valCheck @key this @../../../key}} </li> {{/if}}" + // Parse Additional Learning Tools
				   "{{/each}}" + // Close Exercises
				   "</ul></li>" + // Close Sections
				   "{{/each}} </ul> {{/if}} </li>" + // Close Modules
				   "{{/each}} </ul></li>" + // Close Chapters
				   "{{/each}} </ul>"; // Close List
				   
		var cTemplate = Handlebars.compile(cSource);
		var chtml = cTemplate(data);
    $('#chapters').html(chtml);
}

/*
 * Function to read in an array of html strings and convert it into a json
 * object.
 */
const decode = ( fileArray ) => {
	let jsonString = "";
	let spacing = "  ";
	for(i = 0; i < fileArray.length; i++)
	{
		let line = "";
		if(fileArray[i].startsWith("a")) {
			let value = pullData(fileArray[i]);
			line = spacing + "\"" + value + "\": ";
		} else if (fileArray[i].startsWith("input")) {
			let value = pullValue(fileArray[i]);
      value = value.replace(/"="/g, '');
      value = value.replace(/"/g, '\\"');
			if (value === "true" || value === "false" || (!isNaN(parseFloat(value)) && !(value.includes("-")) && !(value.includes("/")))) {
				line = value;
			} else {
				line = "\"" + value + "\"";
			}
			if ((i + 2 < fileArray.length) && (fileArray[i + 2].startsWith("li"))) {
				line = line + ",";
			}
		} else if(fileArray[i].startsWith("select")) {
			let value = pullData(fileArray[i]);
			line = "\"" + value + "\",";
		} else if(fileArray[i].startsWith("button")) {
      i = i + 13;
    } else if (fileArray[i].startsWith("ul")) {
      if (fileArray[i + 1].startsWith("/ul")) {
        line = "{}";
        if((i + 3 < fileArray.length) && (fileArray[i + 3].startsWith("li"))) {
          line += ",";
        }
        i++;
      } else {
        if(i != 1 && i != (fileArray.length - 1)) {
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
const buildJSON = () => {
  //$('.instDropdown').html("");

  let json = "{\n";
  let spacing = "  ";

  let header = $('#heading').html();
  let headerArray = prepArray(header);
  json += decode(headerArray, false);
  json += ",";

  let options = $('#options').html();
  let optionArray = prepArray(options);
  json += decode(optionArray, false);
  json += ",";

  let chapters = $('#chapters').html();
  let chapterArray = prepArray(chapters);

  json += spacing + "\"chapters\": ";
  json += decode(chapterArray);
  json += "\n" + spacing + "}";

  json += "\n}";
  
  json = json.replace(/"sections": "null"/g, "\"sections\": {}");
  
  //$('.instDropdown').html(dropdownAdd());
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

  let titleString = "<h1> Header: <button id=\"toggle\" class=\"odsa_button\"> Show Options </button> </h1>";
  $('#title').html(titleString);

  encode(jsonFile);

  addClasses();
}