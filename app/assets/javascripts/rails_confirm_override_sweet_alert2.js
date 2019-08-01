allowAction = function(link) {
  if (!link.attr('data-message')) {
    return true;
  }
  showConfirmDialog(link);
};

confirmed = function(link) {
  link.removeAttr('data-message');
};

performAction = function(link) {
  if(link.hasClass('sweet-alert-from')) {
    link[0].submit();
  }
  else {
    link.attr('href', link.attr('data-link'));
    link[0].click()
  }
}

showConfirmDialog = function(link) {
  var swalOptions = {
    title: 'Are you sure?',
    type: 'warning',
    showCancelButton: true,
    confirmButtonText: "Ok",
    cancelButtonText: "Cancel",
    confirmButtonColor: "#3085d6",
    cancelButtonColor: "#aaa"
  }
  if (typeof sweetAlertConfirmConfig != 'undefined') {
    $.each(sweetAlertConfirmConfig, function(key, val) {
      swalOptions[key] = val;
    });
  }
  var optionKeys = [
    'text',
    'showCancelButton',
    'confirmButtonColor',
    'cancelButtonColor',
    'confirmButtonText',
    'cancelButtonText',
    'html',
    'imageUrl',
    'allowOutsideClick',
    'customClass'
  ];
  $.each(link.data(), function(key, val) {
    if ($.inArray(key, optionKeys) >= 0) {
      swalOptions[key] = val;
    }
    if ( key == "message" ) {
      swalOptions['title'] = val;
    }
  });
  var message = link.attr('data-message');
  confirmed(link);
  return swal(swalOptions).then(function(result) {
    if (result.value) {
      performAction(link);
    } else if (result.dismiss === 'cancel') {
      link.attr('data-message', message);
    }
  });
};
