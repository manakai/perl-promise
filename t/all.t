use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

test {
  my $c = shift;
  Promise->all ([])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 0;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'all empty array';

test {
  my $c = shift;
  Promise->all (bless [], 'test::hoge')->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 0;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'all empty blessed array';

test {
  my $c = shift;
  Promise->all->then (sub { ok 0 }, sub {
    my $arg = shift;
    test {
      like $arg, qr{^Can't use an undefined value};
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'all not array';

test {
  my $c = shift;
  Promise->all ('foo')->then (sub { ok 0 }, sub {
    my $arg = shift;
    test {
      like $arg, qr{^Can't use string};
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'all not array';

test {
  my $c = shift;
  Promise->all ([Promise->new (sub { $_[0]->(124) })])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 1;
      is $arg->[0], 124;
      done $c;
      undef $c;
    } $c;
  });
} n => 3, name => 'all a promise ok';

test {
  my $c = shift;
  Promise->all ([Promise->new (sub { $_[1]->(124) })])->catch (sub {
    my $arg = shift;
    test {
      is $arg, 124;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'all a promise ng';

test {
  my $c = shift;
  Promise->all (["not a Promise"])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 1;
      is $arg->[0], 'not a Promise';
      done $c;
      undef $c;
    } $c;
  });
} n => 3, name => 'all not a promise';

test {
  my $c = shift;
  Promise->all ([undef])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 1;
      is $arg->[0], undef;
      done $c;
      undef $c;
    } $c;
  });
} n => 3, name => 'all not a promise';

test {
  my $c = shift;
  Promise->all (["Promise"])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 1;
      is $arg->[0], 'Promise';
      done $c;
      undef $c;
    } $c;
  });
} n => 3, name => 'all has-then but not a promise';

test {
  my $c = shift;
  Promise->all ([Promise->new (sub { $_[0]->(12) }),
                 Promise->new (sub { $_[0]->(42) })])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 2;
      is $arg->[0], 12;
      is $arg->[1], 42;
      done $c;
      undef $c;
    } $c;
  });
} n => 4, name => 'all two promises';

test {
  my $c = shift;
  my ($d, $e);
  Promise->all ([Promise->new (sub { $d = $_[0] }),
                 Promise->new (sub { $e = $_[0] })])->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 2;
      is $arg->[0], 12;
      is $arg->[1], 42;
      done $c;
      undef $c;
    } $c;
  });
  AE::postpone {
    $e->(42);
    AE::postpone { $d->(12) };
  };
} n => 4, name => 'all two promises';

test {
  my $c = shift;
  Promise->all ([Promise->new (sub { $_[1]->(12) }),
                 Promise->new (sub { $_[0]->(42) })])->catch (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'all two promises one rejected';

{
  package test::ThenableButThrow;
  sub then { die "then!" }
}

test {
  my $c = shift;
  Promise->all ([bless {promise_state => ''}, 'test::ThenableButThrow'])->catch (sub {
    my $arg = shift;
    test {
      like $arg, qr[^then!];
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'all thenable but throw';

test {
  my $c = shift;
  my $x = {};
  eval { die $x };
  test {
    is $@, $x;
  } $c;
  my $p = Promise->all ([1, 2]);
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

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
