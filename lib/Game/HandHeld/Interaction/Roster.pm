use 5.024;

package Game::HandHeld::Interaction::Roster {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';

   extends 'Game::HandHeld::Interaction';

   has roster => (is => 'ro', required => 1);
   has grace_period => (is => 'ro', default => 0);
   has monitor_counter => (is => 'ro', default => undef);
   has index => (is => 'rwp', init_arg => undef, default => 0);
   has _current => (
      is       => 'lazy',
      init_arg => undef,
      clearer  => 1,
   );

   sub _build__current ($self) {
      my $index   = $self->index;
      my $current = $self->roster->[$index];
      if (!ref $current) {    # parse and cache, on the fly
         my ($event, $skip, $position) = split m{\s+}mxs, $current;
         $current = $self->roster->[$index] = {
            event => $event,
            skip  => $skip,
         };
         $current->{positions} = [$position] if defined $position;
      } ## end if (!ref $current)
      $current->{positions} = [delete $current->{position}]
         if exists $current->{position};
      $current->{item} = {
         tags => [$current->{event}],
         positions => delete($current->{positions}),
      } if exists $current->{positions};
      return {$current->%*};
   } ## end sub _build__current ($self)

   sub _match_event ($self, $event, $models) {
      $models = [$models] unless ref $models eq 'ARRAY';
      for my $model ($models->@*) {
         if (ref $model eq 'RegExp') {
            return 1 if $event =~ m{$model};
         }
         elsif (!ref $model) {
            return 1 if $event eq $model;
         }
         else {
            ouch 'invalid-model', 'invalid model for matching event';
         }
      } ## end for my $model ($models->...)
   } ## end sub _match_event

   sub update ($self, $event) {
      my $current = $self->_current;
      return unless $self->_match_event($event, $current->{event});
      my $game = $self->game;
      if (($current->{skip} //= 0) > 0) {
         $current->{skip}--;
         $current->{skipped}++;

         if (defined(my $counter = $self->monitor_counter)) {
            my $grace = $self->grace_period;
            $current->{skip} = 0
               if !$game->total($counter) && $current->{skipped} >= $grace;
         }
      }
      return if $current->{skip};
      my $specs = $current->{items} // [];
      $specs = [$current->{item}] if exists $current->{item};
      $game->add_items($specs->@*);
      $game->increase_speed($current->{speed_change}) if $current->{speed_change};
      $self->_set_index(($self->index + 1) % ($self->roster->@*));
      $self->_clear_current;
      return;
   } ## end sub update
} ## end package Game::HandHeld::Interaction::Roster

1;
__END__
