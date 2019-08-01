$(document).on("turbolinks:load", function () {

  // on video search page, we are not updating the video url but when clicked on the video link in browser,
  //  we need the pretty url. To obtain the pretty url in the browser url we use this js code
  if ($(".video-display").length > 0) {
    if ($(".video-display").attr("data-id").length > 0) {
      window.history.pushState($(".video-display").attr("data-id"), "", "/videos/" + $(".video-display").attr("data-id"));
    }
  }

  // hide by default
  hide_conversion_card_and_guest_delay();

  // Start conversion button clicked
  $("#conversion-start-button").click(function (e) {
    e.preventDefault();
    // remove flash message if there are any
    $(".alert-fixed-right").hide("");

    // check guest video length limit
    if (gon.has_active_subscription === false) {
      var today_date = new Date();
      start_time_in_hrs_mins_sec = get_time_in_hrs_mins_sec($("#start-time").val());
      end_time_in_hrs_mins_sec = get_time_in_hrs_mins_sec($("#end-time").val());
      var input_start_time = new Date(today_date.getFullYear(), today_date.getMonth(), today_date.getDate(), start_time_in_hrs_mins_sec.hours, start_time_in_hrs_mins_sec.minutes, start_time_in_hrs_mins_sec.seconds, 0);
      var input_end_time = new Date(today_date.getFullYear(), today_date.getMonth(), today_date.getDate(), end_time_in_hrs_mins_sec.hours, end_time_in_hrs_mins_sec.minutes, end_time_in_hrs_mins_sec.seconds, 0);
      var minutes = ((input_end_time - input_start_time) / 60000);
      if (minutes > gon.guest_video_duration_limit_minutes) {
        display_video_length_limit_confirmation();
        return false;
      }
    }

    // in case converting same video
    hide_conversion_card_and_guest_delay();
    reset_conversion_time_0();
    $(".conversion-timer").stopwatch().stopwatch("stop");
    $(".conversion-timer").stopwatch().stopwatch("reset");

    // change progress bar state
    change_progress_bar_converting();

    // disable the conversion options
    disable_conversion_options();

    // request to fetch delay countdown display status and delay value in seconds
    request = $.ajax({
      url: "/videos/delay_download"
    });
    request.done(function (data) {
      // check to show delay countdown or not
      if (data.status) {

        // show guest delay div
        $("#guest-delay").show();
        show_timers();

        // start delay countdown
        now = new Date
        now.setSeconds(now.getSeconds() + data.delay_seconds)
        $(".delay-timer").countdown(now, function (event) {
          $(this).html(event.strftime(" %S seconds"));
        });

        // show the spinner
        $("#delay-timer-spinner").show();

        // start conversion after delay countdown finished
        setTimeout(function () {
          // hide the spinner
          $("#delay-timer-spinner").hide();
          initialize_start_conversion();
        }, data.delay_seconds * 1000)
      }
      else {
        // start conversion without any delay countdown
        initialize_start_conversion();
      };
    });
  });

  $("#reset-start-time").click(function () {
    $("#start-time").val(gon.video_start_time);
  });

  $("#reset-end-time").click(function () {
    $("#end-time").val(gon.video_end_time);
  });

  $("#start-time, #end-time").click(function () {
    $(this).val("");
  });

  $("#start-time, #end-time").keypress(function (evt) {
    auto_format_input_on_enter($(this), evt.keyCode);
    var theEvent = evt || window.event;
    var key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode(key);
    var regex = /[0-9]/;
    if (!regex.test(key)) {
      theEvent.returnValue = false;
      if (theEvent.preventDefault) theEvent.preventDefault();
    }
  });

  $("#start-time").blur(function () {
    validate_start_time();
  });

  $("#end-time").blur(function () {
    validate_end_time();
  });
}); // on("turbolinks:load") end

function initialize_start_conversion() {
  // start conversion time
  $(".conversion-timer").stopwatch().stopwatch("start");

  // display conversion in progress message
  window.inprogress_message = setTimeout(function () {
    show_conversion_inprogress_modal();
  }, gon.video_converting_modal_showafter_seconds * 1000)

  // show the spinner
  $("#conversion-timer-spinner").show();

  change_progress_bar_converting();
  show_conversion_card();
  hide_timers();

  var video_id = $("#id").val();
  var identifier = $("#identifier").val();
  // subscribe to the channel 'VideoStatusChannel' for getting the video conversion status message broadcast by action cable.
  displayVideoStatus(video_id, identifier);
  // request to video conversion
  $.ajax({
    url: "/videos/convert",
    type: "GET",
    data: {
      id: video_id,
      video_format: $("#video-format").val(),
      start_time: $("#start-time").val(),
      end_time: $("#end-time").val(),
    }
  });
};

