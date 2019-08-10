use 5.024;

package Game::HandHeld::Interaction::Skipper {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Module::Runtime 'use_module';
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   has skip_events => (is => 'ro', default  => 1);
   has _remaining  => (is => 'rw', init_arg => undef, default => 0);
   has _step_event => (is => 'rw', init_arg => undef, default => undef);

   sub activate ($self, $event) {
      $self->_remaining($self->skip_events);
      $self->_step_event($event);
      return;
   }

   sub update ($self, $event) {
      my $remaining = $self->_remaining or return;
      return 'break' if $self->_step_event ne $event;
      $self->_remaining(--$remaining);    # decrease skips count
      return 'break' if $remaining;
      $self->_step_event(undef);
      return;
   } ## end sub update
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Interaction::Pauser - pause for some events

=head1 DESCRIPTION

This interaction encapsulates pausing for some events.

=cut
