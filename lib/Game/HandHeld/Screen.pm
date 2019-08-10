use 5.024;

package Game::HandHeld::Screen {
   use Moo;
   use warnings;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Storable 'dclone';
   use Try::Catch;
   use Scalar::Util qw< blessed refaddr weaken >;
   use Module::Runtime 'use_module';
   use Game::HandHeld::Position;

   with 'Game::HandHeld::Role::GamePointer';

   has _position_for => (
      is       => 'ro',
      init_arg => undef,
      default  => sub { return {} },
   );

   sub BUILD ($self, $args) {
      $self->_build_positions($args->{positions});
   }

   sub _hoh_to_aoh ($self, $h) {
      return [
         map { ref $h->{$_} eq 'HASH' ? {$h->{$_}->%*, id => $_} : $_; }
           keys $h->%*
      ];
   } ## end sub _hoh_to_aoh

   sub _build_positions ($self, $spec) {
      $spec = $self->_hoh_to_aoh($spec) if ref $spec eq 'HASH';
      ouch 'invalid-positions', 'invalid input positions, not href or aref'
        unless ref $spec eq 'ARRAY';
      my @spec = $spec->@*;
      my $pf   = $self->_position_for;
      $pf->%* = ();    # paranoia
      for my $pos (@spec) {
         ouch 'undefined-position', 'undefined input position'
           unless defined $pos;
         $pos = {id => $pos} unless ref $pos;
         ouch 'invalid-position', 'invalid position definition'
           unless ref $pos eq 'HASH';
         $pos = $self->_new_position(dclone($pos));
         my $id = $pos->id;
         ouch 'duplicate-position-id', "duplicate position id '$id'"
           if exists $pf->{$id};
         $pf->{$id} = $pos;
      } ## end for my $pos (@spec)
   } ## end sub _build_positions

   sub _new_position ($self, $x, @override) {
      $x = {id => $x} unless ref $x;
      my $class = $self->{_class} // 'Game::HandHeld::Position';
      return use_module($class)
        ->new($x->%*, @override, game => $self->game,);
   } ## end sub _new_position

#   sub add_positions ($self, @list) {
#      my $pf = $self->_position_for;
#      my $myself = refaddr($self);
#      for my $e (@list) {
#         my $p = blessed($e)    ? $e
#            : ! ref($e)         ? $self->_new_position($e)
#            : ref($e) eq 'HASH' ? $self->_new_position($e)
#            : ouch 400, ' cannot handle reference type ' . ref($e);
#         ouch 'invalid-screen-on-position', 'invalid screen set for position'
#            unless refaddr($p->screen) eq $myself;
#         my $id = $p->id;
#         ouch 'duplicate-position-id', 'duplicated position id'
#            if exists $pf->{$id};
#         $pf->{$id} = $p;
#      }
#      return $self;
#   }

   sub position ($self, $x) {
      return $x if blessed $x;
      ouch 400, 'cannot handle reference input ' . ref $x if ref $x;
      my $pf = $self->_position_for;
      ouch 404, "Not Found '$x'" unless exists $pf->{$x};
      return $pf->{$x};
   } ## end sub position

   sub set_ui_data ($self, @as) {
      my %data_for = @as && ref $as[0] eq 'HASH' ? $as[0]->%* : @as;
      while (my ($name, $data) = each %data_for) {
         try { $self->position($name)->ui_data($data) }
         catch { die $_ unless kiss(404) };
      }
      return $self;
   } ## end sub set_ui_data

   sub positions ($self) { return values $self->_position_for->%* }
} ## end package Game::HandHeld::Screen

1;
__END__
