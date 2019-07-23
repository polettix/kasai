use 5.024;

package Game::HandHeld {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Module::Runtime 'use_module';

   use Game::HandHeld::Counter;

   use constant GO_MISSES => 3;

   has _changes => (is => 'rw', default => sub { return {} });

   has _counter_for => (
      is => 'ro',
      default => sub {
         my $score = Game::HandHeld::Counter->new;
         my $misses = Game::HandHeld::Counter->new(
            upper_threshold => (GO_MISSES - 1),   
         );
         return {
            score => $score,
            catch => $score,
            miss  => $misses,
         };
      },
   );

   has _interactions => (
      is => 'ro',
      default => sub { return [] },
      init_arg => 'interactions',
   );

   has _items => (is => 'rw', default => sub { return {} });

   has screen => (
      is => 'ro',
      isa => sub ($x) { blessed($x) && $x->isa('Game::HandHeld::Screen') },
      default => sub {
         require Game::HandHeld::Screen;
         return Game::HandHeld::Screen->new;
      },
   );

   has _sync_events => (
      is => 'rw',
      default => sub { return [] },
      init_arg => 'sync_events',
   );

   has _ticks => (is => 'rw', clearer => 1, default => 0);

   sub _instance ($self, $default_class, $instance) {
      if (! blessed($instance //= {})) {
         my %args = $instance->%*;
         my $class = delete($args{_class}) // $default_class;
         $instance = use_module($class)->new(%args);
      }
      $instance->game($self) if $instance->can('game');
      return $instance;
   }

   sub BUILD ($self, $args) {
      my %args = $args->%*;

      # screen with positions
      my $scr = $self->_instance('Game::HandHeld::Screen', $args{screen});
      $scr->add_positions((delete($args{positions}) // [])->@*);
      $self->screen($scr);

      my @ints = map {$self->_instance('Game::HandHeld::Interaction', $_)}
         ($args{interactions} // [])->@*;
      $self->_interactions(\@ints);

      my @items = map {$self->_instance('Game::HandHeld::Item', $_)}
         ($args{items} // [])->@*;
      $self->_items({map {refaddr($_) => $_} @items});

      my @syevs = map {$self->_instance('Game::HandHeld::SyncEvents', $_)}
         ($args{sync_events} // [])->@*;
      $self->_sync_events(\@syevs);
   }

   # counters interface, default counter is 'score'
   sub _counter_delta ($self, $name, $delta) {
      $self->counter_for($name)->add($delta);
      $self->_changes->{$name}++;
      return $self;
   }
   sub counter_for ($self, $name) {
      my $cf = $self->_counter_for;
      return $cf->{$name} //= Game::HandHeld::Counter->new(name => $name);
   }
   sub add_counter ($self, $name, $counter = undef) {
      $self->_counter_for->{$name} = blessed($counter) ? $counter
         : Game::HandHeld::Counter->new($counter // {});
      return $self;
   }
   sub increase ($s, $n = 'score') { $s->_counter_delta($n, +1) }
   sub decrease ($s, $n = 'score') { $s->_counter_delta($n, -1) }
   sub total ($s, $n = 'score') { return $s->counter_for($n)->value }
   sub last_update_changes ($self) { return $self->_changes->%* }

   # screen interface
   sub positions ($self) { return $self->screen->positions }

   # items facility
   sub add_item ($self, $item) {
      $self->_items->{refaddr($item)} = $item;
      return $self;
   }
   sub remove_item ($self, $item) {
      delete $self->_items->{refaddr($item)};
      return $self;
   }
   sub items ($self) { return values $self->_items->%* }

   # game interface
   sub is_over ($self) { $self->counter_for('miss')->is_outside }

   sub tick ($self, @async) {
      my $ticks = ($self->_ticks // 0) + 1;
      $self->_ticks($ticks);
      my @sync = map { $_->tick($ticks) } $self->_sync_events->@*;
      $self->update($_) for (@async, @sync);
      return $self;
   }

   sub _updatables ($self) {
      return (values($self->_items->%*), $self->_interactions->@*);
   }

   sub update ($self, $event) { # e.g. advance, move, ...
      $self->_changes({}); # reset
      $_->update($event) for $self->_updatables;
      return $self;
   }

   sub set_ui_data ($self, @args) {
      $self->screen->set_ui_data(@args);
      return $self;
   }
}

1;
__END__
