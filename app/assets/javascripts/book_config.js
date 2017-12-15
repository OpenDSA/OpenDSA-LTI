/* OpenDSA Book Configuration Interface */

// allows us to customize node apperances when they are rendered
// from https://github.com/vakata/jstree/blob/master/src/misc.js
(function (factory) {
	"use strict";
	if (typeof define === 'function' && define.amd) {
		define('jstree.node_customize', ['jquery','jstree'], factory);
	}
	else if(typeof exports === 'object') {
		factory(require('jquery'), require('jstree'));
	}
	else {
		factory(jQuery, jQuery.jstree);
	}
}(function ($, jstree, undefined) {
	"use strict";

	if($.jstree.plugins.node_customize) { return; }

	/**
	 * the settings object.
	 * key is the attribute name to select the customizer function from switch.
	 * switch is a key => function(el, node) map.
	 * default: function(el, node) will be called if the type could not be mapped
	 * @name $.jstree.defaults.node_customize
	 * @plugin node_customize
	 */
	$.jstree.defaults.node_customize = {
		"key": "type",
		"switch": {},
		"default": null
	};

	$.jstree.plugins.node_customize = function (options, parent) {
		this.redraw_node = function (obj, deep, callback, force_draw) {
			var node_id = obj;
			var el = parent.redraw_node.apply(this, arguments);
			if (el) {
				var node = this._model.data[node_id];
				var cfg = this.settings.node_customize;
				var key = cfg.key;
				var type =  (node && node.original && node.original[key]);
				var customizer = (type && cfg.switch[type]) || cfg.default;
				if(customizer)
					customizer(el, node);
			}
			return el;
		};
	};
}));

