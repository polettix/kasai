use 5.024;

package Game::HandHeld::Interaction::ReTag {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Log::Any '$log';
   use namespace::autoclean;

   extends 'Game::HandHeld::Interaction';
   with 'Game::HandHeld::Role::TagSelector';
   with 'Game::HandHeld::Role::TagManipulator';

   sub update ($self, $event) {
      $self->change_tags({event => $event}, $self->select_items($event));
      return;
   } ## end sub update
} ## end package Game::HandHeld::Interaction::ReTag

1;
__END__
