$(document).on('turbolinks:load', () => {
  // hide monthly price & button by default
  $('#membership-price-monthly').hide();
  $('#membership-signup-button-monthly').hide();

  // toggle showing monthly/annual price & button depending on radio button click
  $("input[name='membership-radio-button']").on('click change', function (e) {
    // console.log(e.type);
    // console.log(this.value);
    if (this.value === 'monthly-radio-button') {
      $('#membership-price-annual').hide();
      $('#membership-price-monthly').show();
      $('#membership-signup-button-annual').hide();
      $('#membership-signup-button-monthly').show();
    } else if (this.value === 'annual-radio-button') {
      $('#membership-price-annual').show();
      $('#membership-price-monthly').hide();
      $('#membership-signup-button-annual').show();
      $('#membership-signup-button-monthly').hide();
    }
  });
});
