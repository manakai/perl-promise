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

test {
  my $c = shift;

  my $v1 = {};
  my $cv = AE::cv;
  $cv->croak ($v1);

  my $p = Promise->from_cv ($cv);
  isa_ok $p, 'Promise';
  $p->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $x = $_[0];
    test {
      is $x, $v1;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => '$cv->croak then from_cv';

test {
  my $c = shift;

  my $v1 = {};
  my $cv = AE::cv;

  my $p = Promise->from_cv ($cv);
  isa_ok $p, 'Promise';
  $p->then (sub {
    test {
      ok 0;
    } $c;
  }, sub {
    my $x = $_[0];
    test {
      is $x, $v1, 'got croaked value';
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });

  $cv->croak ($v1);
} n => 2, name => 'from_cv then $cv->croak';

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
