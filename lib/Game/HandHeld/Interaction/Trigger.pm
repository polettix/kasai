use 5.024;

package Game::HandHeld::Interaction::Trigger {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Module::Runtime 'use_module';
   use Log::Any '$log';

   extends 'Game::HandHeld::Interaction';
   has condition => (
      is       => 'ro',
      required => 1,
      isa      => sub ($x) {
         ouch 'invalid-condition', 'invalid condition for skipper'
           unless ref $x eq 'CODE';
      },
      coerce => sub ($x) {
         my $xref = ref $x;
         return $x if $xref eq 'CODE';
         ouch 'invalid-condition', 'invalid condition (sub or hashref)'
           unless $xref eq 'HASH';
         my %args = $x->%*;
         defined(my $class = delete $args{_class})
           or ouch 'no-condition-class', 'no class for condition';
         my $evaluator = use_module($class)->new(%args);
         return $evaluator if ref $evaluator eq 'CODE';
         ouch 'invalid-condition', "missing method 'evaluate'"
           unless blessed($evaluator) && $evaluator->can('evaluate');
         return sub { return $evaluator->evaluate(@_) };
      },
   );
   has skip_rest => (is => 'ro', default => 0);
   has targets => (
      is       => 'ro',
      required => 1,
      isa      => sub ($x) {
         ouch 'invalid-condition', 'invalid condition for skipper'
           unless ref $x eq 'ARRAY';
      }
   );

   sub update ($self, $event) {
      return unless $self->condition->($self, $event);
      my $game = $self->game;
      $game->interaction($_)->activate($event) for $self->targets->@*;
      return;
   } ## end sub update
};

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Interaction::Pauser - pause for some events

=head1 DESCRIPTION

This interaction encapsulates pausing for some events.

=cut
