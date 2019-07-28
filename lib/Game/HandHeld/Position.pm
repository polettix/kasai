use 5.024;

package Game::HandHeld::Position {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr weaken >;

   # public accessors
   has id        => (is => 'ro', default => sub ($s) { refaddr($s) });
   has screen    => (is => 'rw', default => undef, weak_ref => 1);
   has ui_data   => (is => 'rw');

   # private stuff
   has _current  => (is => 'ro', default => sub { return {} } );
   has _succ_for => (
      is => 'ro',
      default => sub { return {} },
      init_arg => 'neighbor_towards',
   );

   # item management interface
   sub __idof ($x) { blessed($x) ? $x->id : ref $x ? refaddr($x) : $x }

   sub register ($self, $item) {
      weaken($self->_current->{__idof($item)} = $item);
      return $self;
   }

   sub release ($self, $item) {
      delete($self->_current->{__idof($item)});
      return $self;
   }

   sub guests ($self) { return values $self->_current->%* }

   sub is_busy ($self) { return scalar keys $self->_current->%* }

   
   # neighbors management interface
   sub neighbor_towards ($self, $dir) {
      my $sf = $self->_succ_for;
      ouch 400, "'@{[ $self->id ]}' has no neighbor towards '$dir'"
         unless defined $sf->{$dir};
      return $self->screen->get_position($sf->{$dir});
   }

   sub add_neighbors ($self, %mapping) {
      my $sf = $self->_succ_for;
      $sf->%* = ($sf->%*, %mapping);
      return $self;
   }
}

1;
__END__
