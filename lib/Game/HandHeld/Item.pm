use 5.024;

package GnW::Item {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;

   has id            => (is => 'ro', default => sub ($s) { refaddr($s) });
   has direction_for => (is => 'ro', default => sub { return {} });
   has game          => (is => 'rw', weak_ref => 1, default => undef);
   has _positions    => (is => 'ro', default => sub { return {} });
   has _interactions => (is => 'ro', default => sub { return {} });

   around BUILDARGS => sub ($orig, $class, @args) {
      my %args = @args && (ref $args[0] eq 'HASH') ? $args[0]->%* : @args;
      if (my $positions = delete $args{positions}) {
         ouch 400, 'invalid positions as input to item'
            unless ref $positions eq 'ARRAY';
         my $screen = $args{field} // undef;
         my %position_for;
         for my $p ($positions->@*) {
            my $position = blessed($p) ? $p
               : blessed($screen) ? $screen->get_position($p)
               : ouch 400, 'cannot resolve position by name without screen';
            $position_for{$position->id} = $position;
         }
         $args{_positions} = \%position_for;
      }

      return $class->$orig(%args);
   };

   sub update ($self, $event) { # default implementation
      my $df = $self->direction_for->{$event}
         or return $self; # skip if not handling this $event

      my @interactions = values $self->_interactions->%*;
      @interactions = ('default') unless @interactions;
      for my $position ($self->positions) {
         INTERACTION:
         for my $interaction (@interactions) {
            next INTERACTION unless exists $df->{$interaction};
            my $direction = $df->{$interaction};
            $self->leave($position);
            $self->register_into($position->successor_for($direction));
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
      $pf->{$_->id} = $_ for @positions;
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

   sub record_interaction($self, $interaction) {
      $self->_interactions->{$interaction} = 1;
      return $self;
   }
}

1;
__END__
