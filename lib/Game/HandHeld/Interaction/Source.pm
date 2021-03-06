use 5.024;

package Game::HandHeld::Interaction::Source {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Game::HandHeld::Item;

   extends 'Game::HandHeld::Interaction';

   has roster => (is => 'ro', required => 1);
   has index => (is => 'rwp', init_arg => undef, default => 0);
   has _current => (
      is       => 'lazy',
      init_arg => undef,
      clearer  => 1,
   );

   sub _build__current ($s) { return {$s->roster->[$s->index]->%*} }

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
      if (($current->{skip} // 0) > 0) {
         $current->{skip}--;
         return;
      }
      my $specs = $current->{items};
      $specs = [$current->{item}] if exists $current->{item};
      $self->game->add_items($specs->@*);
      $self->_set_index(($self->index + 1) % ($self->roster->@*));
      $self->_clear_current;
      return;
   } ## end sub update
} ## end package Game::HandHeld::Interaction::Source

1;
__END__
