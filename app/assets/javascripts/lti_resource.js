(function() {
  $(document).ready(function() {
      $('#dismiss-button').on('click', function(event) {
          $('#alert-box').css('display', 'none');
      })

      if (window.odsa_organizations) {
          $('#select_organization').on('change', function() {
              if ($('#select_organization').val() == -1) {
                  $('#organization_name').attr('required', true);
                  $('#organization_abbreviation').attr('required', true);
                  $('#other_organization_inputs').css('display', '');
              }
              else {
                  $('#organization_name').removeAttr('required');
                  $('#organization_abbreviation').removeAttr('required');
                  $('#other_organization_inputs').css('display', 'none');
              }
          });

          $('#organization_form').on('submit', function(event) {
              event.preventDefault();
              orgId = $('#select_organization').val();
              if (orgId == -1) {
                  $.ajax({
                      url: '/organizations',
                      type: 'post',
                      data: 'organization_name=' + $('#organization_name').val()
                          + '&organization_abbreviation=' + $('#organization_abbreviation').val()
                  }).done(function(data) {
                      $('#alert-box').css('display', 'none');
                      createCourseOffering(data.id);
                  }).fail(function(data) {
                      displayErrors(data.responseJSON);
                  });
              }
              else {
                  createCourseOffering(orgId);
              }
          });
      }
      else {
          initializeJsTree();
      }
  }); 

  function createCourseOffering(organizationId) {
      odsa_course_info.organization_id = organizationId;
      $.ajax({
          url: '/lti/course_offering',
          type: 'post',
          data: JSON.stringify(odsa_course_info),
          contentType: 'application/json'
      }).done(function(data) {
          $('#alert-box').css('display', 'none');
          $('#organization_form').css('display', 'none');
          initializeJsTree();
      }).fail(function(data) {
          displayErrors(data.responseJSON);
      });
  }

  function displayErrors(errors) {
      html = '';
      for (var error of errors) {
          html += '<li>' + error + '</li>';
      }
      $('#alert-messages').html(html);
      $('#alert-box').css('display', '');
  }

  // prepare and send back the complete url used by canvas to configure lti launch
  var getResourceURL = function(obj) {
      if (!$.isEmptyObject(obj)) {
          var odsa_url = odsa_launch_url + '?' + $.param(obj);
          var urlParams = {
              'embed_type': 'basic_lti',
              'url': odsa_url
          };
          return return_url + '?' + $.param(urlParams);
      }
      return '';
  };

  function initializeJsTree() {
      var chapters = [];
      // prepare tree data
      $.each(jsonFile, function(ch_index, ch_obj) {
          var tree_ch_obj = {
              'text': ch_index,
              'children': []
          };
          $.each(ch_obj, function(mod_index, exercises) {
              if (exercises !== null) {
                  var tree_mod_obj = {
                      'text': mod_index,
                      'children': []
                  };
                  $.each(exercises, function(ex_index, ex) {
                      if (ex !== null) {
                          var tree_sec_obj = {
                              'text': ex.long_name,
                              'type': 'section',
                              'url_params': {
                                  'ex_short_name': ex.short_name
                              }
                          }
                          tree_mod_obj['children'].push(tree_sec_obj);
                      }
                  });
                  tree_ch_obj['children'].push(tree_mod_obj);
              }
          });
          chapters.push(tree_ch_obj);
      });

      // insialize tree instance
      $('#using_json')
      
      // listen for select event
      .on('select_node.jstree', function(e, data) {
          var selected = data.instance.get_node(data.selected);
          if (selected.original.type === 'section') {
              console.log(getResourceURL(selected.original.url_params));
              window.location.href = getResourceURL(selected.original.url_params);
          }
      })

      .jstree({
          'core': {
              'data': [{
                  'text': 'OpenDSA Exercises and Visualizations',
                  'state': {
                      'opened': true,
                      'selected': true
                  },
                  'children': chapters
              }]
          }
      });
  }

}).call(this);