use 5.024;

package Game::HandHeld::Role::Positional {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Scalar::Util 'blessed';
   use List::Util 'first';
   use Ouch ':trytiny_var';
   use Game::HandHeld::Collection;
   use namespace::clean;

   requires qw< id game >;

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

   sub positions ($self) { return $self->_positions->elements }

   sub has_position ($self, $pos) { $self->_positions->has_element($pos) }

   sub register ($self) {
      my $id   = $self->id;
      my $game = $self->game;
      $game->position($_)->register($id) for $self->positions;
      return $self;
   } ## end sub register ($self)

   sub register_into ($self, @positions) {
      $self->leave(@positions);    # "refresh" by removing if present

      my $id   = $self->id;
      my $game = $self->game;
      my $ps   = $self->_positions;
      $game->position($_)->register($id) for $ps->append(@positions);

      return $self;
   } ## end sub register_into

   sub leave ($self, @positions) {
      my $id   = $self->id;
      my $game = $self->game;
      my $ps   = $self->_positions;
      $game->position($_)->release($id) for $ps->remove(@positions);
      return $self;
   } ## end sub leave

   sub vanish ($self) {
      my $id   = $self->id;
      my $game = $self->game;
      my $ps   = $self->_positions;
      $game->position($_)->release($id) for $ps->evacuate;
      return $self;
   } ## end sub vanish ($self)

   sub move_into ($self, @positions) {
      $self->vanish;
      $self->register_into(@positions);
      return $self;
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::Positional - something that occupies position(s)

=head1 DESCRIPTION

Likely composed into an ::Item.

=cut
