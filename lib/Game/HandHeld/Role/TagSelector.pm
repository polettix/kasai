use 5.024;

package Game::HandHeld::Role::TagSelector {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Log::Any '$log';
   use namespace::clean;

   requires 'game';

   has _selector => (
      is       => 'ro',
      init_arg => 'selector',
      default  => sub { return [] },
      coerce   => sub ($x) {
         ouch 'undefined-selector', 'undefined selector'
           unless defined $x;
         $x = [$x] unless ref $x eq 'ARRAY';
         for my $y ($x->@*) {
            my $yref = ref $y;
            ouch 'invalid-selector', 'invalid selector'
              if $yref && $yref ne 'HASH';
         }
         return $x;
      },
   );

   sub selector ($self, $event) {
      my @retval;
      for my $s ($self->_selector->@*) {
         my $sref = ref $s;
         if (!$sref) { push @retval, $s }
         elsif ($sref eq 'HASH') {
            my $cmd = $s->{cmd} // $s->{command};
            if ($cmd eq 'event') {
               push @retval, $event;
            }
            else {
               ouch 'invalid-selector', "invalid selection cmd '$cmd'";
            }
         } ## end elsif ($sref eq 'ARRAY')
      } ## end for my $s ($self->_selector...)
      return \@retval;
   } ## end sub selector

   sub select_items ($s, $e) { $s->game->items(tags => $s->selector($e)) }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::TagSelector - generate selector of tags

=head1 DESCRIPTION

Likely composed into an ::Interaction that wants to select items based on
tags.

=cut
