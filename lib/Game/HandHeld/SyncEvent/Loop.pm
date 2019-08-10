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
      $self->_index((my $index = $self->_index % $current->@*) + 1);
      return $current->[$index];
   }
} ## end package Game::HandHeld::SyncEvent::Loop

1;
__END__
