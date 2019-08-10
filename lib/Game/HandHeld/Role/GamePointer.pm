use 5.024;

package Game::HandHeld::Role::GamePointer {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util 'blessed';
   use namespace::clean;

   has game => (
      is  => 'rw',
      isa => sub ($x) {
         ouch 'not-a-game', "invalid 'game' provided"
           unless blessed($x) && $x->isa('Game::HandHeld');
      },
      weak_ref => 1,
   );

   sub screen ($self) {
      my $game = $self->game or ouch 'no-game', "no 'game' defined";
      return $game->screen;
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::GamePointer - role for a class that points to ::HandHeld

=head1 DESCRIPTION

This is a I<base> role for all classes that hold a pointer to the main
game.

=cut
