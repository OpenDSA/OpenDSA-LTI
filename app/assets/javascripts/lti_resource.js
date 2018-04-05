(function () {
  $(document).ready(function () {
    // whether we know what organization they are from
    hasOrg = typeof window.organization_id !== 'undefined';

    $('#dismiss-button').on('click', function (event) {
      $('#alert-box').css('display', 'none');
    });

    if (window.course_offering_id) {
      // course offering already exists, let them pick an exercise/visualization
      initializeJsTree();
    }
    else {
      // course offering doesn't exist, make the user provide some info first
      $('#course_info_form').on('submit', function (event) {
        event.preventDefault();
        orgId = hasOrg ? window.organization_id : $('#select_organization').val();
        courseId = $('#select_course').val();
        if (orgId == -1) {
          // need to create organization, course, and course offering
          $.ajax({
            url: '/organizations',
            type: 'post',
            data: 'organization_name=' + $('#organization_name').val() +
            '&organization_abbreviation=' + $('#organization_abbreviation').val()
          }).done(function (data) {
            $('#alert-box').css('display', 'none');
            var courseNumber = $('#course_number').val();
            var courseName = $('#course_name').val();
            createCourse(courseNumber, courseName, data.id);
          }).fail(function (data) {
            displayErrors(data.responseJSON);
          });
        }
        else if (courseId == -1) {
          // need to create course and course offering
          var courseNumber = $('#course_number').val();
          var courseName = $('#course_name').val();
          createCourse(courseNumber, courseName, orgId);
        }
        else {
          // just need to create course offering
          createCourseOffering(orgId, courseId);
        }
      });
      $('#select_course').on('change', function () {
        var selectCourse = $('#select_course');
        var otherCourseInputs = $('#other_course_inputs');
        id = selectCourse.val();
        if (id == -1) {
          // they selected "Other", so make them tell us the course name and number
          enableOtherCourseInputs();
        }
        else {
          // they selected a pre-existing course
          disableOtherCourseInputs();
        }
      });
      if (hasOrg) {
        populateCourses(window.organization_id);
      }
      else {
        $('#select_organization').on('change', function () {
          var orgId = $('#select_organization').val();
          if (orgId == -1) {
            // they selected "Other", so make them provide us info about their
            // organization
            $('#organization_name').attr('required', true);
            $('#organization_abbreviation').attr('required', true);
            $('#other_organization_inputs').css('display', '');
          }
          else {
            // they selected a pre-existing organization
            $('#organization_name').removeAttr('required');
            $('#organization_abbreviation').removeAttr('required');
            $('#other_organization_inputs').css('display', 'none');
          }
          populateCourses(orgId);
        });
      }
    }
  });

  /**
   * Enabled the course name and course number inputs
   */
  function enableOtherCourseInputs() {
    courseSelect = $('#select_course');
    otherCourseInputs = $('#other_course_inputs');

    courseSelect.removeAttr('required');
    otherCourseInputs.css('display', '');
    otherCourseInputs.find('#course_number').attr('required', true);
    otherCourseInputs.find('#course_name').attr('required', true);
  }

  /**
   * Disable the course name and course number inputs
   */
  function disableOtherCourseInputs() {
    courseSelect = $('#select_course');
    otherCourseInputs = $('#other_course_inputs');

    courseSelect.attr('required', true);
    courseSelect.removeAttr('disabled');
    otherCourseInputs.css('display', 'none');
    otherCourseInputs.find('#course_number').removeAttr('required');
    otherCourseInputs.find('#course_name').removeAttr('required');
  }

  /**
   * Populate the course select dropdown based on the user's
   * organization, or enable the other course info inputs
   * if we don't know the user's organization
   * @param organizationId
   */
  function populateCourses(organizationId) {
    courseSelect = $('#select_course');
    otherCourseInputs = $('#other_course_inputs');
    if (organizationId == -1) {
      courseSelect.html('');
      courseSelect.attr('disabled', true);
      enableOtherCourseInputs();
      return;
    }
    disableOtherCourseInputs();

    html = '<option disabled="" selected="" value="-2"></option>';
    $.ajax({
      url: '/courses/' + organizationId + '/list',
      type: 'get',
      contentType: 'application/json'
    }).done(function (data) {
      data.forEach(function (course) {
        html += '<option value="' + course.id + '">' +
          course.number + ': ' + course.name +
          '</option>';
      });
      html += '<option value="-1">Other</option>';
      courseSelect.html(html);
      courseSelect.removeAttr('disabled');
    }).fail(function (data) {
      courseSelect.html('');
      displayErrors(data.responseJSON);
    });
  }

  /**
   * Creates a new course
   * @param {*} number
   * @param {*} name 
   * @param {*} organizationId 
   */
  function createCourse(number, name, organizationId) {
    request_data = {
      course: {
        name: name,
        number: number,
        organization_id: organizationId
      }
    };
    $.ajax({
      url: '/courses',
      type: 'post',
      data: JSON.stringify(request_data),
      contentType: 'application/json'
    }).done(function (data) {
      $('#alert-box').css('display', 'none');
      createCourseOffering(organizationId, data.id);
    }).fail(function (data) {
      displayErrors(data.responseJSON);
    });
  }

  /**
   * Creates a new course offering
   * @param {*} organizationId 
   * @param {*} courseId 
   */
  function createCourseOffering(organizationId, courseId) {
    var course_offering = window.odsa_course_info.course_offering;
    course_offering.organization_id = organizationId;
    course_offering.course_id = courseId;
    course_offering.term_id = $('#select_term').val();
    $.ajax({
      url: '/course_offerings',
      type: 'post',
      data: JSON.stringify(window.odsa_course_info),
      contentType: 'application/json'
    }).done(function (data) {
      $('#alert-box').css('display', 'none');
      $('#course_info_form').css('display', 'none');
      initializeJsTree();
    }).fail(function (data) {
      displayErrors(data.responseJSON);
    });
  }

  /**
   * Displays the specified errors
   * @param {*} errors 
   */
  function displayErrors(errors) {
    html = '';
    errors.forEach(function (error) {
      html += '<li>' + error + '</li>';
    });
    $('#alert-messages').html(html);
    $('#alert-box').css('display', '');
  }

  // prepare and send back the complete url used by canvas to configure lti launch
  var getResourceURL = function (obj) {
    if (!$.isEmptyObject(obj)) {
      var odsa_url = odsa_launch_url + '?' + $.param(obj);
      if (deepLinking) {
        return odsa_url;
      }
      var urlParams = {
        'embed_type': 'basic_lti',
        'url': odsa_url
      };
      return return_url + '?' + $.param(urlParams);
    }
    return '';
  };

  /**
   * Initialize the resource selection tree
   */
  function initializeJsTree() {
    var chapters = [];
    // prepare tree data
    $.each(jsonFile, function (ch_index, ch_obj) {
      var tree_ch_obj = {
        'text': ch_index,
        'children': []
      };
      $.each(ch_obj, function (mod_index, exercises) {
        if (exercises !== null) {
          var tree_mod_obj = {
            'text': mod_index,
            'children': []
          };
          $.each(exercises, function (ex_index, ex) {
            if (ex !== null) {
              var tree_sec_obj = {
                'text': ex.long_name,
                'type': 'section',
                'url_params': {
                  'ex_short_name': ex.short_name
                }
              };
              tree_mod_obj.children.push(tree_sec_obj);
            }
          });
          tree_ch_obj.children.push(tree_mod_obj);
        }
      });
      chapters.push(tree_ch_obj);
    });

    // insialize tree instance
    $('#using_json')

      // listen for select event
      .on('select_node.jstree', function (e, data) {
        var selected = data.instance.get_node(data.selected);
        if (selected.original.type === 'section') {
          console.log(getResourceURL(selected.original.url_params));
          var url = getResourceURL(selected.original.url_params);
          if (deepLinking) {
            var contentItem = {
              '@context': 'http://purl.imsglobal.org/ctx/lti/v1/ContentItem',
              '@graph': [
                {              
                  '@type': 'ContentItem',
                  'mediaType': 'text/html',
                  'title': selected.text,
                  'url': url,
                  'placementAdvice': {
                    'displayWidth': 800,
                    'displayHeight': 1000,
                    'presentationDocumentTarget': 'iframe'
                  }
                }
              ]
            };
            var jsonStr = JSON.stringify(contentItem);
            //jsonStr = jsonStr.replace(/"/g, "&quot;").replace(/'/g, "&#39;");
            //jsonStr = JSON.encode(jsonStr)
            window.content_item_params.content_items = jsonStr;
            $('#content_items').attr('value', jsonStr);
            $.ajax({
              url: '/lti/content_item_selection',
              type: 'post',
              data: JSON.stringify(content_item_params),
              contentType: 'application/json'
            }).done(function (data) {
              for (var key in data) {
                $('input[name="' + key + '"]').attr('value', data[key]);
              }
              $('#return_form').submit();
            }).fail(function (data) {
              displayErrors(data.responseJSON);
            });
          }
          else {
            window.location.href = url;
          }
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