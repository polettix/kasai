use 5.024;

package GnW::Interaction {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';

   has game => (is => 'rw', weak_ref => 1, default => undef);
   has name => (is => 'rw', default => 'bump');
   has position_for => (is => 'ro');

   around BUILDARGS => sub ($orig, $class, @args) {
      my %args = @args && (ref $args[0] eq 'HASH') ? $args[0]->%* : @args;

      my $pf = $args{position_for} //= {};
      my $screen = $args{field} // undef;
      for my $p (values $pf->%*) {
         next if blessed($p); # good to go
         ouch 400, 'cannot resolve position by name without screen'
            unless blessed($screen);
         $p = $screen->get_position($p); # substitute name with object
      }

      return $class->$orig(%args);
   };

   sub update ($self, $event) { # default implementation
      my ($cpos, $tpos) = $self->position_for->@{qw< catcher target >};
      my ($target) = $tpos->current or return;
      my ($catcher) = $cpos->current or return;
      $_->record_interaction($self->name) for ($target, $catcher);
      $self->game->increase($self->name);
      return;
   }
}

1;
__END__
