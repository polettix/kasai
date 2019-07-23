use 5.024;

package Game::HandHeld::Interaction::Sink {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;

   extends 'Game::HandHeld::Interaction';

   sub update ($self, $event) {
      my $game = $self->game;
      my @dels;
      while (my ($counter, $position) = each $self->position_for->%*) {
         for my $item ($position->guests) {
            $item->leave($position);
            $game->increase($counter);
            push @dels, $item;
         }
      }
      $game->remove_item($_) for @dels; # might happen multiple times
      return;
   }
}

1;
__END__
