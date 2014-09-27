use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

test {
  my $c = shift;
  my $invoked = 0;
  Promise->resolve->then (sub {
    test {
      $invoked++;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  }, sub {
    test {
      $invoked++;
      ok 0;
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
} n => 2, name => 'resolve';

test {
  my $c = shift;
  Promise->resolve->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], undef;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args';

test {
  my $c = shift;
  Promise->resolve ("aga\xFA", 31)->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], "aga\xFA";
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args';

test {
  my $c = shift;
  my $value = ["aga\xFA", 31];
  Promise->resolve ($value)->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args';

test {
  my $c = shift;
  my $value = {"aga\xFA" => 31};
  Promise->resolve ($value)->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args';

test {
  my $c = shift;
  my $value = bless {"aga\xFA" => 31}, 'test::Hoge';
  Promise->resolve ($value)->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args';

test {
  my $c = shift;
  my $value = bless {"aga\xFA" => 31, promise_state => 'foo'}, 'test::PromiseLike';
  Promise->resolve ($value)->then (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'resolve args psuedo-promise';

test {
  my $c = shift;
  local @test::PromiseSubclass::ISA = qw(Promise);
  my $value = bless {"aga\xFA" => 31, promise_state => 'foo'}, 'test::PromiseSubclass';
  my $p2 = Promise->resolve ($value);
  isnt $p2, $value;
  my $invoked = 0;
  $p2->then (sub { $invoked++ }, sub { $invoked++ });
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 2, name => 'resolve args promise subclass';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { });
  my $invoked = 0;
  $p1->then (sub { $invoked++ }, sub { $invoked++ });
  my $p2 = Promise->resolve ($p1);
  is $p2, $p1;
  is $invoked, 0;
  done $c;
} n => 2, name => 'resolve promise';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
