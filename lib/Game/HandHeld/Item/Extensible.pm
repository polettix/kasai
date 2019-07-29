use 5.024;

package Game::HandHeld::Item::Extensible {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Game::HandHeld::Counter;

   extends 'Game::HandHeld::Item';

   has counter => (is => 'rw', default => 'miss');
   has '+_positions' => (is => 'rw', default => sub { [] });

   around BUILD => sub ($orig, $self, $args) {
      my $positions = defined($args->{position}) ? [$args->{position}]
         : defined($args->{positions}) ? $args->{positions}
         : [];
      ouch 400, 'invalid positions as input to item'
         unless ref $positions eq 'ARRAY';
      my $screen = $self->game->screen;
      my @positions = map {
         blessed($_) ? $_
            : blessed($screen) ? $screen->get_position($_)
            : ouch 400, 'cannot resolve position without screen';
      } $positions->@*;
      $self->_positions(\@positions);
      $self->_refresh_positions;
      return;
   };

   sub length ($s) { return $s->game->total($s->counter) }

   sub positions ($self) { $self->_positions->@[0 .. $self->length - 1] }

   sub update ($self, $event) { return $self }

   sub _refresh_positions ($self) {
      my $n = $self->length;
      my $ps = $self->_positions;
      for my $i (0 .. $#$ps) {
         if ($i < $n) { $ps->[$i]->register($self) }
         else         { $ps->[$i]->release($self) }
      }
      return $self;
   }

   sub record_interaction ($s, $interaction) { $s->_refresh_positions }
}

1;
__END__
