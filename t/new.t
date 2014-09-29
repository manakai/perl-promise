use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[0]->('hoge') });
  isa_ok $p, 'Promise';
  my $invoked = 0;
  $p->then (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, 'hoge';
      done $c;
      undef $c;
    } $c;
  }, sub { ok 0 });
  is $invoked, 0;
} n => 4, name => 'new ok';

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[1]->('hoge') });
  isa_ok $p, 'Promise';
  my $invoked = 0;
  $p->then (sub { ok 0 }, sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, 'hoge';
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
} n => 4, name => 'new ng';

test {
  my $c = shift;
  my $d;
  my $invoked = 0;
  Promise->new (sub { $d = $_[0]; })->then (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  AE::postpone {
    test {
      is $invoked, 0;
    } $c;
    AE::postpone {
      $d->('ab');
    };
  };
} n => 2, name => 'new ok';

test {
  my $c = shift;
  my $d;
  my $invoked = 0;
  Promise->new (sub { $d = $_[1]; })->catch (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  AE::postpone {
    test {
      is $invoked, 0;
    } $c;
    AE::postpone {
      $d->('ab');
    };
  };
} n => 2, name => 'new ng';

test {
  my $c = shift;
  my $invoked = 0;
  my $p = Promise->new (sub { })->then (sub { $invoked++ }, sub { $invoked++ });
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 1, name => 'new callback not invoked';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->new (sub {
    $_[0]->(12);
    $_[1]->(21);
  })->then (sub {
    my $arg = shift;
    $invoked++;
    test {
      is $invoked, 1;
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  }, sub { ok 0 });
} n => 2, name => 'new callback invoked multiple times';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->new (sub {
    $_[0]->(12);
    $_[0]->(21);
  })->then (sub {
    my $arg = shift;
    $invoked++;
    test {
      is $invoked, 1;
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  }, sub { ok 0 });
} n => 2, name => 'new callback invoked multiple times';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->new (sub {
    $_[1]->(51);
    $_[0]->(12);
    $_[1]->(21);
    $_[1]->(24);
  })->then (sub { ok 0 }, sub {
    my $arg = shift;
    $invoked++;
    test {
      is $invoked, 1;
      is $arg, 51;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'new callback invoked multiple times';

test {
  my $c = shift;
  dies_here_ok {
    Promise->new;
  };
  like $@, qr{^TypeError: };
  done $c;
} n => 2, name => 'new no arg';

test {
  my $c = shift;
  dies_here_ok {
    Promise->new ('hpoge');
  };
  like $@, qr{^TypeError: };
  done $c;
} n => 2, name => 'new bad arg';

test {
  my $c = shift;
  dies_here_ok {
    Promise->new (['hpoge']);
  };
  like $@, qr{^TypeError: };
  done $c;
} n => 2, name => 'new bad arg';

test {
  my $c = shift;
  dies_here_ok {
    Promise->new (sub { die });
  };
  unlike $@, qr{^TypeError};
  done $c;
} n => 2, name => 'new exception in code';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
