use 5.024;

package Game::HandHeld::Role::Tagged {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Scalar::Util 'blessed';
   use List::Util 'first';
   use Ouch;
   use Game::HandHeld::Collection;
   use Log::Any '$log';
   use namespace::clean;

   has _tags => (
      is       => 'ro',
      default  => sub { return {} },
      init_arg => 'tags',
      isa      => sub ($x) {
         ouch 'invalid-tags', 'invalid set of tags'
           unless ref $x eq 'HASH';
      },
      coerce => sub ($x) {
         ouch 'undefined-tag', 'undefined tag' unless defined $x;
         $x = [$x] unless ref $x;
         $x = {map { $_ => 1 } $x->@*} if ref $x eq 'ARRAY';
         return $x;
      },
   );

   sub tags ($self) {
      return sort { $a <=> $b } keys $self->_tags->%*;
   }

   sub has_tags ($self, @tags) {
      my $ts = $self->_tags;
      for my $tag (@tags) {
         return unless exists $ts->{$tag};
      }
      return 1;
   } ## end sub has_tags
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::Tagged - something that has tags

=head1 DESCRIPTION

Likely composed into an ::Item.

=cut
