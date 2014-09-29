use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;
use AnyEvent;

test {
  my $c = shift;
  my $cv = AE::cv;
  my $invoked = 0;
  Promise->from_cv ($cv)->then (sub {
    my $arg = shift;
    $invoked++;
    test {
      is $invoked, 1;
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
  $cv->send (12);
  is $invoked, 0;
} n => 3, name => 'from_cv';

test {
  my $c = shift;
  my $cv = AE::cv;
  my $invoked = 0;
  Promise->from_cv ($cv)->then (sub {
    my $arg = shift;
    $invoked++;
    test {
      is $invoked, 1;
      is $arg, 321;
      done $c;
      undef $c;
    } $c;
  });
  $cv->send (Promise->new (sub { $_[0]->(321) }));
  is $invoked, 0;
} n => 3, name => 'from_cv promise';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
