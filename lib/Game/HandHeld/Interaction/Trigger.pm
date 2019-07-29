use 5.024;

package Game::HandHeld::Interaction::Trigger {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Game::HandHeld::Counter;

   extends 'Game::HandHeld::Interaction::';

   has items_for => (is => 'rw', default => sub { {} });

   sub BUILD ($self, $args) {
      my $if = $args->{items_for} // {};
      ouch 400, 'invalid items_for as input to interaction (trigger)'
         unless ref $if eq 'HASH';
      my $screen = $self->game->screen;
      my %items_for;
      for (my ($event, $items) = each $if->%*) {
         $items_for{$event} = [
            map { blessed($_) ? $_ : $game->get_item($_) } $items->@*
         ];
      }
      $self->items_for(\%items_for);
      return;
   }

   sub update ($self, $event) {
      my $if = $self->items_for;
      return $self unless exists $if->{$event};
      my $name = $self->name;
      $_->record_interaction($name) for $if->{$event}->@*;
      return $self;
   }

};

1;
__END__
