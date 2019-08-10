use 5.024;

package Game::HandHeld::Interaction::Mover {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   has by_event     => (is => 'ro', default => 0);
   has cleans_items => (is => 'ro', default => 1);

   # this is either a HoH or a HoHoH depending on by_event above. In the
   # latter case, the event is used as an entry point (first "H"), then
   # the following key is the position id, then the interaction

   has next_hop_for => (
      is       => 'ro',
      required => 1,
      isa      => sub ($x) {
         ouch 'invalid-next_hop_for', "'next_hop_for' must be a hashref"
           unless ref $x eq 'HASH';
      },
   );

   has selector => (
      is      => 'ro',
      default => sub { return [] },
      coerce  => sub ($x) {
         ouch 'undefined-selector', 'undefined selector'
           unless defined $x;
         $x = [$x] unless ref $x;
         ouch 'invalid-selector', 'invalid selector, must be array'
           unless ref $x eq 'ARRAY';
         return $x;
      },
   );

   sub _selector ($self, $event) {
      my @selector;
      for my $s ($self->selector->@*) {
         my $sref = ref $s;
         if (!$sref) { push @selector, $s }
         elsif ($sref eq 'ARRAY') {
            my ($cmd, @args) = $s->@*;
            if ($cmd eq 'event') {
               push @selector, $event;
            }
            else {
               ouch 'invalid-selector', "invalid selection cmd '$cmd'";
            }
         } ## end elsif ($sref eq 'ARRAY')
         else {
            ouch 'invalid-selector', "invalid selector ref $sref";
         }
      } ## end for my $s ($self->selector...)
      return \@selector;
   } ## end sub _selector

   sub update ($self, $event) {
      my $nhf = $self->next_hop_for;
      $nhf = $nhf->{$event} if $self->by_event;
      ouch 'undefined-next_hop_for',
        "event '$event' has no next_hop_for definition"
        unless defined $nhf;
      my $game = $self->game;
      for my $item ($game->items(tags => $self->_selector($event))) {
         my $item_id = $item->id;
         my @new_pos;
         for my $pos_id ($item->positions) {

            # we don't complain if there is not a "next hop" for some
            # position, it might just mean that there is no movement
            # from *that* position.
            next unless exists $nhf->{$pos_id};

            # "undef" next hop means just leaving this position for good
            my $next_hop = $nhf->{$pos_id} // [];
            push @new_pos, ref $next_hop ? $next_hop->@* : $next_hop;

            $item->leave($pos_id);
         } ## end for my $pos_id ($item->...)

         # after leaving all old positions we can join new ones. This
         # allows overlapping between the two sets.
         $item->register_into(@new_pos);

         # get rid of items without a position if asked to do so
         $game->remove_items($item_id)
           if !$item->positions && $self->cleans_items;
      } ## end for my $item ($game->items...)
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
