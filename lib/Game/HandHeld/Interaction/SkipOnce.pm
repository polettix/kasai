use 5.024;

package Game::HandHeld::Interaction::SkipOnce {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Module::Runtime 'use_module';
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   has _active => (is => 'rw', default => 0);

   sub activate ($self, $event) {
      $self->_active(1);
      return;
   }

   sub update ($self, $event) {
      return unless $self->_active;
      $self->_active(0);
      return 'break';
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Interaction::Pauser - pause for some events

=head1 DESCRIPTION

This interaction encapsulates pausing for some events.

=cut
