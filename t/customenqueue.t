use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

{
  package test::Promise;
  our @ISA = qw(Promise);
  our @QUEUE;
  sub _enqueue ($$) {
    push @QUEUE, $_[1];
  } # _enqueue
}

test {
  my $c = shift;
  my $p = test::Promise->new (sub { $_[0]->() });
  my $invoked = 0;
  $p->then (sub { $invoked++ });
  is $invoked, 0;
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 1;
  done $c;
} n => 2, name => 'enqueue';

test {
  my $c = shift;
  my $d;
  my $p = test::Promise->new (sub { $d = $_[0] });
  my $invoked = 0;
  $p->then (sub { $invoked++ });
  is $invoked, 0;
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 0;
  $d->();
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 1;
  done $c;
} n => 3, name => 'enqueue';

test {
  my $c = shift;
  my $d;
  my $p = test::Promise->new (sub { $d = $_[0] });
  my $invoked = 0;
  $p->then (sub { $invoked++ })
    ->then (sub { $invoked++ });
  is $invoked, 0;
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 0;
  $d->();
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 2;
  done $c;
} n => 3, name => 'enqueue';

test {
  my $c = shift;
  my $p = test::Promise->new (sub { $_[0]->() });
  my $invoked = 0;
  $p->then (sub { test::Promise->resolve->then (sub { $invoked++ }) });
  is $invoked, 0;
  while (@test::Promise::QUEUE) {
    (shift @test::Promise::QUEUE)->();
  }
  is $invoked, 1;
  done $c;
} n => 2, name => 'enqueue';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
