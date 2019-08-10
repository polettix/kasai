use 5.024;

package Game::HandHeld::Position {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr weaken >;
   use namespace::autoclean;

   with 'Game::HandHeld::Role::Identifier';
   with 'Game::HandHeld::Role::GamePointer';
   with 'Game::HandHeld::Role::ItemsTracker';

   # public accessors
   has ui_data => (is => 'rw');

   # private stuff
   has _succ_for => (
      is       => 'ro',
      default  => sub { return {} },
      init_arg => 'neighbor_towards',
   );

   # guest objects interface
   sub is_busy ($self) { return scalar $self->items }
   sub register ($self, @items) { $self->add_items(@items) }
   sub release ($self, @items) { $self->remove_items(@items) }

   # neighbors management interface
   sub neighbor_towards ($self, $dir) {
      my $sf = $self->_succ_for;
      ouch 400, "'@{[ $self->id ]}' has no neighbor towards '$dir'"
        unless defined $sf->{$dir};
      return $self->game->position($sf->{$dir});
   } ## end sub neighbor_towards
} ## end package Game::HandHeld::Position

1;
__END__
