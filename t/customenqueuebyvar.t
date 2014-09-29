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
  package test::package;
  our @CARP_NOT = qw(Promise);
  our @QUEUE;
  $Promise::Enqueue = sub {
    push @QUEUE, $_[1];
  };
}

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[0]->() });
  my $invoked = 0;
  $p->then (sub { $invoked++ });
  is $invoked, 0;
  while (@test::package::QUEUE) {
    (shift @test::package::QUEUE)->();
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
