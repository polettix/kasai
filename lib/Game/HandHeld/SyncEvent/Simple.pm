use 5.024;

package Game::HandHeld::SyncEvent::Simple {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use namespace::autoclean;

   extends 'Game::HandHeld::SyncEvent';

   has min_tick => (is => 'rw', default  => 0);
   has max_tick => (is => 'rw', default  => -1);
   has name     => (is => 'rw', required => 1);
   has offset   => (is => 'rw', default  => 0);
   has period   => (is => 'rw', required => 1);

   sub tick ($self, $n) {
      my ($min_tick, $max_tick) = ($self->min_tick, $self->max_tick);
      return if $n < $min_tick;
      return if ($max_tick >= 0) && ($n > $max_tick);
      $n = ($n - $min_tick) % $self->period;
      return unless $n == $self->offset;
      return $self->name;
   } ## end sub tick
} ## end package Game::HandHeld::SyncEvent::Simple

1;
__END__
