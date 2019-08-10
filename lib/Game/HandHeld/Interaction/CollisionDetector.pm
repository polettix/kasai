use 5.024;

package Game::HandHeld::Interaction::CollisionDetector {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';

   # this is a AoH
   has triggers => (
      is       => 'ro',
      required => 1,
      coerce   => sub ($x) {
         ouch 'invalid-triggers', "'triggers' must be an arrayref"
           unless ref $x eq 'ARRAY';
         my @triggers;
         for my $trigger ($x->@*) {
            ouch 'invalid-trigger', "all triggers must be hashes"
              unless ref $trigger eq 'HASH';
            my %trigger = $trigger->%*;

            ouch 'invalid-trigger', "missing next_hop_for in trigger"
              unless defined $trigger{next_hop_for};
            ouch 'invalid-trigger',
              "next_hop_for in trigger must be a hash"
              unless ref $trigger{next_hop_for} eq 'HASH';

            $trigger{counters} = [delete $trigger{counter}]
              if defined $trigger{counter};
            ouch 'invalid-trigger',
              "interactions in trigger must be in array"
              if defined $trigger{counters}
              && ref $trigger{counters} ne 'ARRAY';

            push @triggers, \%trigger;
         } ## end for my $trigger ($x->@*)
         return \@triggers;
      },
   );

   has cleans_items => (is => 'ro', default => 1);

   sub update ($self, $event) {
      my $triggers = $self->triggers;
      my $game     = $self->game;

      # first pass, see if every group has some busy position
      my @present;
      for my $trigger ($triggers->@*) {
         my $nhf      = $trigger->{next_hop_for};
         my @operands = map {
            my $pos = $_;
            my $next_hop = $nhf->{$pos} // [];
            map { [$_, $pos, $next_hop] } $game->position($pos)->items
         } keys $nhf->%* or return;    # no items, no party
         push @present,
           {
            operands => \@operands,
            counters => $trigger->{counters} // [],
           };
      } ## end for my $trigger ($triggers...)

      # here I have to enact over items at specific positions
      for my $fired (@present) {
         for my $operand ($fired->{operands}->@*) {
            my ($item_id, $pre, $post) = $operand->@*;
            my $item = $game->item($item_id);
            $item->leave($pre);
            $item->register_into(ref $post ? $post->@* : $post);

            $game->remove_items($item)
              if !$item->positions && $self->cleans_items;

            # one counter action for every pair
            for my $counter ($fired->{counters}->@*) {
               my ($n, $d) = ref $counter ? $counter->%* : ($counter, 1);
               $game->counter_delta($n, $d);
            }
         } ## end for my $operand ($fired...)
      } ## end for my $fired (@present)

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
