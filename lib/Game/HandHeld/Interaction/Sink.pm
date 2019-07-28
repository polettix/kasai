use 5.024;

package Game::HandHeld::Interaction::Sink {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   sub update ($self, $event) {
      my $game = $self->game;
      my @dels;
      my $pf = $self->position_for;
      while (my ($counter, $position) = each $self->position_for->%*) {
         for my $item ($position->guests) {
            $item->leave($position);
            $game->increase($counter);
            $log->debug("increased $counter: " . $game->total($counter));
            push @dels, $item;
         }
      }
      $game->remove_item($_) for @dels; # might happen multiple times
      return;
   }
}

1;
__END__
