use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

test {
  my $c = shift;

  my $promise = Promise->reject;
  isa_ok $promise, 'Promise';

  $promise->then (sub {
    test {
      ok not 1;
      done $c;
      undef $c;
    } $c;
  }, sub {
    test {
      ok 1;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'reject';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->reject->then (sub {
    $invoked++;
  }, sub {
    $invoked++;
    test {
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
} n => 2, name => 'reject then async';

test {
  my $c = shift;
  Promise->reject->then (undef, sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], undef;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'reject args missing';

test {
  my $c = shift;
  Promise->reject ('hoge')->then (undef, sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], 'hoge';
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'reject args';

test {
  my $c = shift;
  my $p = Promise->new (sub { });
  Promise->reject ($p)->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, $p;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'reject arg is promise';

test {
  my $c = shift;
  my $v1 = {};
  Promise->reject ($v1)->catch (sub {
    my $v = $_[0];
    test {
      is $v, $v1;
    } $c;
    done $c;
    undef $c;
  });
} n => 1;

test {
  my $c = shift;
  my $v1 = {};
  for ($v1) {
    Promise->reject ($_)->catch (sub {
      my $v = $_[0];
      test {
        is $v, $v1;
      } $c;
      done $c;
      undef $c;
    });
  }
} n => 1, name => '$_';

test {
  my $c = shift;
  my $v1 = rand;
  $v1 =~ /\A(.+)\z/;
  Promise->reject ($1)->catch (sub {
    my $v = $_[0];
    test {
      is $v, $v1;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => '$1';

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
