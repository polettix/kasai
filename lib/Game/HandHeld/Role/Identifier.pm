use 5.024;

package Game::HandHeld::Role::Identifier {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use namespace::clean;

   has id => (
      is     => 'lazy',
      coerce => sub ($x) {
         ouch 'undefined-id', 'undefined id' unless defined $x;
         return $x unless ref $x;
         return $x->new_id if blessed $x;
         ouch 'invalid-id', 'invalid ref for id';
      }
   );

   sub _build_id ($self) { return refaddr($self) }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::Identifier - role for something with an identifier

=head1 DESCRIPTION

This role provides an C<id> method.

=cut