(function () {
  var availTree, includedTree,
      includedTreeElem, availTreeElem,
      langSelect, addChapterDialog, renameChapterDialog,
      exSettingsDialog;

  // indicates if we are in the processing of loading an existing configuration
  var loadingConfig = false;

  $(document).ready(function () {
    // setup the split pane used for book content selection
    var pane1 = document.querySelector('#chosen-pane');
    var pane2 = document.querySelector('#available-pane');
    Split([pane1, pane2], {
      sizes: [50, 50],
      minSize: 280
    });

    langSelect = $('#book-lang');
    if (langSelect.val() != null && langSelect.val() != -1) {
      initializeJsTree(ODSA.availableModules[langSelect.val()].children);
    }
    langSelect.on('change', function() {
      if (!loadingConfig) {
        initializeJsTree(ODSA.availableModules[langSelect.val()].children);
      }
    });

    // dialog displayed when creating a new chapter
    addChapterDialog = $('#add-chapter-dialog').dialog({
      autoOpen: false,
      modal: true,
      width: 500,
      buttons: {
        'Add': function() {
          if (addChapter()) {
            addChapterDialog.dialog('close');
          }
        },
        'Cancel': function() {
          addChapterDialog.dialog('close');
          updateDialogErrors(addChapterDialog, '');
        }
      },
      close: function() {
        addChapterForm[0].reset();
      },
      open: function() {
        updateDialogErrors(addChapterDialog, '');
      }
    });

    var addChapterForm = addChapterDialog.find('form').on('submit', function(event) {
      event.preventDefault();
      addChapter();
    });

    $('#btn-add-chapter').on('click', function() {
      addChapterDialog.dialog('open');
    });

    $('#add-chapter-submit').on('click', function() {
      if (addChapter()) {
        addChapterDialog.dialog('close');
      }
    });

    // dialog displayed when renaming a chapter
    renameChapterDialog = $('#rename-chapter-dialog').dialog({
      autoOpen: false,
      modal: true,
      width: 500,
      buttons: {
        'Rename': renameChapterHelper,
        'Cancel': function() {
          renameChapterDialog.dialog('close');
          updateDialogErrors(addChapterDialog, '');
        }
      },
      close: function() {
        renameChapterForm[0].reset();
      },
      open: function() {
        updateDialogErrors(addChapterDialog, '');
      }
    });

    $('#rename-chapter-submit').on('click', function() {
      renameChapterHelper();
    });

    var renameChapterForm = renameChapterDialog.find('form').on('submit', function(event) {
      event.preventDefault();
      renameChapterHelper();
    });

    function renameChapterHelper() {
      var nodeId = renameChapterDialog.dialog('option', 'nodeId');
      var newName = $.trim($('#chapter-newname').val());
      if (renameChapter(nodeId, newName)) {
        renameChapterDialog.dialog('close');
      }
    }

    // dialog displayed when editing exercise settings
    exSettingsDialog = $('#exercise-settings-dialog').dialog({
      autoOpen: false,
      modal: true,
      width: 500,
      buttons: {
        'Save': exerciseSettingsHelper,
        'Cancel': function() {
          exSettingsDialog.dialog('close');
          updateDialogErrors(exSettingsDialog, '');
        }
      },
      close: function() {
        exSettingsForm[0].reset();
      },
      open: function() {
        updateDialogErrors(exSettingsDialog, '');
      }
    });

    $('#exercise-settings-submit').on('click', exerciseSettingsHelper);

    var exSettingsForm = exSettingsDialog.find('form').on('submit', function(event) {
      event.preventDefault();
      exerciseSettingsHelper();
    });

    // parse settings from the dialog and apply them to the
    // target exercise
    function exerciseSettingsHelper() {
      var node = getIncludedNode(exSettingsDialog.dialog('option', 'nodeId'));
      var settings = {
        points: Number.parseFloat($('#exercise-settings-points').val()),
      };
      if (node.type !== 'extr') {
        settings.required = $('#exercise-settings-required').is(':checked');
        if (node.type === 'ka') {
          settings.threshold = Number.parseInt($('#exercise-settings-threshold').val());
        }
        if (node.type === 'pe') {
          settings.threshold = Number.parseFloat($('#exercise-settings-threshold').val());
          var feedback = $('#exercise-settings-feedback').val();
          if (feedback === 'continuous') {
            settings['JXOP-feedback'] = feedback;
            settings['JXOP-fix'] = $('#exercise-settings-fix').val();
          }
          if ($('#exercise-settings-code').is(':checked')) {
            settings['JXOP-code'] = 'none';
          }
        }
      }
      setExerciseSettings(node, settings);
      exSettingsDialog.dialog('close');
    }

    var kaOptionList = ['required', 'points', 'threshold'];
    for (var i = 0; i < kaOptionList.length; i++) {
      var kaOption = kaOptionList[i];
      var elem = $('#glob-ka-' + kaOption);
      elem.on('change', function() {
        onGlobalExerciseSettingsUpdate('ka', globalKaSettings());
      });
    }

    var peOptionList = ['required', 'points', 'threshold', 'feedback', 'fix'];
    for (var i = 0; i < peOptionList.length; i++) {
      var peOption = peOptionList[i];
      var elem = $('#glob-pe-' + peOption);
      elem.on('change', function() {
        onGlobalExerciseSettingsUpdate('pe', globalPeSettings());
      });
    }

    var extrOptionList = ['points'];
    for (var i = 0; i < ODSA.learningTools.length; i++) {
      var tool = ODSA.learningTools[i];
      for (var j = 0; j < extrOptionList.length; j++) {
        var extrOption = extrOptionList[j];
        var elem = $('#glob-' + tool.name + '-' + extrOption);
        elem.on('change', function() {
          onGlobalExerciseSettingsUpdate('extr', globalExtrSettings(tool.name), tool.name);
        });
      }
    }

    var exSettingsFeedback = $('#exercise-settings-feedback');
    var exSettingsFix = $('#exercise-settings-fix');
    exSettingsFeedback.on('change', function() {
      if (exSettingsFeedback.val() === 'continuous') {
        exSettingsFix.removeAttr('disabled');
      }
      else {
        exSettingsFix.attr('disabled', true);
      }
    });

    // download book configuration as a json file
    $('#book-config-form').on('submit', function(event) {
      event.preventDefault();
      var config = allGlobalSettings();
      config.chapters = includedChapters();

      var dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(config, null, 2) + '\n');
      var exportName = config.title.replace(/ /g, '_');
      var downloadAnchorNode = document.createElement('a');
      downloadAnchorNode.setAttribute("href", dataStr);
      downloadAnchorNode.setAttribute("download", exportName + ".json");
      downloadAnchorNode.style.display = 'none';
      document.body.appendChild(downloadAnchorNode);
      downloadAnchorNode.click();
      downloadAnchorNode.remove();
    });

    $('#upload-config-file').on('change', function() {
      $('#config-file-load').removeAttr('disabled');
    });

    if ($('#upload-config-file')[0].value !== '') {
      $('#config-file-load').removeAttr('disabled');
    }

    // load a configuration from the file a user has chosen
    $('#config-file-load').on('click', function() {
      loadingConfig = true;
      $('#config-file-load').attr('disabled', true);
      $('#reference-config-load').attr('disabled', true);
      var file = $('#upload-config-file')[0].files[0];
      var reader = new FileReader();
      reader.onload = (function(event) {
        var config = JSON.parse(event.target.result);
        loadConfiguration(config);
        $('#config-file-load').removeAttr('disabled');
        $('#reference-config-load').removeAttr('disabled');
        loadingConfig = false;
      });
      reader.readAsText(file);
    });

    // load a configuration from a reference configuration stored on the 
    // OpenDSA server
    $('#reference-config-load').on('click', function(event) {
      loadingConfig = true;
      $('#config-file-load').attr('disabled', true);
      $('#reference-config-load').attr('disabled', true);
      var url = $('#reference-config').val();
      $.ajax({
        url: url,
        success: function(data, txtStatus, xhr) {
          loadConfiguration(data);
        },
        error: function(xhr, txtStatus, errorThrown) {
          alert('Error loading configuration: ' + textStatus + ' ' + errorThrown);
        },
        complete: function(xhr, textStatus) {
          $('#reference-config-load').removeAttr('disabled');
          if ($('#upload-config-file')[0].value !== '') {
            $('#config-file-load').removeAttr('disabled');
          }
          loadingConfig = false;
        }
      });
    });
  });

  /* changes made from default options
     items have format:
     '<node_id>': {
       '<setting_name>': '<setting_value>'
     }
  */
  var optionChanges = {};

  /* mark a tree node as having settings different from the globals/defaults */
  function markModified(nodeId, elem) {
    var iconId = nodeId + '_modified';
    if (getOption(nodeId, 'showsection') === false) {
      $(elem).addClass('section-hidden');
    }
    if ($('#' + iconId).length === 0) {
      var node = getIncludedNode(nodeId);
      if (!node) return;
      elem.prepend('<i id="' + iconId + '" class="jstree-icon modified-icon">M</i>');
      for (var i = 0; i < node.parents.length; i++) {
        var parentId = node.parents[i];
        if (parentId === '#') {
          continue;
        }
        var anchor = $('#' + parentId + '_anchor');
        markModifiedChildren(parentId, anchor);
      }
    }
  }

  /* Mark a tree node as having children with settings different from
     the global/default settings */
  function markModifiedChildren(nodeId, elem) {
    var iconId = nodeId + '_childmodified';
    if ($('#' + iconId).length === 0) {
      var modifiedIcon = $('#' + nodeId + '_modified');
      var html = '<i id="' + iconId + '" class="jstree-icon modifiedchild-icon">•</i>';
      if (modifiedIcon.length > 0) {
        modifiedIcon.after(html);
      }
      else {
        elem.prepend(html);
      }
    }
  }

  /* Indicates if a tree node has children with settings different from
     the global/default settings */
  function hasModifiedChildren(nodeId) {
    var node = getIncludedNode(nodeId);
    for (var i = 0; i < node.children.length; i++) {
      var childId = node.children[i];
      if (hasOptionChanges(childId)) return true;
      if (hasModifiedChildren(childId)) {
        return true;
      }
    }
    return false;
  }

  /* Mark a tree node has not having any children with settings different from
     the global/default settings */
  function markNotModifiedChildren(nodeId) {
    var iconId = nodeId + '_childmodified';
    $('#' + iconId).remove();
  }

  /* mark a tree node as not having settings different from the globals/defaults */
  function markNotModified(nodeId) {
    var iconId = nodeId + '_modified';
    $('#' + iconId).remove();
    var node = getIncludedNode(nodeId);
    for (var i = 0; i < node.parents.length; i++) {
      var parentId = node.parents[i];
      if (parentId === '#') continue;
      if (!hasModifiedChildren(parentId)) {
        markNotModifiedChildren(parentId);
      }
    }
  }

  /* Sets an option that is different from the default/global settings 
     for a tree node */
  function setOption(nodeId, optionName, optionValue) {
    var opts = optionChanges[nodeId];
    if (typeof opts === 'undefined') {
      opts = {};
      optionChanges[nodeId] = opts;
    }
    opts[optionName] = optionValue;
    var anchor = $('#' + nodeId + '_anchor');
    markModified(nodeId, anchor);
  }

  /* Remove an option for a given node */
  function deleteOption(nodeId, optionName) {
    var opts = optionChanges[nodeId];
    if (typeof opts === 'undefined') return;
    delete opts[optionName];
    if ($.isEmptyObject(opts)) {
      // the options object is empty, so remove it
      deleteAllOptions(nodeId);
    }
  }

  /* Get the value of an option that is different from the default/global settings 
    for a given node */
  function getOption(nodeId, optionName) {
    var opts = optionChanges[nodeId];
    if (!$.isEmptyObject(opts)) {
      return optionChanges[nodeId][optionName];
    }
    return undefined;
  }

  /* Get all of the settings for a given node */
  function getOptions(node) {
    if (typeof node !== 'object') {
      node = getIncludedNode(node);
    }
    var opts = optionChanges[node.id] || {};
    opts = $.extend(globalTypeSettings(node), opts);
    return opts;
  }

  /* Get all of the options that are different from the default/global
     settings for a given node */
  function getOptionChanges(nodeId) {
    return optionChanges[nodeId];
  }

  /* Indicates if a node has any options different from the default/global settings */
  function hasOptionChanges(nodeId) {
    return nodeId in optionChanges;
  }

  /* Resets a node to the default/global settings */
  function deleteAllOptions(nodeId) {
    delete optionChanges[nodeId];
    markNotModified(nodeId);
  }

  /* Remove a module from the included tree */
  function removeModule(node) {
    if (node.original.included === false) return false;
    node.original.included = false;
    var parent = availTree.jstree(true).get_node(node.original.parent_id);
    availTree.jstree(true).copy_node(node, parent);
    includedTree.jstree(true).delete_node(node);
  }

  /* Add a module to the included tree */
  function addModule(node, parent) {
    if (node.original.included === true) return false;
    node.original.included = true;
    includedTree.jstree().copy_node(node, parent, 'last');
    availTree.jstree().delete_node(node);
  }

  function renameChapter(nodeId, newName) {
    var valid = validateChapterName(renameChapterDialog, newName, nodeId);
    if (valid) {
      var node = includedTree.jstree().get_node(nodeId);
      valid = includedTree.jstree().rename_node(node, newName);
    }
    return valid;
  }

  /* Add a chapter to the included tree */
  function addChapter(name) {
    if (!name) {
      var elem = $('#chapter-name');
      name = $.trim(elem.val());
    }
    var valid = validateChapterName(addChapterDialog, name);

    if (valid) {
      includedTree.jstree(true).create_node('#', {text: name, type: 'chapter', id: 'chapter_' + encodeId(name)}, "last");
    }

    return valid;
  }

  /* Check that the chapter name is unique and meets other requirements */
  function validateChapterName(dialog, name, ignore) {
    var valid = !chapterExists(dialog, name, ignore);
    valid = valid && checkRegexp(dialog, name, /^[\w\s]{1,100}$/,
      'Name must be between 1 and 100 characters long.');
    return valid;
  }

  /* Checks if a chapter with the specified name exists
    and displays an error messages if it does */
  function chapterExists(dialog, name, ignore) {
    var treeNodes = includedTree.jstree(true).get_json();
    for (var i = 0; i < treeNodes.length; i++) {
      var node = treeNodes[i];
      var chapterName = node.text;
      if (name.toLowerCase() === chapterName.toLowerCase() && node.id !== ignore) {
        updateDialogErrors(dialog, 'A chapter with that name already exists.');
        return true;
      }
    }
    return false;
  }

  /* Check if a value matches a regeular expression 
    Displays an error if it doesn't*/
  function checkRegexp(dialog, value, regexp, error) {
    if (regexp.test(value)) {
      return true;
    }
    updateDialogErrors(dialog, error);
    return false;
  }

  /* Sets the error message on the dialog */
  function updateDialogErrors(dialog, msg) {
    var errors = dialog.find('.dialog-errors');
    if (!msg) {
      errors.text('');
      return;
    }
    errors
      .text(msg)
      .addClass('ui-state-highlight');
    setTimeout(function() {
      errors.removeClass('ui-state-highlight', 1500);
    }, 500);
  }

  /* Gets the global exercise settings  (glob_exer_options) */
  function globalExerSettings() {
    return {
      'JXOP-debug': $('#JXOP-debug').is(':checked').toString()
    };
  }

  /* Gets the global Khan-Academy Exercise settings (glob_ka_options) */
  function globalKaSettings() {
    return {
      required: $('#glob-ka-required').is(':checked'),
      points: Number.parseFloat($('#glob-ka-points').val()),
      threshold: Number.parseInt($('#glob-ka-threshold').val())
    };
  }

  /* Gets the global Proficiency Exercise settings (glob_pe_options) */
  function globalPeSettings() {
    return {
      required: $('#glob-pe-required').is(':checked'),
      points: Number.parseFloat($('#glob-pe-points').val()),
      threshold: Number.parseFloat($('#glob-pe-threshold').val())
    };
  }

  /* Gets the global Slideshow settings (glob_ss_options) */
  function globalSsSettings() {
    return {
      required: $('#glob-ss-required').is(':checked'),
      points: Number.parseFloat($('#glob-ss-points').val()),
      threshold: 1
    };
  }

  /* Gets the global External Tool settings (glob_extr_options) 
    If a tool name is provided, only the options for that tool
    will be returned. */
  function globalExtrSettings(toolName) {
    if (toolName) {
      return {
        points: Number.parseFloat($('#glob-' + toolName + '-points').val())
      };
    }

    var settings = {
      points: Number.parseFloat($('#glob-extr-points').val())
    };
    for (var i = 0; i < ODSA.learningTools.length; i++){
      var tool = ODSA.learningTools[i];
      settings[tool.name] = {
        points: Number.parseFloat($('#glob-' + tool.name + '-points').val())
      };
    }
    return settings;
  }

  /* Gets the default settings for sections */
  function globalSectionSettings() {
    return {
      showsection: true
    };
  }

  /* Gets the code languages the user has selected */
  function selectedCodeLanguages() {
    var checkboxes = $('input:checkbox[name=code-lang]:checked');
    var selected = {};
    for (var i = 0; i < checkboxes.length; i++) {
      var lang = checkboxes[i].value;
      selected[lang] = ODSA.codeLanguages[lang];
    }
    return selected;
  }

  /* Gets an object containing all the global book settings */
  function allGlobalSettings() {
    return {
      title: $('#book-title').val(),
      desc: $('#book-desc').val(),
      build_dir: "Books",
      code_dir: "SourceCode/",
      lang: $('#book-lang').val(),
      code_lang: selectedCodeLanguages(),
      build_JSAV: $('#build-jsav').is(':checked'),
      build_cmap: false,
      suppress_todo: $('#suppress-todo').is(':checked'),
      dispModComp: $('#disp-mod-comp').is(':checked'),
      glob_exer_options: globalExerSettings(),
      glob_ss_options: globalSsSettings(),
      glob_ka_options: globalKaSettings(),
      glob_pe_options: globalPeSettings(),
      glob_extr_options: globalExtrSettings()
    };
  }

  /* Gets an object containing all the chapters in the book 
    including the modules in the chapters, and any changes
    made to options sections and/or exercises/visualizations */
  function includedChapters() {
    var tree = includedTree.jstree().get_json();
    var chapters = {};

    for (var i = 0; i < tree.length; i++) {
      var chapterNode = tree[i];
      var chapter = {};
      chapters[chapterNode.text] = chapter;
      for (var j = 0; j < chapterNode.children.length; j++) {
        var moduleNode = getIncludedNode(chapterNode.children[j].id);
        var module = {};
        for (var k = 0; k < moduleNode.children.length; k++) {
          var sectionNode = getIncludedNode(moduleNode.children[k]);
          var changes = getOptionChanges(sectionNode.id);
          if (changes) {
            module[sectionNode.text] = changes;
          }
          for (var l = 0; l < sectionNode.children.length; l++) {
            var exNode = getIncludedNode(sectionNode.children[l]);
            changes = getOptionChanges(exNode.id);
            if (changes) {
              var fixed = {};
              for (var change in changes) {
                if (change.indexOf('JXOP-') === 0) {
                  fixed.exer_options = fixed.exer_options || {};
                  fixed.exer_options[change] = changes[change];
                }
                else {
                  fixed[change] = changes[change];
                }
              }
              module[exNode.original.short_name] = fixed;
            }
          }
        }
        chapter[moduleNode.original.path] = module;
      }
    }

    return chapters;
  }

  /* Gets a node from the available tree */
  function getAvailNode(node) {
    return availTree.jstree().get_node(node);
  }

  /* Gets a node from the included tree */
  function getIncludedNode(node) {
    return includedTree.jstree().get_node(node);
  }

  /* Gets the global settings based on the nodes type */
  function globalTypeSettings(node) {
    var globals;
    switch (node.type) {
      case 'ss':
        globals = globalSsSettings();
        break;
      case 'ka':
        globals = globalKaSettings();
        break;
      case 'pe':
        globals = globalPeSettings();
        break;
      case 'extr':
        globals = globalExtrSettings(node.original.learning_tool);
        break;
      case 'section':
        globals = globalSectionSettings();
        break;
      default:
        globals = {};
    }
    return globals;
  }

  /* Sets the exercise settings for the exercise represented by the node */
  function setExerciseSettings(node, settings) {
    var globalSettings = globalTypeSettings(node);
    var opts = getOptions(node);
    // delete any options that are no longer set
    for (var setting in opts) {
      if (!(setting in settings)) {
        deleteOption(node.id, setting);
      }
    }
    // check to see which settings, if any, don't match the global settings
    for (var setting in settings) {
      var value = settings[setting];
      if (!(setting in globalSettings) || value !== globalSettings[setting]) {
        setOption(node.id, setting, value);
      }
      else {
        deleteOption(node.id, setting);
      }
    }
  }

  /* Removes any exercise setting changes that are equal to the new
    global settings*/
  function onGlobalExerciseSettingsUpdate(type, changes, toolName) {
    for (var nodeId in optionChanges) {
      var node = getIncludedNode(nodeId);
      if (node.type !== type || (toolName && node.original.learning_tool !== toolName)) {
        continue;
      }
      var options = optionChanges[nodeId];
      for (var setting in changes) {
        if (setting in options && options[setting] === changes[setting]) {
          deleteOption(nodeId, setting);
        }
      }
    }
  }

  /* Remove any values from options that are the same as the global options 
   of the node's type */
  function cleanOptions(node, options) {
    var globals = globalTypeSettings(node);
    for (var setting in globals) {
      if (setting in options && options[setting] === globals[setting]) {
        delete options[setting];
      }
    }
    return options;
  }

  /* Loads the settings from the specified configuration */
  function loadConfiguration(config) {
    $('#book-config-form')[0].reset();
    for (var key in config) {
      switch(key) {
        case 'title':
          $('#book-title').val(config.title);
          break;
        case 'desc':
          $('#book-desc').val(config.desc);
          break;
        case 'code_lang':
          setCodeLangs(config.code_lang);
          break;
        case 'lang':
          $('#book-lang').val(config.lang);
          break;
        case 'build_JSAV':
          $('#build-jsav').prop('checked', config.build_JSAV);
          break;
        case 'suppress_todo':
          $('#suppress-todo').prop('checked', config.suppress_todo);
          break;
        case 'dispModComp':
          $('#disp-mod-comp').prop('checked', config.dispModComp);
          break;
        case 'glob_exer_options':
          setGlobExerOptions(config.glob_exer_options);
          break;
        case 'glob_ss_options':
          setGlobSsOptions(config.glob_ss_options);
          break;
        case 'glob_ka_options':
          setGlobKaOptions(config.glob_ka_options);
          break;
        case 'glob_pe_options':
          setGlobPeOptions(config.glob_pe_options);
          break;
        case 'glob_extr_options':
          setGlobExtrOptions(config.glob_extr_options);
          break;
        case 'chapters':
          //loadChapters(config.chapters, config.lang);
          break;
        default:
          //
      }
    }
    initializeJsTree(ODSA.availableModules[config.lang].children, config.chapters);
  }

  /* Sets the selected code languages */
  function setCodeLangs(langs) {
    for (var lang in ODSA.codeLanguages) {
      // jquery doesn't work when element id's contain '+' characters, e.g. C++
      var elem = document.getElementById('code-lang-' + lang);
      elem.checked = (lang in langs);
    }
  }

  /* Sets the global exercise options */
  function setGlobExerOptions(options) {
    for (var option in options) {
      $('#' + option).prop('checked', options[option]);
    }
  }

  /* Sets the global slideshow options */
  function setGlobSsOptions(options) {
    for (var option in options) {
      var value = options[option];
      if (typeof value === 'boolean') {
        $('#glob-ss-' + option).prop('checked', value);
      }
      else {
        $('#glob-ss-' + option).val(value);
      }
    }
  }

  /* Sets the global Khan-Academy exercise options */
  function setGlobKaOptions(options) {
    for (var option in options) {
      var value = options[option];
      if (typeof value === 'boolean') {
        $('#glob-ka-' + option).prop('checked', value);
      }
      else {
        $('#glob-ka-' + option).val(value);
      }
    }
  }

  /* Sets the global Proficiency Exercise Options */
  function setGlobPeOptions(options) {
    for (var option in options) {
      var value = options[option];
      if (typeof value === 'boolean') {
        $('#glob-pe-' + option).prop('checked', value);
      }
      else {
        $('#glob-pe-' + option).val(value);
      }
    }
  }

  /* Sets the global external tool options */
  function setGlobExtrOptions(options) {
    for (var option in options) {
      var value = options[option];
      if (option === 'points') {
        $('#glob-extr-points').val(value);
      }
      else {
        for (var opt in value) {
          var val = value[opt];
          if (typeof val === 'boolean') {
            $('#glob-' + option + '-' + opt).prop('checked', val);
          }
          else {
            $('#glob-' + option + '-' + opt).val(val);
          }
        }
      }
    }
  }

  /* Encodes the specified string for use as an html element id */
  function encodeId(id) {
    return encodeURIComponent(id).replace(/[%']/g, '');
  }

  /**
   * Initialize the book content selection trees
   */
  function initializeJsTree(availData, chapters) {
    if (availTree) {
      availTree.jstree('destroy');
      includedTree.jstree('destroy');
    }

    optionChanges = {};
    var includedData;
    if (langSelect.val() === 'en' && !chapters) {
      // include some default chapters
      includedData = [
        {text: 'Preface', id: 'chapter_Preface', type: 'chapter'},
        {text: 'Appendix', id: 'chapter_Appendix', type: 'chapter'}
      ];
    }
    else {
      includedData = [];
    }

    // node types
    itemTypes = {
      'chapter': {
        icon: 'fa fa-folder-o'
      },
      'module': {
        icon: 'fa fa-files-o'
      },
      'section': {
        icon: 'fa fa-file-o'
      },
      'ka': {
        icon: 'ka-icon',
      },
      'ss': {
        icon: 'ss-icon'
      },
      'pe': {
        icon: 'pe-icon'
      },
      'extr': {
        icon: 'et-icon'
      }
    };

    includedTreeElem = $('#included-modules');
    // tree of chapters and modules included in the book
    includedTree = includedTreeElem.jstree({
      'types': itemTypes,
      'dnd': {
        // drag and drop settings
        copy: false,
        is_draggable: function (nodes) {
          return true;
        },
        inside_pos: 'last'
      },
      'contextmenu': {
        // menu displayed when right clicking on certain nodes
        items: function(node) {
          if (node.type === 'chapter') {
            return {
              'rename': {
                label: 'Rename',
                action: function(args) {
                  var node = includedTree.jstree(true).get_node(args.reference);
                  renameChapterDialog.dialog('option', 'nodeId', node.id);
                  renameChapterDialog.find('#chapter-newname').val(node.text).focus(
                    function() {
                      this.select();
                    }
                  );
                  renameChapterDialog.dialog('open');
                }
              },
              'remove': {
                label: 'Remove',
                action: function(args) {
                  var node = includedTree.jstree(true).get_node(args.reference);
                  // remove all of the modules in the chapter
                  while (node.children.length > 0) {
                    var child = includedTree.jstree(true).get_node(node.children[0]);
                    removeModule(child);
                  }
                  // remove the chapter
                  includedTree.jstree(true).delete_node(node);
                }
              }
            };
          }
          if (node.type === 'module') {
            return {
              'remove': {
                label: 'Remove',
                action: function(args) {
                  var node = includedTree.jstree(true).get_node(args.reference);
                  removeModule(node);
                }
              }
            };
          }
          if (node.type === 'section') {
            if (getOption(node.id, 'showsection') === false) {
              return {
                'show': {
                  label: 'Show Section',
                  action: function(args) {
                    var node = includedTree.jstree(true).get_node(args.reference);
                    node.original.showsection = false;
                    $('#' + node.a_attr.id).removeClass('section-hidden');
                    deleteOption(node.id, 'showsection');
                  }
                }
              };
            }
            else {
              return {
                'hide': {
                  label: 'Hide Section',
                  action: function(args) {
                    var node = includedTree.jstree(true).get_node(args.reference);
                    node.original.showsection = true;
                    setOption(node.id, 'showsection', false);
                  }
                }
              };
            }
          }
          if ($.inArray(node.type, ['ka', 'pe', 'extr', 'ss']) >= 0) {
            return {
              'settings': {
                label: 'Edit Exercise Settings',
                action: function(args) {
                  exSettingsDialog.find('form')[0].reset();
                  var node = includedTree.jstree(true).get_node(args.reference);
                  var thresholdElem = $('#exercise-settings-threshold');
                  switch (node.type) {
                    case 'ka':
                      thresholdElem.attr('step', 1);
                      thresholdElem.attr('min', 1);
                      thresholdElem.removeAttr('max');
                      $('#exercise-settings-pe').css('display', 'none');
                      $('#exercise-settings-required-group').css('display', '');
                      $('#exercise-settings-threshold-group').css('display', '');
                      break;
                    case 'pe':
                      thresholdElem.attr('step', 1);
                      thresholdElem.attr('min', 1);
                      thresholdElem.removeAttr('max');
                      $('#exercise-settings-pe').css('display', 'none');
                      $('#exercise-settings-required-group').css('display', '');
                      $('#exercise-settings-threshold-group').css('display', '');
                      break;
                    case 'extr':
                      $('#exercise-settings-pe').css('display', 'none');
                      $('#exercise-settings-required-group').css('display', 'none');
                      $('#exercise-settings-threshold-group').css('display', 'none');
                      break;
                    case 'ss':
                      $('#exercise-settings-pe').css('display', 'none');
                      $('#exercise-settings-required-group').css('display', '');
                      $('#exercise-settings-threshold-group').css('display', 'none');
                      break;
                  }
                  var options = getOptions(node);
                  for (var option in options) {
                    var value = options[option];
                    option = option.replace('JXOP-', '');
                    if (typeof value === 'boolean') {
                      $('#exercise-settings-' + option).prop('checked', value);
                    }
                    else {
                      $('#exercise-settings-' + option).val(value);
                    }
                  }
                  if (node.type === 'pe') {
                    var hideCode = 'JXOP-code' in options && options['JXOP-code'] === 'none';
                    $('#exercise-settings-' + option).prop('checked', hideCode);
                    if ($('#exercise-settings-feedback').val() === 'continuous') {
                      $('#exercise-settings-fix').removeAttr('disabled');
                    }
                    else {
                      $('#exercise-settings-fix').attr('disabled', true);
                    }
                  }
                  exSettingsDialog.dialog('option', 'nodeId', node.id);
                  exSettingsDialog.dialog('open');
                }
              },
              'reset-settings': {
                label: 'Reset Settings',
                action: function(args) {
                  var node = getIncludedNode(args.reference);
                  deleteAllOptions(node.id);
                }
              }
            };
          }
          return {};
        }
      },
      'node_customize': {
        // customize node appearances when they are rendered
        default: function(elem, node) {
          if (!node) return;
          var anchor = $(elem).find('#' + node.id + '_anchor');
          if (node.id in optionChanges) {
            markModified(node.id, anchor);
          }
          if (hasModifiedChildren(node.id)) {
            markModifiedChildren(node.id, anchor);
          }
        }
      },
      'core': {
        // control which operations are allowed for each node type
        'check_callback': function (operation, node, node_parent, node_position, more) {
          if (node.type === 'chapter') {
            if (operation === 'delete_node') {
              // only allow deletion of chapters with no children
              return node.children.length === 0;
            }
            if (operation === 'rename_node') return true;
            // '#' is the type of the root node
            // chapters can only be children of the root node
            return node_parent.type === '#' && (operation === 'move_node' || operation === 'create_node');
          }
          if (node.type === 'module') {
            if (operation === 'move_node') {
              // only allow modules to be children of chapters
              return node_parent.type === 'chapter';
            }
            if (operation === 'copy_node' && more.is_multi) {
              // allow nodes to be copied from the Available tree only
              node.original.included = true;
              return true;
            }
            if (operation === 'delete_node') {
              // only allow deletion of nodes marked as not being included
              // in the book
              return node.original.included === false;
            }
          }
          return false;
        },
        'data': includedData
      },
      'plugins': ['dnd', 'types', 'wholerow', 'contextmenu', 'node_customize']
    });

    availTreeElem = $('#available-modules');
    // tree of modules available to be included in the book
    availTree = availTreeElem.jstree({
        'types': itemTypes,
        'dnd': {
          // drag and drop settings
          copy: false,
          is_draggable: function (nodes) {
            for (var i = 0; i < nodes.length; i++) {
              if (nodes[i].type !== 'module') return false;
            }
            return true;
          }
        },
        'conditionalselect': function(node, event) {
          // only modules can be seelcted
          return node.type === 'module';
        },
        'contextmenu': {
          items: function(node) {
            return {}; // no context menu
          }
        },
        'sort': function(node1, node2) {
          // sort nodes in alphabetical order
          var n1 = this.get_node(node1);
          var n2 = this.get_node(node2);
          if (n1.type === n2.type) {
            return n1.text > n2.text ? 1 : -1;
          }
          return n1.type === 'chapter' ? 1 : -1;
        },
        'core': {
          'check_callback': function (operation, node, node_parent, node_position, more) {
            // only allow deleting of nodes that were moved to the Included tree
            return operation === 'copy_node' ||
              (operation === 'delete_node' && node.original.included);
          },
          'data': availData
        },
        'plugins': ['search', 'dnd', 'types', 'wholerow', 'conditionalselect', 'sort', 'contextmenu']
      });

      // when nodes are moved to a different tree through drag and drop,
      // their original data is not copied by jsTree, so we have to copy
      // it over ourselves
      function restoreData(tree, node, origTree, original) {
        node = tree.jstree().get_node(node);
        original = origTree.jstree().get_node(original);
        Object.assign(node.original, original.original);
        tree.jstree().set_id(node, original.id);
        $.each(node.children, function(index, child) {
          var origChild = original.children[index];
          restoreData(tree, child, origTree, origChild);
        });
      }

      $("#included-modules").bind('copy_node.jstree', function(e, data) {
        restoreData(includedTree, data.node, availTree, data.original);
      });

      $("#available-modules").bind('copy_node.jstree', function(e, data) {
        restoreData(availTree, data.node, includedTree,data.original);
      });

      $("#available-modules").bind('ready.jstree', function() {
        if (chapters) {
          // we are loading an existing configuration
          for (var chapter in chapters) {
            var modules = chapters[chapter];
            addChapter(chapter);
            var chapterNode = getIncludedNode('chapter_' + encodeId(chapter));
            for (var mod in modules) {
              var children = modules[mod];
              var modId = encodeId(mod);
              var modNode = getAvailNode(modId);
              addModule(modNode, chapterNode);
              for (var child in children) {
                var id = '|';
                var options = children[child];
                if ('showsection' in options) {
                  id += 'sect|' + child;
                }
                else {
                  id += '|' + child;
                }
                id = modNode.id + encodeId(id);
                var childNode = getIncludedNode(id);
                options = cleanOptions(childNode, options);
                for (var option in options) {
                  var value = options[option];
                  setOption(id, option, value);
                }
              }
            }
          }
        }

        $('#btn-add-chapter').removeAttr('disabled');
        if (langSelect.val() !== 'en' || chapters) return;

        // add some default modules
        var intro = availTree.jstree().get_node('Intro');
        var glossary = availTree.jstree().get_node('Glossary');
        var biblio = availTree.jstree().get_node('Bibliography');
        var preface = includedTree.jstree().get_node('chapter_Preface');
        var appendix = includedTree.jstree().get_node('chapter_Appendix');
        addModule(intro, preface);
        addModule(glossary, appendix);
        addModule(biblio, appendix);
      });
  }
})();