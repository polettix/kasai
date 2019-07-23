use 5.024;

package Game::HandHeld::Screen {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr weaken >;
   use Module::Runtime 'use_module';
   use Game::HandHeld::Position;

   use constant DEFAULT_CLASS => 'Game::HandHeld::Position';

   has _position_for => (is => 'ro', default => sub { return {} });
   has position_class => (is => 'ro', default => DEFAULT_CLASS);

   sub BUILD ($self, $args) {
      if (my $ps = $args->{positions}) {
         ouch 400, 'invalid input positions' unless ref($ps) eq 'ARRAY';
         $self->add_positions($ps->@*);
      }
      return;
   }

   sub add_positions ($self, @list) {
      my $pf = $self->_position_for;
      my $class = use_module($self->position_class);
      for my $e (@list) {
         my $p = blessed($e)    ? $e
            : ! ref($e)         ? $class->new(id => $e)
            : ref($e) eq 'HASH' ? use_module($e->{_class} // $class)->new($e->%*)
            : ouch 400, ' cannot handle reference type ' . ref($e);
         $p->screen($self); # "acquire" this position
         $pf->{$p->id} = $p;
      }
   }

   sub get_position ($self, $x) {
      return $x if blessed $x;
      ouch 400, ' cannot handle reference input ' . ref($x);
      my $pf = $self->_position_for;
      ouch 404, "Not Found '$x'" unless exists $pf->{$x};
      return $pf->{$x};
   }

   sub set_ui_data ($self, @as) {
      my %data_for = @as && ref $as[0] eq 'HASH' ? $as[0]->%* : @as;
      while (my ($name, $data) = each %data_for) {
         $self->get_position($name)->ui_data($data);
      }
      return $self;
   }

   sub positions ($self) { return values $self->_position_for->%* }
}

1;
__END__
