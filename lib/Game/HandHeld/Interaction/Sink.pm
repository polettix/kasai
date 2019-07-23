use 5.024;

package Game::HandHeld::Interaction::Sink {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;

   extends 'Game::HandHeld::Interaction';

   sub update ($self, $event) {
      my $game = $self->game;
      while (my ($counter, $position) = each $self->position_for->%*) {
         for my $item ($position->guests) {
            $item->leave($position);
            $game->increase($counter);
            $game->remove_item($item); # might happen multiple times
         }
      }
      return;
   }
}

1;
__END__
