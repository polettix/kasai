use 5.024;

package Game::HandHeld::Interaction {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use namespace::autoclean;

   with 'Game::HandHeld::Role::Identifier';
   with 'Game::HandHeld::Role::GamePointer';
   with 'Game::HandHeld::Role::EventRecipient';

   # This makes this class "abstract" in that some form of overriding
   # should happen
   sub update ($self, $event) {
      ouch 'not-implemented', 'method update MUST be overridden';
   }
} ## end package Game::HandHeld::Interaction

1;
__END__
