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
  my $x = {};
  my $y = {};
  Promise->new (sub {
    eval { die $x };
    test {
      is $@, $x, '$@ before resolve';
    } $c;
    $_[0]->($y);
    test {
      is $@, $x, '$@ after resolve';
    } $c;
  })->then (sub {
    my $e = $_[0];
    test {
      is $e, $y;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 3, name => '$@ and resolve';

test {
  my $c = shift;
  Promise->resolve->then (sub {
    die 0;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $e = $_[0];
    test {
      like $e, qr{^0 at \Q@{[__FILE__]}\E line @{[__LINE__-6]}};
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'throw with false value';

{
  package test::FalseOverloaded;
  use overload '""' => sub { '' }, fallback => 1;
}

test {
  my $c = shift;
  my $v = bless {}, 'test::FalseOverloaded';
  Promise->resolve->then (sub {
    die $v;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $e = $_[0];
    test {
      is $e, $v;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'throw with false object';

test {
  {
    package test::Thenable;
    sub then { Promise->resolve ($_[0]->{value})->then ($_[1]) }
  }
  my $c = shift;
  my $v = {};
  Promise->resolve->then (sub {
    return bless {value => $v}, 'test::Thenable';
  })->then (sub {
    my $r = $_[0];
    test {
      is $r, $v;
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'thenable does not throw';

test {
  {
    package test::ThrowThenable;
    sub then { die $_[0]->{die} }
  }
  my $c = shift;
  my $v = bless {}, 'test::FalseOverloaded';
  Promise->resolve->then (sub {
    return bless {die => $v}, 'test::ThrowThenable';
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $e = $_[0];
    test {
      is $e, $v;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'then throws with false object';

{
  package test::CanThrow;
  sub can { die $_[0]->{die} }
  sub then { }
}

test {
  my $c = shift;
  my $x = {};
  my $v = bless {die => $x}, 'test::CanThrow';
  Promise->new (sub {
    $_[0]->($v);
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $e = $_[0];
    test {
      is $e, $x;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'can throw';

test {
  my $c = shift;
  my $x = bless {}, 'test::FalseOverloaded';
  my $v = bless {die => $x}, 'test::CanThrow';
  Promise->new (sub {
    $_[0]->($v);
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $e = $_[0];
    test {
      is $e, $x;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'can throw false';

run_tests;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
