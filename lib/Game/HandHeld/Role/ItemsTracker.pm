use 5.024;

package Game::HandHeld::Role::ItemsTracker {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util 'blessed';
   use Game::HandHeld::Collection;
   use Log::Any '$log';
   use namespace::clean;

   requires 'game';

   has _items => (
      is      => 'ro',
      default => sub { return [] },
      isa     => sub ($x) {
         ouch 'invalid-collection', 'invalid collection for positions'
           unless blessed($x) && $x->isa('Game::HandHeld::Collection');
      },
      coerce => sub ($x) {
         return $x if blessed($x);
         return Game::HandHeld::Collection->new(
            elements    => $x,
            name        => 'items',
            stringifier => 'id',
         );
      },
      init_arg => 'items',
   );

   sub items ($self, %opts) {
      my @ids = $self->_items->elements;
      return @ids unless $opts{as_objects};
      my $game = $self->game;
      return map { $game->item($_) } @ids;
   } ## end sub items

   sub has_item ($self, $x) { return $self->_items->has_element($x) }

   sub add_items ($self, @items) {
      my $game = $self->game;
      $self->_items->append(map { $game->item($_)->id } @items);
      return $self;
   }

   sub remove_items ($self, @items) {
      $self->_items->remove(@items);
      return $self;
   }

   sub remove_all_items ($self) {
      $self->_items->evacuate;
      return $self;
   }

   sub clean_items_interactions ($self) {
      my $game = $self->game;
      $game->item($_)->clear_interactions for $self->items;
      return $self;
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::ItemsTracker - track multiple items

=head1 DESCRIPTION

Holds a pointer to an item. Has a flag to mark if interactions should be
cleared after having been used.

=cut
