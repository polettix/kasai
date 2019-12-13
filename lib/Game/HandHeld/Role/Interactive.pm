use 5.024;

package Game::HandHeld::Role::Interactive {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Scalar::Util 'blessed';
   use List::Util 'first';
   use Ouch ':trytiny_var';
   use Game::HandHeld::Collection;
   use namespace::clean;

   has _interactions => (
      is      => 'ro',
      default => sub { return [] },
      isa     => sub ($x) {
         ouch 'invalid-collection', 'invalid collection for interactions'
           unless blessed($x) && $x->isa('Game::HandHeld::Collection');
      },
      coerce => sub ($x) {
         return $x if blessed($x);
         return Game::HandHeld::Collection->new(
            elements    => $x,
            name        => 'interactions',
            stringifier => 'name',
         );
      },
   );

   sub interactions ($self) { return $self->_interactions->elements }

   sub has_interaction ($s, $int) { $s->_interactions->has_element($int) }

   sub record_interactions ($self, @interactions) {
      $self->_interactions->append(@interactions);
      return $self;
   }

   sub clear_interactions ($self) {
      $self->_interactions->evacuate;
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
