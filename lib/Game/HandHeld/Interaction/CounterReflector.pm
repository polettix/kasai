use 5.024;

package Game::HandHeld::Interaction::CounterReflector {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   has counter => (is => 'ro', required => 1);
   has _positions => (
      is       => 'ro',
      init_arg => 'positions',
      coerce   => sub ($x) { [$x->@*] },
      required => 1,
   );
   has item => (
      is      => 'ro',
      default => sub ($self) { $self->game->item({})->id },
   );

   sub _item ($self) { return $self->game->item($self->item, auto => 1) }

   sub positions ($self) { return $self->_positions->@* }

   sub update ($self, $event) {
      my $game  = $self->game;
      my $value = $game->total($self->counter);
      my $item  = $self->_item;
      for my $pos_id ($self->positions) {
         my $is_present = $item->has_position($pos_id);
         if ($value > 0 && !$is_present) { $item->register_into($pos_id) }
         elsif ($value <= 0 && $is_present) { $item->leave($pos_id) }
         --$value;
      } ## end for my $pos_id ($self->...)
      return;
   } ## end sub update
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Interaction::Router - encapsulate moving of items

=head1 DESCRIPTION

This interaction encapsulates the movement of items.

It holds one item and it makes sure it advances when the right event
arrives, checking its current position and finding out the next one.

=cut
