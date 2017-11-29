(function () {
  var availMods = null;
  var includedMods = null;
  var langSelect = null;

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
      $('#btn-add-chapter').removeAttr('disabled');
      initializeJsTree(ODSA.availableModules[langSelect.val()].children);
    });

    var addChapterDialog = $('#add-chapter-dialog').dialog({
      autoOpen: false,
      modal: true,
      buttons: {
        'Add': function() {
          if (addChapter()) {
            addChapterDialog.dialog('close');
          }
        },
        'Cancel': function() {
          addChapterDialog.dialog('close');
          updateDialogErrors('');
        }
      },
      close: function() {
        form[0].reset();
      },
      open: function() {
        updateDialogErrors('');
      }
    });

    form = addChapterDialog.find('form').on('submit', function(event) {
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
  });

  /**
   * Initialize the resource selection tree
   */
  function initializeJsTree(availData) {
    if (availMods !== null) {
      availMods.jstree('destroy');
      includedMods.jstree('destroy');
    }

    var includedData = [];
    if (langSelect.val() === 'en') {
      includedData = [
        {text: 'Preface', id: 'Preface', type: 'chapter'},
        {text: 'Appendix', id: 'Appendix', type: 'chapter'}
      ];
    }

    // tree of chapters and modules included in the book
    includedMods = $("#included-modules").jstree({
      'types': {
        'chapter': {
        },
        'module': {
          icon: 'fa fa-sticky-note-o'
        }
      },
      'dnd': {
        copy: false,
        is_draggable: function (nodes) {
          return true;
        }
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
                  var node = includedMods.jstree(true).get_node(args.reference);
                  
                }
              },
              'remove': {
                label: 'Remove',
                action: function(args) {
                  var node = includedMods.jstree(true).get_node(args.reference);
                  // remove all of the modules in the chapter
                  while (node.children.length > 0) {
                    var child = includedMods.jstree(true).get_node(node.children[0]);
                    removeModule(child);
                  }
                  // remove the chapter
                  includedMods.jstree(true).delete_node(node);
                }
              }
            };
          }
          if (node.type === 'module') {
            return {
              'remove': {
                label: 'Remove',
                action: function(args) {
                  var node = includedMods.jstree(true).get_node(args.reference);
                  removeModule(node);
                }
              }
            };
          }
          return {};
        }
      },
      'core': {
        'check_callback': function (operation, node, node_parent, node_position, more) {
          if (node.type === 'chapter') {
            if (operation === 'delete_node') {
              // only allow deletion of chapters with no children
              return node.children.length === 0;
            }
            // '#' is the type of the root node
            // chapters can only be children of the root node
            return node_parent.type === '#' && operation === 'move_node' || operation === 'create_node';
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
      'plugins': ['search', 'dnd', 'types', 'wholerow', 'contextmenu']
    });

    // tree of modules available to be included in the book
    availMods = $('#available-modules')
      .jstree({
        'types': {
          'category': {
            max_depth: 1
          },
          'module': {
            max_depth: 0,
            icon: 'fa fa-sticky-note-o'
          }
        },
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
          return n1.type === 'category' ? 1 : -1;
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
        Object.assign(data.node.original, data.original.original);
      });

      $("#available-modules").bind('copy_node.jstree', function(e, data) {
        Object.assign(data.node.original, data.original.original);
      });

      $("#available-modules").bind('ready.jstree', function() {
        if (langSelect.val() !== 'en') return;
        var intro = availMods.jstree().get_node('Intro');
        var glossary = availMods.jstree().get_node('Glossary');
        var biblio = availMods.jstree().get_node('Bibliography');
        var preface = includedMods.jstree().get_node('Preface');
        var appendix = includedMods.jstree().get_node('Appendix');
        addModule(intro, preface);
        addModule(glossary, appendix);
        addModule(biblio, appendix);
      });
  }
  
  function removeModule(node) {
    if (node.original.included === false) return false;
    node.original.included = false;
    var parent = availMods.jstree(true).get_node(node.original.parent_id);
    availMods.jstree(true).copy_node(node, parent);
    includedMods.jstree(true).delete_node(node);
  }

  function addModule(node, parent) {
    if (node.original.included === true) return false;
    node.original.included = true;
    includedMods.jstree().copy_node(node, parent);
    availMods.jstree().delete_node(node);
  }

  function rename_chapter(nodeId, newName) {
    includedMods.jstree(true).rename_node(nodeId, newName);
  }

  function addChapter() {
    var valid = true;
    var elem = $('#chapter-name');
    var name = $.trim(elem.val());
    valid = valid && !chapterExists(elem, name);
    valid = valid && checkRegexp(elem, name, /^[\w\s]{1,100}$/, 
      'Name must be between 1 and 100 characters long.');

    if (valid) {
      includedMods.jstree(true).create_node('#', {text: name, type: 'chapter'}, "last");
    }

    return valid;
  }

  function chapterExists(elem, name) {
    var treeNodes = includedMods.jstree(true).get_json();
    for (var i = 0; i < treeNodes.length; i++) {
      var chapterName = treeNodes[i].text;
      if (name.toLowerCase() === chapterName.toLowerCase()) {
        updateDialogErrors('A chapter with that name already exists.');
        return true;
      }
    }
    return false;
  }

  function checkRegexp(elem, value, regexp, error) {
    if (regexp.test(value)) {
      return true;
    }
    updateDialogErrors(error);
    return false;
  }

  function updateDialogErrors(msg) {
    if (!msg) {
      $('#dialog-errors').text('');
      return;
    }
    $('#dialog-errors')
      .text(msg)
      .addClass('ui-state-highlight');
    setTimeout(function() {
      $('#dialog-errors').removeClass('ui-state-highlight', 1500);
    }, 500);
  }

})();