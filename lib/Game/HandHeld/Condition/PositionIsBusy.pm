use 5.024;

package Game::HandHeld::Condition::PositionIsBusy {
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';

   sub new ($class, @args) {
      my %args = @args && ref $args[0] ? $args[0]->%* : @args;
      my $positions =
        defined $args{position} ? [$args{position}] : $args{positions};
      ouch 'missing-positions', 'missing positions to check'
        unless defined $positions && $positions->@*;
      return sub ($interaction, $event) {
         my $game = $interaction->game;
         for my $pos_id ($positions->@*) {
            return 1 if $game->position($pos_id)->is_busy;
         }
         return 0;
      };
   } ## end sub new
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Condition::PositionIsBusy - check if position(s) is busy

=head1 DESCRIPTION

This interaction encapsulates checking the condition that one or more
positions are busy.

=cut
