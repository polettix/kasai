use 5.024;
use experimental qw< postderef signatures >;

package Game::HandHeld::Item {
   use Moo;
   no warnings qw< experimental::postderef experimental::signatures >;
   use namespace::autoclean;
   with 'Game::HandHeld::Role::Identifier';
   with 'Game::HandHeld::Role::GamePointer';
   with 'Game::HandHeld::Role::Positional';
   with 'Game::HandHeld::Role::Interactive';
   with 'Game::HandHeld::Role::Tagged';

   sub summary ($self) {
      my $positions = join ', ', $self->positions;
      my $tags = join ', ', $self->tags;
      return sprintf '%s <%s> [%s]', $self->id, $positions, $tags;
   }
} ## end package Game::HandHeld::Item

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Item - class to represent an Item

=head1 DESCRIPTION

This class allows representing an Item. An Item does not have an active
business logic, but can be manipulated by an Interaction.

An Item has.

=over

=item *

an identifier

=item *

a (weak) pointer towards the game containing it

=item *

handlers to manage its presence in one or more positions

=item *

handlers to manage a list of I<interactions> that migth occur to it (it is able
to track Interactions' names, not objects).

=back

=cut
