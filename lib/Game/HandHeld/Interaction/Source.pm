use 5.024;

package Game::HandHeld::Interaction::Source {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;

   extends 'Game::HandHeld::Interaction';

   sub update ($self, $event) {
      return unless $event eq 'generate';
      my $pf = $self->position_for;
      my ($position) = exists $pf->{default} ? $pf->{default}
         : map {$pf->{$_}} sort {$a cmp $b} keys $pf->%*;
      $self->game->add_item(
         GnW::Item->new(
            position => $position,
            locked   => 0,
            direction_for => {
               advance => {
                  default => 'default',
                  catch   => 'alternative',
               },
            },
         )
      );
      return;
   }
}

1;
__END__
