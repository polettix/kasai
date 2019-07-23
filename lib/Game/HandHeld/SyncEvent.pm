use 5.024;

package Game::HandHeld::SyncEvent {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;

   use constant DEFAULT_PERIOD => 25;
   use constant DEFAULT_NAME   => 'tock';

   has min_tick => (is => 'rw', default => 0);
   has max_tick => (is => 'rw', default => -1);
   has offset   => (is => 'rw', default => 0);
   has period   => (is => 'rw', default => DEFAULT_PERIOD);
   has name     => (is => 'rw', default => DEFAULT_NAME);

   sub tick ($self, $n) {
      my ($min_tick, $max_tick) = ($self->min_tick, $self->max_tick);
      return if $n < $min_tick;
      return if ($max_tick >= 0) && ($n > $max_tick);
      $n = ($n - $min_tick) % $self->period;
      return unless $n == $self->offset;
      return $self->name;
   }
}

1;
__END__
