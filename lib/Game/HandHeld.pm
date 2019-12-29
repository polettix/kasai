use 5.024;

package Game::HandHeld {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Ouch ':trytiny_var';
   use Scalar::Util qw< blessed refaddr >;
   use Module::Runtime 'use_module';
   use Storable 'dclone';
   use Log::Any '$log';
   use Data::Dumper;

   use Game::HandHeld::Screen;
   use Game::HandHeld::Counter;

   use constant GO_MISSES => 3;

   has _changes => (is => 'rw', default => sub { return {} });

   has _counter_for => (
      is => 'ro',
      init_arg => undef,
      default => sub { return {} },
   );

   has _interactions => (
      is => 'ro',
      init_arg => undef,
      default => sub ($s) { return [] },
   );

   has _item_for => (
      is => 'ro',
      init_arg => undef,
      default => sub ($self) { return {} },
   );

   has screen => (
      is => 'rwp',
      isa => sub ($x) {
         return unless defined $x;
         return if blessed($x) && $x->isa('Game::HandHeld::Screen');
         ouch 'invalid-screen', "invalid value for 'screen'";
      },
      init_arg => undef,
      handles => [qw< position positions >],
   );

   has _sync_events => (
      is => 'ro',
      default => sub { return [] },
      init_arg => undef,
   );

   has _ticks => (is => 'rw', clearer => 1, default => 0);

   sub BUILD ($self, $args) {
      $self->_build_counter_for($args->{counters});
      $self->_build_screen($args->{positions});
      $self->_build_item_for($args->{items});
      $self->_build_interactions($args->{interactions});
      $self->_build_sync_events($args->{sync_events});
   }

   sub _build_counter_for ($self, $spec) {
      $spec //= [
         {
            score => {},
            miss  => { upper_threshold => (GO_MISSES - 1) },
         },
         {
            catch => 'score'
         },
      ];
      $spec = [$spec] if ref $spec eq 'HASH';
      ouch 'invalid-counters', 'invalid counters definition'
         unless ref $spec eq 'ARRAY';
      my @spec = map {$_->%*} $spec->@*;
      ouch 'invalid-counters', 'counters aref must have even items'
         if @spec % 2;
      my $cf = $self->_counter_for;
      $cf->%* = (); # paranoia
      while (@spec) {
         my ($name, $target) = splice @spec, 0, 2;
         ouch 'duplicate-counter-id', 'duplicate counter identifier'
            if exists $cf->{$name};
         if (! ref $target) {
            ouch 'undefined-counter', "counter '$name' is undefined"
               unless defined $target;
            ouch 'missing-counter', "counter '$name' refers to missing '$target'"
               unless exists $cf->{$target};
            $cf->{$name} = $cf->{$target};
         }
         else {
            $cf->{$name} = $self->_new_something(
               type => 'counter',
               default_class => 'Game::HandHeld::Counter',
               base_class => 'Game::HandHeld::Counter',
               spec => $target,
               override => [],
            );
         }
      }
   }

   sub _build_sync_events ($self, $spec) {
      ouch 'invalid-sync_events', "invalid 'sync_events'"
         unless ref $spec eq 'ARRAY';
      $self->_sync_events->@* = (
         map {
            my $x = $_;
            $x = {name => $x} unless ref $x;
            ouch 'invalid-sync_event', "invalid sync_event definition"
               unless ref $x eq 'HASH';
            $self->_new_sync_event($x);
         } $spec->@*
      );
   }

   sub _new_sync_event ($self, $x, @override) {
      return $self->_new_something(
         type => 'sync_event',
         default_class => 'Game::HandHeld::SyncEvent::Simple',
         base_class => 'Game::HandHeld::SyncEvent',
         spec => $x,
         override => \@override,
      );
   }

   sub _build_screen ($self, $positions) {
      return if $self->screen;
      my $screen = Game::HandHeld::Screen->new(
         game => $self,
         positions => $positions,
      );
      $self->_set_screen($screen);
      return;
   }

   sub _build_item_for ($self, $specs) {
      $specs = $self->_items_hoh_to_aoh($specs) if ref $specs eq 'HASH';
      ouch 'invalid-items', 'invalid input items, not href or aref'
         unless ref $specs eq 'ARRAY';
      my $item_for = $self->_item_for;
      $item_for->%* = (); # paranoia
      $self->add_items($specs->@*);
      return;
   }

   sub _items_hoh_to_aoh ($self, $h) {
      return [
         map {
            ref $h->{$_} eq 'HASH' ? {$h->{$_}->%*, id => $_} : $_;
         } keys $h->%*
      ];
   }

   sub _new_item ($self, $x, @override) {
      return $self->_new_something(
         type => 'item',
         default_class => 'Game::HandHeld::Item',
         base_class => 'Game::HandHeld::Item',
         spec => $x,
         override => \@override,
      );
   }

   sub _build_interactions ($self, $spec) {
      ouch 'invalid-interactions', 'invalid interactions (not arrayref)'
         unless ref $spec eq 'ARRAY';
      my $interactions = $self->_interactions;
      $interactions->@* = (); # paranoia
      for my $i ($spec->@*) {
         ouch 'invalid-interaction', 'invalid interaction (not hashref)'
            unless ref $i eq 'HASH';
         push $interactions->@*, $self->_new_interaction($i);
      }
   }

   sub _new_interaction ($self, $x, @override) {
      return $self->_new_something(
         type => 'interaction',
         default_class => undef,
         base_class => 'Game::HandHeld::Interaction',
         spec => $x,
         override => \@override,
      );
   }

   sub _new_something ($self, %args) {
      my ($type, $default_class, $base_class, $override) =
         @args{qw< type default_class base_class override >};
      my $spec = dclone($args{spec});
      ouch "invalid-$type", "invalid $type definition"
         unless ref $spec eq 'HASH';
      my $class = $spec->{_class};
      $class //= $default_class if defined $default_class;
      $class = use_module($class);
      $override //= [];
      my $instance = $class->new($spec->%*, $override->@*, game => $self)
         or ouch "constructor-$type", "cannot create instance of class $class";
      ouch "invalid-$type", "invalid class for $type"
         unless $instance->isa($base_class);
      return $instance;
   }

   # counters interface, default counter is 'score'
   sub counter_delta ($self, $name, $delta) {
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
   sub increase ($s, $n = 'score') { $s->counter_delta($n, +1) }
   sub decrease ($s, $n = 'score') { $s->counter_delta($n, -1) }
   sub total ($s, $n = 'score') { return $s->counter_for($n)->value }
   sub last_update_changes ($self) { return $self->_changes->%* }

   # items facility
   sub item ($self, $item, %opts) {
      ouch 'undefined-item', 'undefined input item' unless defined $item;
      return $item if blessed($item);
      return $self->add_items($item)->[0] if ref $item;
      my $if = $self->_item_for;
      return $if->{$item} if exists $if->{$item};
      ouch 'missing-item', "item '$item' is missing" unless $opts{'auto'};
      return $self->add_items({id => $item})->[0];
   }
   sub add_items ($self, @items) {
      my $item_for = $self->_item_for;
      my @retval;
      for my $item (@items) {
         ouch 'undefined-item', 'undefined input item' unless defined $item;
         $item = {id => $item} unless ref $item;
         ouch 'invalid-item', 'invalid item definition' if ref $item ne 'HASH';
         my %spec = $item->%*;
         $spec{positions} = [$spec{position}] if defined $spec{position};
         $item = $self->_new_item(\%spec);
         my $id = $item->id;
         ouch 'duplicate-item-id', "duplicate item id '$id'"
            if exists $item_for->{$id};
         push @retval, $item_for->{$id} = $item;

         # now the item is tracked, we can register into position
         $item->register;
      }
      return @retval if wantarray;
      return \@retval;
   }
   sub remove_items ($self, @items) {
      for my $item (@items) {
         my $id = blessed($item) ? $item->id : $item;
         my $item_object = delete $self->_item_for->{$id} or next;
         $item_object->vanish;
      }
      return $self;
   }
   sub items ($self, %args) {
      my @tags = defined $args{tags} ? $args{tags}->@* : ();
      return grep { $_->has_tags(@tags) } values $self->_item_for->%*;
   }

   # interactions
   sub interaction ($self, $id) { # FIXME optimize? worth the trouble? use selectors?
      my ($retval) = grep { $_->id eq $id } $self->interactions;
      return $retval;
   }
   sub interactions ($self) { return $self->_interactions->@* }

   # sync events
   sub sync_events ($self) { return $self->_sync_events->@* }
   sub increase_speed ($self, $amount = 1) {
      $_->speed($_->speed + $amount) for $self->sync_events;
      return $self;
   }
   sub decrease_speed ($self, $amount = 1) {
      return $self->increase_speed(-$amount);
   }

   # game interface
   sub is_over ($self) { $self->counter_for('miss')->is_outside }

   sub tick ($self, @async) {
      my $ticks = ($self->_ticks // 0) + 1;
      $self->_ticks($ticks);
      my @sync = map { $_->tick($ticks) } $self->sync_events;
      $self->update($_) for (@async, @sync);
      return $self;
   }

   sub update ($self, $event) { # e.g. advance, move, ...
      $self->_changes({}); # reset
      for my $interaction ($self->interactions) {
         my $outcome = $interaction->notify($event) // 'continue';
         last if $outcome eq 'break';
      }
      return $self;
   }

   sub set_ui_data ($self, @args) {
      $self->screen->set_ui_data(@args);
      return $self;
   }

   # load from file
   sub data_from_file ($class, $file) {
      if (! ref $file) {
         open my $fh, '<', $file or ouch 'open', "open: $!";
         $file = $fh;
      }
      ouch 'invalid-input', 'invalid input file'
        unless ref $file eq 'GLOB';

      binmode $file, ':encoding(utf-8)';
      my $text = do { local $/; <$file> };

      my $data;
      if ($text =~ m{\A \s* \{ }mxs) { # JSON::PP should suffice
         require JSON::PP;
         $data = JSON::PP::decode_json($text);
      }
      else {
         require YAML;
         $data = YAML::Load($text);
      }

      return $data;
   }

   sub new_from_file ($class, $file) {
      my $spec = $class->data_from_file($file);
      return $class->new($spec->%*);
   }
}

1;
__END__
