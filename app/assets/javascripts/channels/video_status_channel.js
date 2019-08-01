function displayVideoStatus(video_id, identifier) {
  const status = App.cable.subscriptions.create(
    {
      channel: 'VideoStatusChannel',
      video_id,
      session_identifier: identifier,
    },
    {
      connected() {
        console.log('connected');
      },
      disconnected() {
        console.log('disconnected');
      },
      received(data) {
        // update conversion form state if conversion retry is performed
        if (data.retries <= data.proxy_retry_limit && data.percentage == 0) {
          // change progress bar state
          change_progress_bar_converting();

          // disable the conversion options
          disable_conversion_options();

          // reset conversion time to 0 seconds
          reset_conversion_time_0();

          // restart the conversion timer
          restart_conversion_timer();
        }

        if (!$('#conversion-card').is(':visible')) {
          reset_conversion_card_proxy_retry();
        }

        $('#conversion-status-text').html(data.conversion_status);
        update_percentage(data.percentage);

        // Conversion failed
        if (data.percentage == 0) {
          close_conversion_inprogress_modal();
          hide_timers();
          if (data.retries > data.proxy_retry_limit) {
            enable_conversion_options();
            // stop & reset conversion timer
            $('.conversion-timer')
              .stopwatch()
              .stopwatch('stop');
            $('.conversion-timer')
              .stopwatch()
              .stopwatch('reset');
            // hide the spinner
            $("#conversion-timer-spinner").hide();
          }
        }

        // Conversion successful
        if (data.percentage == 100) {
          if (data.converted_video_id != undefined) {
            const download_link = `/videos/download?converted_video_id=${data.converted_video_id}`;
            $('#download-file-button').attr('href', download_link);
          }
          close_conversion_inprogress_modal();
          change_progress_bar_completed();
          enable_conversion_options();
          hide_timers();
          $('#download-file-button').removeClass('disabled');
          // stop & reset conversion timer
          $('.conversion-timer')
            .stopwatch()
            .stopwatch('stop');
          $('.conversion-timer')
            .stopwatch()
            .stopwatch('reset');
          // hide the spinner
          $("#conversion-timer-spinner").hide();

          const conversion_time = parseInt($.trim($('.conversion-timer').text()).split(' ')[0]);
          if (conversion_time <= gon.video_converting_modal_showafter_seconds) {
            clearTimeout(inprogress_message);
          }
        }
        // Successfull conversion
        if (data.status_code == 9) {
          close_conversion_inprogress_modal();
        }
        // Conversion failed due to exception or proxy error
        if (data.status_code == 11) {
          close_conversion_inprogress_modal();
          hide_conversion_card_and_guest_delay();
          enable_conversion_options();
        }
        // Conversion failed due to video being blocked
        if (data.status_code == 12) {
          close_conversion_inprogress_modal();
          hide_conversion_card_and_guest_delay();
        }

        $('.justify-content-end').html(data.display_flash_message);
      },
    }
  );
}

// Update conversion progess bar
function update_percentage(percentage) {
  $('.progress-bar')
    .width(`${percentage}%`)
    .attr('aria-valuenow', percentage);
  $('.progress-bar').html(`${percentage}%`);
}
