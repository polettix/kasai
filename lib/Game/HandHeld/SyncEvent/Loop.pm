use 5.024;

package Game::HandHeld::SyncEvent::Loop {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use namespace::autoclean;

   extends 'Game::HandHeld::SyncEvent';

   has _current => (is => 'lazy', clearer => 1, init_arg => undef);
   has _sequence => (is => 'ro', init_arg => 'sequence', required => 1);
   has _index    => (is => 'rw', init_arg => undef,      default  => 0);

   sub _build__current ($self) { return [$self->_sequence->@*] }

   sub reset ($self) {
      $self->_current->clear;
      $self->_index(0);
      return $self;
   }

   sub tick ($self, $n) {
      my $current = $self->_current;
      my $N = $current->@*;
      my $speed = $self->speed;
      my $speed_prefix = quotemeta $self->speed_prefix;
      my $index = $self->_index % $N;
      my $retval = $current->[$index];
      while ($retval =~ m{\A $speed_prefix (\d+) \z}mxs) {
         last if $1 >= $speed;
         $index = ($index + 1) % $N;
         $retval = $current->[$index];
      }
      $self->_index(($index + 1) % $N);
      return $retval;
   }
} ## end package Game::HandHeld::SyncEvent::Loop

1;
__END__
