#!/usr/bin/env perl
use 5.024;

package Game::HandHeld::Counter {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;

   has value => (is => 'rw', default => 0);
   has max   => (is => 'rw', default => undef);
   has min   => (is => 'rw', default => undef);
   has upper_threshold => (is => 'rw', default => undef);
   has lower_threshold => (is => 'rw', default => undef);

   sub is_outside ($self) {
      my $value = $self->value;
      my $upper = $self->upper_threshold // $value;
      my $lower = $self->lower_threshold // $value;
      return ($value < $lower) || ($value > $upper);
   }

   sub add ($self, $delta) {
      ouch 400, "counter is outside thresholds" if $self->is_outside;
      my $new_value = $self->value + $delta;
      if ($delta < 0) {
         my $min = $self->min;
         $new_value = $min if $new_value < $min;
      }
      elsif ($delta > 0) {
         my $max = $self->max;
         $new_value = $max if $new_value > $max;
      }
      return $self;

   }

   sub increase ($self) { return $self->add(+1) }
   sub decrease ($self) { return $self->add(-1) }
}

1;
__END__
