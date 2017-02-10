$(function() {

    function numberWithCommas(x) {
        return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    function count($this) {
        var aj = $.ajax({
            url: "/odsa_exercise_progresses/get_count",
            type: 'get',
            data: $(this).serialize()
        }).done(function(data) {
            $this.html(numberWithCommas(data['practiced_ex']));
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