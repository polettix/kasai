use 5.024;

package Game::HandHeld::Role::TagManipulator {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Log::Any '$log';
   use namespace::clean;

   has remove => (is => 'rw', default => sub { return [] });
   has add    => (is => 'rw', default => sub { return [] });

   sub change_tags ($self, $meta_for, @items) {
      if (my @remove = $self->expand_tags($meta_for, $self->remove->@*)) {
         $_->remove_tags($_->tags(@remove)) for @items;
      }
      if (my @add = $self->expand_tags($meta_for, $self->add->@*)) {
         $_->add_tags(@add) for @items;
      }
      return $self;
   } ## end sub update

   sub expand_tags ($self, $meta_for, @tags) {
      my @retval;
      for my $x (@tags) {
         my $xref = ref $x;
         if ($xref eq 'HASH') {
            if (defined(my $rx = $x->{regex} // $x->{regexp})) {
               push @retval, qr{$rx};
            }
            elsif (defined(my $key = $x->{meta})) {
               if (exists $meta_for->{$key}) {
                  push @retval, $meta_for->{$key};
               }
               else {
                  ouch 'unknown-meta', "unknown tag meta $key";
               }
            }
         } ## end if ($xref eq 'HASH')
         elsif ($xref) {
            ouch 'invalid-tag', "cannot expand a tag from ref $xref";
         }
         else {
            push @retval, $x;
         }
      } ## end for my $x ($self->add->...)
      return @retval;
   } ## end sub selector
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::TagManipulator - generate selector of tags

=head1 DESCRIPTION

Likely composed into an ::Interaction that wants to select items based on
tags.

=cut
