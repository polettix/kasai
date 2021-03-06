use 5.024;

package Game::HandHeld::SyncEvent {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use namespace::autoclean;

   has speed => (is => 'rw', default => 0);
   has speed_prefix => (is => 'rw', default => '');

   sub tick ($self, $n) { ouch 'abstract-class', 'override this class' }
} ## end package Game::HandHeld::SyncEvent

1;
__END__
