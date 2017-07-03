use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

{
  package test::Promise1;
  our @ISA = qw(Promise);
}

test {
  my $c = shift;
  my $p = test::Promise1->new (sub { $_[0]->(12) });
  isa_ok $p, 'test::Promise1';
  $p->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'subclass new';

{
  package test::Promise2;
  our @ISA = qw(Promise);

  sub new ($) {
    my $class = shift;
    return $class->SUPER::new (sub { $_[1]->(31) });
  } # new
}

test {
  my $c = shift;
  my $p = test::Promise2->new;
  isa_ok $p, 'test::Promise2';
  Promise->resolve ($p)->catch (sub {
    my $arg = shift;
    test {
      like $arg, qr{^TypeError: The executor is not invoked or the resolver is not specified at }; # XXX location is within AnyEvent as test::Promise2->new is invoked within Promise->resolve's callback
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'subclass custom new';

test {
  my $c = shift;
  my $p = test::Promise2->new;
  isa_ok $p, 'test::Promise2';
  eval {
    $p->catch (sub {
      test {
        ok 0;
      } $c;
    });
  };
  like $@, qr{^TypeError: The executor is not invoked or the resolver is not specified at \Q@{[__FILE__]}\E line \Q@{[__LINE__-2]}\E};
  done $c;
} n => 2, name => 'subclass custom new invoked within ->then (->catch) does not invoke argument';

test {
  my $c = shift;
  my $p = test::Promise2->new;
  isa_ok $p, 'test::Promise2';
  eval {
    $p->then (sub {
      test {
        ok 0;
      } $c;
    }, sub {
      test {
        ok 0;
      } $c;
    });
  };
  like $@, qr{^TypeError: The executor is not invoked or the resolver is not specified at \Q@{[__FILE__]}\E line \Q@{[__LINE__-2]}\E};
  done $c;
} n => 2, name => 'subclass custom new invoked within ->then does not invoke argument';

test {
  my $c = shift;
  my $p1 = test::Promise1->new (sub { $_[1]->(3) });
  my $p2 = $p1->then;
  isa_ok $p2, 'test::Promise1';
  my $p3 = $p2->catch;
  isa_ok $p3, 'test::Promise1';
  $p3->catch (sub {
    test {
      done $c;
      undef $c;
    } $c;
  })
} n => 2, name => 'subclassed then and catch';

test {
  my $c = shift;
  my $p = test::Promise1->all (['foo', 'bar']);
  isa_ok $p, 'test::Promise1';
  $p->then (sub {
    my $arg = shift;
    test {
      is ref $arg, 'ARRAY';
      is scalar @$arg, 2;
      is $arg->[0], 'foo';
      is $arg->[1], 'bar';
      done $c;
      undef $c;
    } $c;
  });
} n => 5, name => 'subclassed all';

test {
  my $c = shift;
  my $p = test::Promise1->race (['foo', 'bar']);
  isa_ok $p, 'test::Promise1';
  $p->then (sub {
    my $arg = shift;
    test {
      is $arg, 'foo';
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'subclassed race';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