function disable_conversion_options() {
  $("#video-format").attr("disabled", true);
  $("#start-time").attr("disabled", true);
  $("#end-time").attr("disabled", true);
  $("#reset-start-time").attr("disabled", true);
  $("#reset-end-time").attr("disabled", true);
  $("#conversion-start-button").attr("disabled", true);
};

function enable_conversion_options() {
  $("#video-format").attr("disabled", false);
  $("#start-time").attr("disabled", false);
  $("#end-time").attr("disabled", false);
  $("#reset-start-time").attr("disabled", false);
  $("#reset-end-time").attr("disabled", false);
  $("#conversion-start-button").attr("disabled", false);
};

function hide_conversion_card_and_guest_delay() {
  $("#conversion-card").hide();
  $("#download-file").hide();
  $("#guest-delay").hide();
};

function show_timers() {
  $(".guest-delay-countdown").show();
};

function hide_timers() {
  $(".guest-delay-countdown").hide();
};

function show_conversion_card() {
  $("#conversion-card").show();
  show_timers();
  $("#download-file").show();
};

function change_progress_bar_converting() {
  $("#conversion-progress-status").show();
  $("#conversion-progress-bar").show();
  $("#conversion-status-text").html("Starting...");
  $(".progress-bar").addClass("bg-warning");
  $(".progress-bar").addClass("progress-bar-animated");
  $(".progress-bar").width("5%").attr("aria-valuenow", 5);
  $(".progress-bar").html("5%");
  $("#download-file-button").addClass("disabled");
  // reset download file button link
  $("#download-file-button").attr("href", "javascript:void(0)");
};

function change_progress_bar_completed() {
  $(".progress-bar").removeClass("bg-warning");
  $(".progress-bar").removeClass("progress-bar-animated");
  $(".progress-bar").width("100%").attr("aria-valuenow", 5);
  $(".progress-bar").html("100%");
};

function guest_download_limit_triggered() {
  close_conversion_inprogress_modal();
  change_progress_bar_completed();
  hide_conversion_card_and_guest_delay();
  // show guest delay div
  $("#guest-delay").show();
  hide_timers();
};

function reset_conversion_card_proxy_retry() {
  disable_conversion_options();
  change_progress_bar_converting();
  show_conversion_card();
}

function restart_conversion_timer() {
  $(".conversion-timer").stopwatch().stopwatch("stop");
  $(".conversion-timer").stopwatch().stopwatch("reset");
  $(".conversion-timer").stopwatch().stopwatch("start");
}

function reset_conversion_time_0() {
  $(".conversion-timer").html(" 0 seconds");
};

function user_input_time(passed_time) {
  var today_date = new Date();
  time_in_hrs_mins_sec = get_time_in_hrs_mins_sec(passed_time);
  var date = new Date(today_date.getFullYear(), today_date.getMonth(), today_date.getDate(), time_in_hrs_mins_sec.hours, time_in_hrs_mins_sec.minutes, time_in_hrs_mins_sec.seconds, 0);
  return Date.parse(date);
};

function update_time_value(input_time, actual_time, input_selector) {
  if ($.trim(input_time) === "") {
    $("#" + input_selector).val(actual_time);
  }
};

function auto_format_time(input_time, input_selector, actual_time) {
  if (input_time.indexOf(":") >= 0) {
    input_time = $.trim(input_time.replace(/\:/g, ''));
  }
  if (input_time.length === 1) {
    input_time = "00:0" + input_time;
  }
  else if (input_time.length === 3) {
    input_time = "0" + input_time.substr(0, 1) + ":" + input_time.substr(1, 2);
  }
  else if (input_time.length === 4) {
    input_time = input_time.substr(0, 2) + ":" + input_time.substr(2, 3);
  }
  else if (input_time.length === 5) {
    input_time = "0" + input_time.substr(0, 1) + ":" + input_time.substr(1, 2) + ":" + input_time.substr(3, 2);
  }
  else if (input_time.length === 6) {
    input_time = input_time.substr(0, 2) + ":" + input_time.substr(2, 2) + ":" + input_time.substr(4, 2);
  }
  $("#" + input_selector).val(input_time);
  var actual_time_length = actual_time.split(":").length;
  var input_time_length = input_time.split(":").length;
  var time = "";
  if (actual_time_length === 2 && (input_time_length < 2 || input_time_length > 2)) {
    if (input_time_length === 1) {
      time = "00:" + input_time;
    }
    if (input_time_length > 2) {
      var minutes_seconds = input_time.split(":").slice(-2);
      time = minutes_seconds[0] + ":" + minutes_seconds[1];
    }
  }
  if (actual_time_length === 3 && (input_time_length < 3 || input_time_length > 3)) {
    if (input_time.split(":").length < 3) {
      var padding_count = actual_time_length - input_time_length;
      var padding_time = repeat_string(padding_count, "00:");
      time = padding_time + input_time;
    }
    if (input_time.split(":").length > 3) {
      var hours_minutes_seconds = input_time.split(":").slice(-3);
      time = hours_minutes_seconds[0] + ":" + hours_minutes_seconds[1] + ":" + hours_minutes_seconds[2];
    }
  }
  if (time != "") {
    $("#" + input_selector).val(format_time(time));
  }
  else {
    $("#" + input_selector).val(format_time(input_time));
  }
};

