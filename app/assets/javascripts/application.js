// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require payola
//= require turbolinks
//= require_tree .

$(document).on("turbolinks:load", function () {
  // Google analytics
  window.dataLayer = window.dataLayer || [];
  function gtag() {
    dataLayer.push(arguments);
  }
  gtag('js', new Date());
  gtag('config', 'UA-8374148-1');

  // Heap Analytics
  window.heap = window.heap || [], heap.load = function (e, t) { window.heap.appid = e, window.heap.config = t = t || {}; var r = t.forceSSL || "https:" === document.location.protocol, a = document.createElement("script"); a.type = "text/javascript", a.async = !0, a.src = (r ? "https:" : "http:") + "//cdn.heapanalytics.com/js/heap-" + e + ".js"; var n = document.getElementsByTagName("script")[0]; n.parentNode.insertBefore(a, n); for (var o = function (e) { return function () { heap.push([e].concat(Array.prototype.slice.call(arguments, 0))) } }, p = ["addEventProperties", "addUserProperties", "clearEventProperties", "identify", "resetIdentity", "removeEventProperty", "setEventProperties", "track", "unsetEventProperty"], c = 0; c < p.length; c++)heap[p[c]] = o(p[c]) };
  heap.load("1822874423");

  // login/signup bootstrap 4 modals
  $('#loginModalCenter, #signupModalCenter, #forgotPasswordModal, #resendConfirmModal').on('shown.bs.modal', function () {
    $(this).before($('.modal-backdrop'));
    $(this).css("z-index", parseInt($('.modal-backdrop').css('z-index')) + 1);
    $('#member_email').focus();
  });

  $('#forgotPasswordModal, #resendConfirmModal, #signupModalCenter').on('shown.bs.modal', function () {
    $('#loginModalCenter').modal('hide');
  });

  $('#loginModalCenter').on('shown.bs.modal', function () {
    $('#signupModalCenter').modal('hide');
  });

  // enable bootstrap 4 tooltips
  $(function () {
    $('[data-toggle="tooltip"]').tooltip();
  });

  // remove #_=_ added to URL by facebook omniauth
  (function () {
    "use strict";
    if (window.location && window.location.hash) {
      if (window.location.hash === '#_=_') {
        window.location.hash = '';
        return;
      }
      const facebookFubarLoginHash = RegExp('_=_', 'g');
      window.location.hash = window.location.hash.replace(facebookFubarLoginHash, '');
    }
  })();

  // display sweet alert for javascript confirmation alert
  $(".sweet-alert").click(function (event) {
    allowAction($(this));
  });

  $(".sweet-alert-from").submit(function (event) {
    event.preventDefault(event);
    allowAction($(this));
  });

});
