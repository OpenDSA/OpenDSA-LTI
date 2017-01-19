$(function() {
  var firstTime = true;

  function count($this) {

    var aj = $.ajax({
      url: "/odsa_exercise_progresses/get_count",
      type: 'get',
      data: $(this).serialize()
    }).done(function(data) {
      if (firstTime) {
        $this.prop('Counter', 0).animate({
          Counter: data['practiced_ex']
        }, {
          duration: 4000,
          easing: 'swing',
          step: function(now) {
            $this.html(Math.ceil(now));
          }
        });
        firstTime = false;
      } else {
        $this.html(data['practiced_ex']);
      }
    }).fail(function(data) {
      console.log('AJAX request has FAILED');
    });

    setTimeout(function() {
      count($this)
    }, 15000);
  }

  $stat_count = $(".stat-count");
  if ($stat_count.length) {
    count($stat_count);
  }
});