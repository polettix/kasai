use 5.024;

package Game::HandHeld::Role::PositionsTracker {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util 'blessed';
   use Game::HandHeld::Collection;
   use Log::Any '$log';
   use namespace::clean;

   requires 'game';

   has _positions => (
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
            name        => 'positions',
            stringifier => 'id',
         );
      },
      init_arg => 'positions',
   );

   sub positions ($self, %opts) {
      my @ids = $self->_positions->elements;
      return @ids unless $opts{as_objects};
      my $game = $self->game;
      return map { $game->position($_) } @ids;
   } ## end sub positions

   sub has_position ($s, $x) { return $s->_positions->has_element($x) }

   sub add_positions ($self, @pos) {
      my $game = $self->game;
      $self->_positions->append(map { $game->position($_)->id } @pos);
      return $self;
   }

   sub remove_positions ($self, @pos) {
      my $game = $self->game;
      $self->_positions->remove(@pos);
      return $self;
   }

   sub remove_all_positions ($self) {
      my $game = $self->game;
      $self->_positions->evacuate;
      return $self;
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::PositionsTracker - track multiple positions

=head1 DESCRIPTION

Holds a list of positions.

=cut
