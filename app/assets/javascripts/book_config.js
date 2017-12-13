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

  $(document).ready(function () {
    var pane1 = document.querySelector('#chosen-pane');
    var pane2 = document.querySelector('#available-pane');
    Split([pane1, pane2], {
      sizes: [50, 50],
      minSize: 200
    });

    langSelect = $('#book-lang');
    if (langSelect.val() != null && langSelect.val() != -1) {
      initializeJsTree(ODSA.availableModules[langSelect.val()].children);
    }
    langSelect.on('change', function() {
      initializeJsTree(ODSA.availableModules[langSelect.val()].children);
    });

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

/*     var globFeedbackSelect = $('#glob-pe-feedback');
    var globFixSelect = $('#glob-pe-fix');
    function updateFeedbackFixSelects() {
      var val = globFeedbackSelect.val();
      if (val === 'continuous') {
        globFixSelect.removeAttr('disabled');
      }
      else {
        globFixSelect.attr('disabled', true);
      }
    }
    updateFeedbackFixSelects();
    globFeedbackSelect.on('change', updateFeedbackFixSelects); */

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

    $('#book-config-form').on('submit', function(event) {
      event.preventDefault();
      var config = allGlobalSettings();
      config.chapters = includedChapters();

      var dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(config, null, 2));
      var exportName = config.title.replace(' ', '_');
      var downloadAnchorNode = document.createElement('a');
      downloadAnchorNode.setAttribute("href", dataStr);
      downloadAnchorNode.setAttribute("download", exportName + ".json");
      downloadAnchorNode.style.display = 'none';
      document.body.appendChild(downloadAnchorNode);
      downloadAnchorNode.click();
      downloadAnchorNode.remove();
    });
  });

  /* changes made from default options
     items have format:
     '<node_id>': {
       '<setting_name>': '<setting_value>'
     }
  */
  var optionChanges = {};

  function markModified(nodeId, elem) {
    var iconId = nodeId + '_modified';
    if (getOption(nodeId, 'showsection') === false) {
      $(elem).addClass('section-hidden');
    }
    if ($('#' + iconId).length === 0) {
      elem.prepend('<i id="' + iconId + '" class="jstree-icon modified-icon">M</i>');
      var node = getIncludedNode(nodeId);
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

  function markNotModifiedChildren(nodeId) {
    var iconId = nodeId + '_childmodified';
    $('#' + iconId).remove();
  }

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

  function deleteOption(nodeId, optionName) {
    var opts = optionChanges[nodeId];
    if (typeof opts === 'undefined') return;
    delete opts[optionName];
    if ($.isEmptyObject(opts)) {
      // the options object is empty, so remove it
      deleteAllOptions(nodeId);
    }
  }

  function getOption(nodeId, optionName) {
    var opts = optionChanges[nodeId];
    if (!$.isEmptyObject(opts)) {
      return optionChanges[nodeId][optionName];
    }
    return undefined;
  }

  function getOptions(node) {
    if (typeof node !== 'object') {
      node = getIncludedNode(node);
    }
    var opts = optionChanges[node.id] || {};
    if (node.type === 'ka') {
      opts = $.extend(globalKaSettings(), opts);
    }
    else if (node.type === 'pe') {
      opts = $.extend(globalPeSettings(), opts);
    }
    else if (node.type === 'extr') {
      opts = $.extend(globalExtrSettings(node.original.learning_tool), opts);
    }
    else {
      return {};
    }
    return opts;
  }

  function getOptionChanges(nodeId) {
    return optionChanges[nodeId];
  }

  function hasOptionChanges(nodeId) {
    return nodeId in optionChanges;
  }

  function deleteAllOptions(nodeId) {
    delete optionChanges[nodeId];
    markNotModified(nodeId);
  }
  
  function removeModule(node) {
    if (node.original.included === false) return false;
    node.original.included = false;
    var parent = availTree.jstree(true).get_node(node.original.parent_id);
    availTree.jstree(true).copy_node(node, parent);
    includedTree.jstree(true).delete_node(node);
  }

  function addModule(node, parent) {
    if (node.original.included === true) return false;
    node.original.included = true;
    includedTree.jstree().copy_node(node, parent);
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

  function addChapter() {
    var elem = $('#chapter-name');
    var name = $.trim(elem.val());
    var valid = validateChapterName(addChapterDialog, name);

    if (valid) {
      includedTree.jstree(true).create_node('#', {text: name, type: 'chapter'}, "last");
    }

    return valid;
  }

  function validateChapterName(dialog, name, ignore) {
    var valid = !chapterExists(dialog, name, ignore);
    valid = valid && checkRegexp(dialog, name, /^[\w\s]{1,100}$/, 
      'Name must be between 1 and 100 characters long.');
    return valid;
  }

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

  function checkRegexp(dialog, value, regexp, error) {
    if (regexp.test(value)) {
      return true;
    }
    updateDialogErrors(dialog, error);
    return false;
  }

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

  function globalExerSettings() {
    return {
      'JXOP-debug': $('#jsav-debug').is('checked')
    };
  }

  function globalKaSettings() {
    return {
      required: $('#glob-ka-required').is(':checked'),
      points: Number.parseFloat($('#glob-ka-points').val()),
      threshold: Number.parseInt($('#glob-ka-threshold').val())
    };
  }

  function globalPeSettings() {
    return {
      required: $('#glob-pe-required').is(':checked'),
      points: Number.parseFloat($('#glob-pe-points').val()),
      threshold: Number.parseFloat($('#glob-pe-threshold').val())
    };
  }
  
  function globalSsSettings() {
    return {
      required: false,
      points: 0,
      threshold: 1
    };
  }

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

  function selectedCodeLanguages() {
    var checkboxes = $('input:checkbox[name=code-lang]:checked');
    var selected = {};
    for (var i = 0; i < checkboxes.length; i++) {
      var lang = checkboxes[i].value;
      selected[lang] = ODSA.codeLanguages[lang];
    }
    return selected;
  }

  function allGlobalSettings() {
    return {
      title: $('#book-title').val(),
      description: $('#book-desc').val(),
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

  function getAvailNode(node) {
    return availTree.jstree().get_node(node);
  }

  function getIncludedNode(node) {
    return includedTree.jstree().get_node(node);
  }

  function setExerciseSettings(node, settings) {
    var globalSettings;
    switch (node.type) {
      case 'ka':
        globalSettings = globalKaSettings();
        break;
      case 'pe':
        globalSettings = globalPeSettings();
        break;
      case 'extr':
        globalSettings = globalExtrSettings(node.original.learning_tool);
        break;
      default:
        return;
    }
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

  function onGlobalExerciseSettingsUpdate(type, changes, toolName) {
    // remove any exercise setting changes that are equal to
    // the new global options
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

  /**
   * Initialize the resource selection tree
   */
  function initializeJsTree(availData) {
    if (availTree) {
      availTree.jstree('destroy');
      includedTree.jstree('destroy');
    }

    var includedData = [];
    if (langSelect.val() === 'en') {
      includedData = [
        {text: 'Preface', id: 'Preface', type: 'chapter'},
        {text: 'Appendix', id: 'Appendix', type: 'chapter'}
      ];
    }

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
        copy: false,
        is_draggable: function (nodes) {
          return true;
        },
        inside_pos: 'last'
      },
      'search': {
        fuzzy: true
      },
      'contextmenu': {
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
            if (node.original.showsection) {
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
          if ($.inArray(node.type, ['ka', 'pe', 'extr']) >= 0) {
            return {
              'settings': {
                label: 'Edit Exercise Settings',
                action: function(args) {
                  exSettingsDialog.find('form')[0].reset();
                  var node = includedTree.jstree(true).get_node(args.reference);
                  var thresholdElem = $('#exercise-settings-threshold');
                  if (node.type === 'ka') {
                    thresholdElem.attr('step', 1);
                    thresholdElem.attr('min', 1);
                    thresholdElem.removeAttr('max');
                    $('#exercise-settings-pe').css('display', 'none');
                    $('#exercise-settings-required-group').css('display', '');
                    $('#exercise-settings-threshold-group').css('display', '');
                  }
                  else if (node.type === 'pe') {
                    thresholdElem.attr('min', 0);
                    thresholdElem.attr('max', 1);
                    thresholdElem.attr('step', 0.1);
                    $('#exercise-settings-pe').css('display', '');
                    $('#exercise-settings-required-group').css('display', '');
                    $('#exercise-settings-threshold-group').css('display', '');
                  }
                  else if (node.type === 'extr') {
                    // external tool
                    $('#exercise-settings-pe').css('display', 'none');
                    $('#exercise-settings-required-group').css('display', 'none');
                    $('#exercise-settings-threshold-group').css('display', 'none');
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
        default: function(elem, node) {
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
      'plugins': ['search', 'dnd', 'types', 'wholerow', 'contextmenu', 'node_customize']
    });

    availTreeElem = $('#available-modules');
    // tree of modules available to be included in the book
    availTree = availTreeElem.jstree({
        'types': itemTypes,
        'dnd': {
          copy: false,
          is_draggable: function (nodes) {
            for (var i = 0; i < nodes.length; i++) {
              if (nodes[i].type !== 'module') return false;
            }
            return true;
          }
        },
        'search': {
          fuzzy: true
        },
        'conditionalselect': function(node, event) {
          return node.type === 'module';
        },
        'contextmenu': {
          items: function(node) {
            return {}; // no context menu
          }
        },
        'sort': function(node1, node2) {
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

      $("#included-modules").bind('copy_node.jstree', function(e, data) {
        restoreData(includedTree, data.node, availTree, data.original);
      });

      $("#available-modules").bind('copy_node.jstree', function(e, data) {
        restoreData(availTree, data.node, includedTree,data.original);
      });

      // when nodes are moved to a different tree through drag and drop, 
      // their original data is not copied by jsTree, so we have to copy
      // it over ourselves
      function restoreData(tree, node, origTree, original) {
        node = tree.jstree().get_node(node);
        original = origTree.jstree().get_node(original);
        Object.assign(node.original, original.original);
        $.each(node.children, function(index, child) {
          var origChild = original.children[index];
          restoreData(tree, child, origTree, origChild);
        });
      }

      $("#available-modules").bind('ready.jstree', function() {
        $('#btn-add-chapter').removeAttr('disabled');
        if (langSelect.val() !== 'en') return;
        var intro = availTree.jstree().get_node('Intro');
        var glossary = availTree.jstree().get_node('Glossary');
        var biblio = availTree.jstree().get_node('Bibliography');
        var preface = includedTree.jstree().get_node('Preface');
        var appendix = includedTree.jstree().get_node('Appendix');
        addModule(intro, preface);
        addModule(glossary, appendix);
        addModule(biblio, appendix);
      });
  }
})();