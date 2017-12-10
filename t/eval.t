use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

test {
  my $c = shift;
  my $x = {};
  my $y = {};
  Promise->new (sub {
    eval { die $x };
    test {
      is $@, $x, '$@ before resolve';
    } $c;
    $_[0]->($y);
    test {
      is $@, $x, '$@ after resolve';
    } $c;
  })->then (sub {
    my $e = $_[0];
    test {
      is $e, $y;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 3, name => '$@ and resolve';

run_tests;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
