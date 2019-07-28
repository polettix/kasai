use 5.024;

package Game::HandHeld::Item {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Log::Any '$log';

   has id            => (is => 'ro', default => sub ($s) { refaddr($s) });
   has direction_for => (is => 'ro', default => sub { return {} });
   has game          => (is => 'rw', weak_ref => 1, default => undef);
   has _positions    => (is => 'ro', default => sub { return {} });
   has _interactions => (is => 'ro', default => sub { return {} });

   sub BUILD ($self, $args) {
      my $positions = defined($args->{position}) ? [$args->{position}]
         : defined($args->{positions}) ? $args->{positions}
         : [];
      ouch 400, 'invalid positions as input to item'
         unless ref $positions eq 'ARRAY';
      my $screen = $self->game->screen;
      $self->move_into(
         map {
            blessed($_) ? $_
               : blessed($screen) ? $screen->get_position($_)
               : ouch 400, 'cannot resolve position without screen';
         } $positions->@*
      );
      return;
   }

   sub update ($self, $event) { # default implementation
      my $df = $self->direction_for->{$event}
         or return $self; # skip if not handling this $event

      my @interactions = keys $self->_interactions->%*;
      @interactions = ('default') unless @interactions;
      for my $position ($self->positions) {
         INTERACTION:
         for my $interaction (@interactions) {
            next INTERACTION unless exists $df->{$interaction};
            my $direction = $df->{$interaction};
            $self->leave($position);
            $self->register_into($position->neighbor_towards($direction));
            last INTERACTION; # left the $position, move on
         }
      }

      # whatever happened, any interaction is cleared for next round
      $self->_interactions->%* = ();
      return $self;
   }

   sub positions ($self) { return values $self->_positions->%* }

   sub register_into ($self, @positions) {
      my $pf = $self->_positions;
      for my $p (@positions) {
         $pf->{$p->id} = $p;
         $p->register($self);
      }
      return $self;
   }

   sub leave ($self, @positions) {
      my $pf = $self->_positions;
      for my $p (@positions) {
         $p->release($self);
         delete $pf->{$p->id};
      }
      return $self;
   }

   sub move_into ($self, $position) { # facility for one-position items
      $self->leave($self->positions);
      $self->register_into($position);
      return $self;
   }

   sub record_interaction ($self, $interaction) {
      $self->_interactions->{$interaction} = 1;
      return $self;
   }

   sub has_interaction ($self, $interaction) {
      return $self->_interactions->{$interaction} // 0;
   }
}

1;
__END__
