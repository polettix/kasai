use 5.024;

package Game::HandHeld::Collection {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Try::Catch;
   use Scalar::Util 'blessed';
   use Log::Any '$log';
   use namespace::clean;

   has name        => (is => 'ro');
   has stringifier => (is => 'ro');
   has _elements   => (is => 'ro', init_arg => 'elements');
   has _has_element => (
      is       => 'lazy',
      init_arg => undef,
      default  => sub ($self) {
         return {map { $_ => 1 } $self->elements};
      }
   );

   around BUILDARGS => sub ($orig, $class, @args) {
      my %args = @args && ref $args[0] eq 'HASH' ? $args[0]->%* : @args;
      ouch 'undefined-name', 'undefined name of collection'
        unless defined $args{name};

      if (!ref $args{stringifier}) {
         my ($name, $method_name) = @args{qw< name stringifier >};
         $method_name //= 'id';
         $args{stringifier} = sub ($x) {
            ouch "$name-undefined", "$name: undefined input to stringifier"
              unless defined $x;
            return $x unless ref $x;
            ouch "$name-unblessed", "$name: unblessed ref to stringifier"
              unless blessed($x);
            my $method = $x->can($method_name)
              or ouch "$name-unsupported",
              "$name: unsupported stringifier '$method_name' for '$x'";
            return $x->$method;
         };
      } ## end if (!ref $args{stringifier...})
      elsif (ref $args{stringifier} ne 'CODE') {
         ouch 'invalid-stringifier', 'invalid stringifier provided';
      }

      my $es = $args{elements} // [];
      $args{elements} = [map { $args{stringifier}->($_) } $es->@*];

      return \%args;
   };

   sub elements ($self) { return $self->_elements->@* }

   sub has_element ($self, $x) {
      return $self->_has_element->{$self->stringifier->($x)} ? 1 : 0;
   }

   sub append ($self, @elements) {
      my $es          = $self->_elements;
      my $he          = $self->_has_element;
      my $stringifier = $self->stringifier;
      my @appended;
      for my $element (@elements) {
         my $key = $stringifier->($element);
         push $es->@*, $key;
         $he->{$key} = 1;
         push @appended, $key;
      } ## end for my $element (@elements)
      return @appended if wantarray;
      return \@appended;
   } ## end sub append

   sub remove ($self, @elements) {
      my $es          = $self->_elements;
      my $he          = $self->_has_element;
      my $stringifier = $self->stringifier;
      my @removed;
      for my $element (@elements) {
         last unless $es->@*;    # if it's empty... no point to go on
         my $key = $stringifier->($element);
         next unless $he->{$key};
         $es->@* = grep { $_ ne $key } $es->@*;
         delete $he->{$key};
         push @removed, $key;
      } ## end for my $element (@elements)
      return @removed if wantarray;
      return \@removed;
   } ## end sub remove

   sub evacuate ($self) {
      my $es = defined wantarray ? [$self->elements] : undef;
      $self->_elements->@* = $self->_has_element->%* = ();
      return $es->@* if wantarray;
      return $es;
   } ## end sub evacuate ($self)
} ## end package Game::HandHeld::Collection

1;
__END__

=encoding utf-8

=head1 NAME

Game::HandHeld::Collection - manage a collection of strings

=head1 DESCRIPTION


=cut
