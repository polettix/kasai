# vim: filetype=perl :
use 5.024;
use warnings;
use Test::More;
use FindBin '$Bin';
#use lib "$Bin/../lib", "$Bin/../local/lib/perl5";
use Path::Tiny;

my $lib = Path::Tiny->new(__FILE__)->parent->parent->child('lib');
my @queue = ($lib);
while (@queue) {
   my $item = shift @queue;
   if ($item->is_dir) {
      push @queue, $item->children;
   }
   elsif ($item =~ m{\.pm\z}mxs) {
      my $module = "$item";
      for ($module) {
         s{\A.*?/?lib/|\.pm\z}{}g;
         s{/}{::}g;
      }
      use_ok($module);
   }
}

done_testing();
