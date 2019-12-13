use 5.024;

package Game::HandHeld::Role::Tagged {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Scalar::Util 'blessed';
   use List::Util 'first';
   use Ouch ':trytiny_var';
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

   sub tags ($self, @filters) {
      my %tags = $self->_tags->%*;

      if (@filters) {
         my @all_tags = keys %tags;
         TAG:
         for my $tag (@all_tags) {
            for my $filter (@filters) {
               my $fref = ref $filter;
               if ($fref eq 'Regexp') {
                  next TAG if $tag =~ $filter;
               }
               elsif ($fref) {
                  ouch 'invalid-spec', "invalid filter for tags ($fref)";
               }
               else {
                  next TAG if $tag eq $filter;
               }
            }
            delete $tags{$tag}; # no match, no party
         }
      }

      return sort { $a cmp $b } keys %tags;
   }

   sub has_tags ($self, @tags) {
      my $ts = $self->_tags;
      for my $tag (@tags) {
         return unless exists $ts->{$tag};
      }
      return 1;
   } ## end sub has_tags

   sub remove_tags ($self, @tags) {
      my $tags = $self->_tags;
      delete $tags->{$_} for @tags;
      return $self;
   }

   sub add_tags ($self, @tags) {
      my $tags = $self->_tags;
      $tags->{$_} = 1 for @tags;
      return $self;
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::Tagged - something that has tags

=head1 DESCRIPTION

Likely composed into an ::Item.

=cut
