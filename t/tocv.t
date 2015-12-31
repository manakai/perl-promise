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
  my $cv = Promise->resolve->then (sub {
    return 123;
  })->to_cv;
  isa_ok $cv, 'AnyEvent::CondVar';
  $cv->cb (sub {
    my $v = $_[0];
    test {
      is $v->recv, 123;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'to_cv resolved';

test {
  my $c = shift;
  my $cv = Promise->resolve->then (sub {
  })->to_cv;
  isa_ok $cv, 'AnyEvent::CondVar';
  $cv->cb (sub {
    my $v = $_[0];
    test {
      is $v->recv, undef;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'to_cv resolved without value';

test {
  my $c = shift;
  my $cv = Promise->resolve->then (sub {
    die 123;
  })->to_cv;
  isa_ok $cv, 'AnyEvent::CondVar';
  $cv->cb (sub {
    my $v = $_[0];
    test {
      eval { $v->recv };
      ok $@;
      like $@, qr{^123 at \Q@{[__FILE__]}\E line @{[__LINE__ - 8]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 3, name => 'to_cv rejected';

test {
  my $c = shift;
  my $cv = Promise->resolve->then (sub {
    die bless [], 'Test::ToCV::1';
  })->to_cv;
  isa_ok $cv, 'AnyEvent::CondVar';
  $cv->cb (sub {
    my $v = $_[0];
    test {
      eval { $v->recv };
      ok $@;
      isa_ok $@, 'Test::ToCV::1';
    } $c;
    done $c;
    undef $c;
  });
} n => 3, name => 'to_cv rejected object';

test {
  my $c = shift;
  my $p = Promise->resolve->then (sub {
    return 123;
  });
  my $cv1 = $p->to_cv;
  my $cv2 = $p->to_cv;
  isnt $cv2, $cv1;
  done $c;
  undef $c;
} n => 1, name => 'to_cv multiple calls';

run_tests;

=head1 LICENSE

Copyright 2015 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
