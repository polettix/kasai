use 5.024;

package Game::HandHeld::Role::EventRecipient {
   use Moo::Role;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Log::Any '$log';
   use namespace::clean;

   requires 'update';

   has _events => (
      is       => 'ro',
      default  => sub { return [{regex => qr{(?mxs:)}}] },
      init_arg => 'events',
      coerce   => sub ($x) {    # force into key-value pairs
         ouch 'undefined-events', "undefined 'events'" unless defined $x;
         my $xref = ref $x;
         $x = [$x] if !$xref || $xref eq 'HASH';
         ouch 'invalid-events', "invalid 'events'"
           unless ref $x eq 'ARRAY';
         my (@retval, %words);
         for my $event ($x->@*) {
            my $eref = ref $event;
            if (!$eref) {
               $words{$event} = 1;
            }
            elsif ($eref eq 'HASH') {
               defined(my $rx = $event->{regex} // $event->{regexp})
                 or ouch 'invalid-event',
                 "missing regexp in hash for event";
               push @retval, qr{$rx};
            } ## end elsif ($eref eq 'HASH')
            else {
               ouch 'invalid-event', "invalid ref $eref for event";
            }
         } ## end for my $event ($x->@*)
         if (scalar keys %words) {
            my $rx = join '|', map { quotemeta $_ } keys %words;
            unshift @retval, qr{\A(?:$rx)\z};
         }
         return \@retval;
      }
   );

   sub handles ($self, $event) {
      for my $rx ($self->_events->@*) {
         return 1 if $event =~ $rx;
      }
      return 0;
   } ## end sub handles

   sub notify ($self, $event) {
      return unless $self->handles($event);
      return $self->update($event);
   }
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Role::Interaction - role for an interaction

=head1 DESCRIPTION

This is a I<base> role for all interactions, i.e. classes that encapsulate
an evolution business logic for the game.

=cut