function check_both_times_equal(start_time, end_time) {
  if (start_time === end_time) {
    $("#start-time").val(gon.video_start_time);
    $("#end-time").val(gon.video_end_time);
  }
};

function repeat_string(times, original_string) {
  var str = "";
  for (var i = 0; i < times; i++) {
    str += original_string;
  }
  return str;
};

function validate_start_time() {
  update_time_value($("#start-time").val(), gon.video_start_time, 'start-time');
  auto_format_time($("#start-time").val(), "start-time", gon.video_start_time);
  var actual_start_time = user_input_time(gon.video_start_time);
  var actual_end_time = user_input_time(gon.video_end_time);
  var start_time = user_input_time($("#start-time").val());
  var end_time = user_input_time($("#end-time").val());
  if (start_time < actual_start_time || start_time > actual_end_time) {
    $("#start-time").val(gon.video_start_time);
  }
  check_both_times_equal(start_time, end_time);
}

function validate_end_time() {
  update_time_value($("#end-time").val(), gon.video_end_time, 'end-time');
  auto_format_time($("#end-time").val(), "end-time", gon.video_end_time);
  var actual_start_time = user_input_time(gon.video_start_time);
  var actual_end_time = user_input_time(gon.video_end_time);
  var start_time = user_input_time($("#start-time").val());
  var end_time = user_input_time($("#end-time").val());
  if (end_time < actual_start_time || end_time < start_time || end_time > actual_end_time) {
    $("#end-time").val(gon.video_end_time);
  }
  check_both_times_equal(start_time, end_time);
}

function auto_format_input_on_enter(thisRef, key_code) {
  if (key_code === 13) {
    if (thisRef.attr("id") === "start-time") {
      validate_start_time();
    }
    if (thisRef.attr("id") === "end-time") {
      validate_end_time();
    }
  }
}

function get_time_in_hrs_mins_sec(passed_time) {
  time_array = passed_time.split(":");
  if (time_array.length === 2) {
    var hours = 00;
    var minutes = time_array[0];
    var seconds = time_array[1];
  }
  else if (time_array.length === 3) {
    var hours = time_array[0];
    var minutes = time_array[1];
    var seconds = time_array[2];
  }
  return { hours: hours, minutes: minutes, seconds: seconds }
}

function format_time(value) {
  var time = get_time_in_hrs_mins_sec(value);
  var hours = parseInt(time.hours);
  var minutes = parseInt(time.minutes);
  var seconds = parseInt(time.seconds);
  var vhours = (hours > 59) ? 59 : time.hours;
  var vminutes = (minutes > 59) ? 59 : time.minutes;
  var vseconds = (seconds > 59) ? 59 : time.seconds;
  if (value.split(":").length === 2) {
    return vminutes + ":" + vseconds;
  }
  else {
    return vhours + ":" + vminutes + ":" + vseconds;
  }
}

// close conversion inprogress modal
function close_conversion_inprogress_modal() {
  const conversion_time = parseInt($.trim($('.conversion-timer').text()).split(' ')[0]);
  if (
    typeof gon.video_converting_modal_showafter_seconds === 'undefined' ||
    conversion_time == 0 ||
    conversion_time >= gon.video_converting_modal_showafter_seconds
  ) {
    clearTimeout(inprogress_message);
  }
}

function display_video_length_limit_confirmation() {
  $.confirm({
    theme: "material",
    title: "Sorry you don't have access!",
    content: "Guests cannot convert videos longer than " + gon.guest_video_duration_limit_minutes + " minutes.<br><br>"
      + "<a href='https://getaudiofromvideo.com/membership/new'>Click here to become a member</a> and download videos of "
      + "unlimited duration.<br><br>",
    buttons: {
      ok: {
        text: "I understand",
        btnClass: "btn-primary",
        keys: ["enter"],
        action: function () {
        }
      }
    }
  });
}

function show_conversion_inprogress_modal() {
  $.confirm({
    theme: "material",
    title: "Conversion in progress!",
    content: "Your conversion is not frozen, but is processsing.<br><br>"
      + "Depending on the size of your video, it may take a few minutes to convert.<br><br>",
    buttons: {
      ok: {
        text: "I understand",
        btnClass: "btn-primary",
        keys: ["enter"],
        action: function () {
        }
      }
    }
  });
}
