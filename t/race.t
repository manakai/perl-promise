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
  my $p = Promise->race ([]);
  isa_ok $p, 'Promise';
  $p->then (sub {
    ok 0;
    $invoked++;
  }, sub {
    ok 0;
    $invoked++;
  });
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 2, name => 'race empty';

test {
  my $c = shift;
  my $invoked = 0;
  my $p = Promise->race->then (sub {
    ok 0;
    $invoked++;
  }, sub {
    $invoked++;
    my $arg = shift;
    test {
      like $arg, qr{^Can't use an undefined value};
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'race bad arg';

test {
  my $c = shift;
  Promise->race ([
    Promise->new (sub { $_[0]->(12) }),
    Promise->new (sub { $_[0]->(23) }),
  ])->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'race two promises';

test {
  my $c = shift;
  Promise->race ([
    Promise->new (sub { my $d = $_[0]; AE::postpone { $d->(12) } }),
    Promise->new (sub { $_[0]->(23) }),
  ])->then (sub {
    my $arg = shift;
    test {
      is $arg, 23;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'race two promises';

test {
  my $c = shift;
  Promise->race ([
    Promise->new (sub { }),
    Promise->new (sub { $_[0]->(23) }),
  ])->then (sub {
    my $arg = shift;
    test {
      is $arg, 23;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'race two promises';

test {
  my $c = shift;
  Promise->race ([
    Promise->new (sub { $_[1]->(12) }),
    Promise->new (sub { $_[0]->(23) }),
  ])->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'race two promises, failed and succeeded';

test {
  my $c = shift;
  Promise->race ([
    Promise->new (sub { $_[0]->(12) }),
    Promise->new (sub { $_[1]->(23) }),
  ])->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'race two promises, ok and ng';

test {
  my $c = shift;
  my $x = {};
  eval { die $x };
  test {
    is $@, $x;
  } $c;
  my $p = Promise->race ([1, 2]);
  test {
    is $@, $x;
  } $c;
  $p->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => '$@';

run_tests;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
