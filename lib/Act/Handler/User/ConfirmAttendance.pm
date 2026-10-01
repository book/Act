package Act::Handler::User::ConfirmAttendance;
use strict;
use parent 'Act::Handler';

use Act::Config;
use Act::Form;
use Act::Template::HTML;
use Act::Order;
use Act::User;

my $form = Act::Form->new(
    required => [ qw(order_id) ]
);
sub handler
{
   unless ($Request{user}->is_users_admin ) {
      $Request{status} = 404;
      return;
   }
   my $template = Act::Template::HTML->new();
   my $fields = {};

   if ($Request{args}{ok}) {
      # form has been submitted
      my $ok = $form->validate($Request{args});
      $fields = $form->{fields};
      my @errors;
      if ($ok) {
         # find the order
         my $order = Act::Order->new(
            order_id => $Request{args}{order_id},
            conf_id  => $Request{conference},
         );
         if ($order) {
            my $user = Act::User->new(user_id => $order->user_id);
            # make sure user is registered for this conference
            if ($user->has_registered) {
               # mark user as attending this conference
               $user->update(participation => { attended => 1 });
               # clear form fields for next user
               $fields = {};
               # show user
               $template->variables(user => $user);
            }
            else {
               push @errors, 'ERR_NOT_REGISTERED';
            }
         }
         else {
            push @errors, 'ERR_UNKNOWN_ORDER_ID';
         }
         $template->variables(errors => \@errors);
      }
      else {
         $form->{invalid}{order_id} && push @errors, 'ERR_MISSING_ORDER_ID';
      }
   }
   # display form
   $template->variables(
      %$fields,
   );
   $template->process('user/confirm_attendance');
   return;
}

1;
