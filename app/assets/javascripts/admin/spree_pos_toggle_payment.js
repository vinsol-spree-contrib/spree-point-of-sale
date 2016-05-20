$( document ).ready(function() {
  $('#sku').focus();
  $( "#pos-tabs" ).tabs();

  $( "#associate_user_toggle" ).click(function() {
    $( "#associate_user" ).slideToggle( "slow", function() {
    });
  });

  $('#update_payment input[type=radio]').click(function() {
    $('#card_name_options').val('');
    $('#card_name_options').hide();
  });

  $('#update_payment input[type=radio][data-name ~= card],#update_payment input[type=radio][data-name ~= Card]').click(function() {
    $('#card_name_options').show();
  });
  $("#update_payment input[name='payment_method_id']:first").click();
  $( "#associate_user" ).toggle();
});
