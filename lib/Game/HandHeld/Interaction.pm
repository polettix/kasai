use 5.024;

package Game::HandHeld::Interaction {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util 'blessed';
   use Log::Any '$log';

   has game => (is => 'rw', weak_ref => 1, default => undef);
   has name => (is => 'rw', default => 'bump');
   has position_for => (is => 'ro');

   around BUILDARGS => sub ($orig, $class, @args) {
      my %args = @args && (ref $args[0] eq 'HASH') ? $args[0]->%* : @args;

      my $pf = $args{position_for} //= {};
      my $screen;
      for my $p (values $pf->%*) {
         next if blessed($p); # good to go
         $screen //= $args{game}->screen
            or ouch 400, 'cannot resolve position by name without screen';
         $p = $screen->get_position($p); # substitute name with object
      }

      return $class->$orig(%args);
   };

   sub update ($self, $event) { # default implementation
      my ($cpos, $tpos) = $self->position_for->@{qw< catcher target >};
      my ($target) = $tpos->guests or return;
      my ($catcher) = $cpos->guests or return;
      my $name = $self->name;
      if (! grep { $_->has_interaction($name) } ($target, $catcher)) {

         # Update counters before recording interactions, so that items
         # can see the updated value in case
         $self->game->increase($name);
         $_->record_interaction($name) for ($target, $catcher);
      }
      return;
   }
}

1;
__END__
