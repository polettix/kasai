use 5.024;

package Game::HandHeld::Interface::Curses {
   use Moo;
   use experimental qw< postderef signatures >;
   no warnings qw< experimental::postderef experimental::signatures >;
   use Log::Any '$log';
   use Curses;
   use Time::HiRes qw< clock_gettime CLOCK_MONOTONIC >;
   use Game::HandHeld;
   use constant FRAMES_PER_SECOND => 25;
   use constant FRAME_DURATION    => (1.0 / FRAMES_PER_SECOND);

   has _game => (is => 'ro', required => 1, init_arg => 'game');
   has _background =>
     (is => 'ro', default => undef, init_arg => 'background');
   has _positions =>
     (is => 'ro', required => 1, init_arg => 'position');
   has _counters =>
     (is => 'ro', required => 1, init_arg => 'counter');
   has _win => (is => 'lazy', predicate => 1);

   sub new_from_files ($class, %args) {
      my $game = Game::HandHeld->new_from_file($args{game});
      my $data = Game::HandHeld->data_from_file($args{ui});
      return $class->new(
         $data->%*,
         game => $game,
      );
   }

   sub DEMOLISH ($self, $in_global_destruction) {
      endwin() if $self->_win;
   }

   sub __set_bg ($win, $background) {
      return unless defined $background;
      my @background = split m{\n}mxs, $background;
      $win->addstr($_, 0, $background[$_]) for 0 .. $#background;
      $win->refresh;
      return;
   } ## end sub __set_bg

   sub set_background ($self, $background) {
      $self->_background(undef);    # disable call in _build__win in case
      __set_bg($self->win, $background);
      $self->_background($background);
      return $self;
   } ## end sub set_background

   sub _build__win ($self) {
      my $win = Curses->new;
      curs_set(0);
      noecho();
      $win->keypad(1);
      __set_bg($win, $self->_background);
      return $win;
   } ## end sub _build__win ($self)

   sub _update_counters ($self) {
      my $game = $self->_game;
      my $win  = $self->_win;
      my $cpf  = $self->_counters;
      while (my ($counter, $ui_data) = each $cpf->%*) {
         my $value = $game->total($counter) // 0;
         $win->addstr($ui_data->@{qw< y x >}, $value);
      }
   } ## end sub _update_counters ($self)

   sub _update ($self, $event) {
      my $game = $self->_game;
      my $win  = $self->_win;
      if   ($event eq 'tick') { $game->tick }
      else                    { $game->update($event) }
      my @positions = $game->positions;
      my $ui_data = $self->_positions;

      while (my ($id, $ud) = each $ui_data->%*) {
         my $is_busy = grep {$_->is_busy}
            map {$game->position($_)}
            ($id, ($ud->{overlaps} // [])->@*);
         my $current = $is_busy ? 'draw' : 'erase';
         next if $current eq ($ud->{previous} //= 'erase');
         $ud->{previous} = $current;
         $win->addstr($ud->@{'y', 'x', $current});
      }

      $self->_update_counters;

      $win->refresh;
   } ## end sub _update

   sub run ($self) {
      my $game = $self->_game;
      my $win   = $self->_win;
      my $alarm = clock_gettime(CLOCK_MONOTONIC);
    DONE:
      while (!$game->is_over) {
       INPUT:
         while ((my $clk = clock_gettime(CLOCK_MONOTONIC)) < $alarm) {

            #if (my @ready = $selector->can_read($alarm - $clk)) {
            #   my $key = $win->getch;
            $win->timeout(int(1000 * ($alarm - $clk)));
            my ($ch, $key) = $win->getch;
            if (defined($key //= $ch)) {
               next INPUT if $key eq ERR;
               last DONE               if $key eq 'q' || $key eq "\x{1b}";
               $self->_update('left')  if $key eq 'a' || $key eq '260';
               $self->_update('right') if $key eq 'l' || $key eq '261';
            } ## end if (defined($key //= $ch...))
            else {
               last DONE;
            }
         } ## end INPUT: while ((my $clk = clock_gettime...))
         $self->_update('tick');
         $alarm += FRAME_DURATION;
      } ## end DONE: while (!$game->is_over)
      if ($game->is_over) {
         $win->addstr(3, 20, 'GAME OVER');
         $win->refresh;
         $win->timeout(-1);
         while (my ($ch, $key) = $win->getch) {
            next unless defined($key //= $ch);
            last if $key eq 'q' || $key eq "\x{1b}";
         }
      } ## end if ($game->is_over)
      return;
   } ## end sub run ($self)
} ## end package Game::HandHeld::Interface::Curses

1;
__END__

