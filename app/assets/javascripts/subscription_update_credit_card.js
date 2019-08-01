$(document).on("turbolinks:load", function() {

  $('#updateCard').on('shown.bs.modal', function() {
    $('#myInput').focus()
  });

  var PayolaSubscriptionUpdateCreditCard = {
    initialize: function() {
      $(document).off('click.payola-subscription-update-credit-card-button').on(
        'click.payola-subscription-update-credit-card-button', '.payola-subscription-update-credit-card-button',
        function(e) {
          e.preventDefault();
          PayolaSubscriptionUpdateCreditCard.handleCheckoutButtonClick($(this));
        }
      );
    },

    handleCheckoutButtonClick: function(button) {
      var form = button.parent('form');
      var options = form.data();

      // Open a Stripe Checkout to collect the customer's billing details
      var handler = StripeCheckout.configure({
        key: options.publishable_key,
        token: function(token) {
          PayolaSubscriptionUpdateCreditCard.tokenHandler(token, options);
        },
        name: options.name,
        panelLabel: options.panel_label,
        allowRememberMe: options.allow_remember_me,
        zipCode: options.verify_zip_code,
        email: options.email || undefined,
      });

      handler.open();
    },

    tokenHandler: function(token, options) {
      var guid = (options.guid);
      var form = $("#" + options.form_id);
      form.append($('<input type="hidden" name="stripeToken">').val(token.id));
      form.append($('<input type="hidden" name="stripeEmail">').val(token.email));
      if (options.signed_custom_fields) {
        form.append($('<input type="hidden" name="signed_custom_fields">').val(options.signed_custom_fields));
      }
      PayolaSubscriptionUpdateCreditCard.submitForm(form.attr('action'), form.serialize(), options, guid);
    },

    submitForm: function(url, data, options, guid) {
      $(".payola-subscription-update-credit-card-button").prop("disabled", true);
      $(".payola-subscription-checkout-button-text").hide();
      $(".payola-subscription-checkout-button-spinner").show();
      $.ajax({
        type: "POST",
        url: options.base_path + "/update_card/" + guid,
        data: data,
        success: function(data) {
          PayolaSubscriptionUpdateCreditCard.poll(data.guid, 60, options);
        },
        error: function(data) {
          PayolaSubscriptionUpdateCreditCard.showError(jQuery.parseJSON(data.responseText).error, options);
        }
      });
    },

    showError: function(error, options) {
      var error_div = $("#" + options.error_div_id);
      error_div.html(error);
      error_div.show();
      $(".payola-subscription-update-credit-card-button").prop("disabled", false)
        .trigger("error", error);
      $(".payola-subscription-checkout-button-spinner").hide();
      $(".payola-subscription-checkout-button-text").show();
    },

    poll: function(guid, num_retries_left, options) {
      if (num_retries_left === 0) {
        PayolaSubscriptionUpdateCreditCard.showError("This seems to be taking too long. Please contact support and give them transaction ID: " + guid, options);
        return;
      }

      var handler = function(data) {
        if (data.status === "active") {
          window.location = options.base_path + guid;
        } else if (data.status === "errored") {
          PayolaSubscriptionUpdateCreditCard.showError(data.error, options);
        } else {
          setTimeout(function() {
            PayolaSubscriptionUpdateCreditCard.poll(guid, num_retries_left - 1, options);
          }, 500);
        }
      };
    }

  };

  PayolaSubscriptionUpdateCreditCard.initialize();
});
