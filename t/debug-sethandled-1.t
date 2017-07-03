use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

my $warn = '';
$SIG{__WARN__} = sub { $warn .= $_[0] };

test {
  my $c = shift;
  my $p = Promise->reject;
  $p->manakai_set_handled;
  AE::postpone {
    test {
      unlike $warn, qr{Uncaught rejection:};
      done $c;
      undef $c;
    } $c;
  };
} n => 1;

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
