use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::Dies;
use Test::More;
use Promise;

test {
  my $c = shift;
  my $value = sub {};
  my $invoked = 0;
  Promise->new (sub {
    $_[0]->($value);
  })->then (sub {
    $invoked++;
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
    } $c;
  }, sub {
    $invoked++;
    ok 0;
  });
  AE::postpone {
    test {
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  };
  is $invoked, 0;
} n => 4, name => 'then ok';

test {
  my $c = shift;
  my $value = sub {};
  my $invoked = 0;
  Promise->new (sub {
    $_[1]->($value);
  })->then (sub {
    $invoked++;
    ok 0;
  }, sub {
    $invoked++;
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
    } $c;
  });
  AE::postpone {
    test {
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  };
  is $invoked, 0;
} n => 4, name => 'then not ok';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->new (sub {
    $_[0]->();
  })->then->then (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, undef;
      done $c;
      undef $c;
    } $c;
  }, sub {
    ok 0;
  });
} n => 2, name => 'then no args ok';

test {
  my $c = shift;
  my $invoked = 0;
  Promise->new (sub {
    $_[1]->();
  })->then->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, undef;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'then no args not ok';

test {
  my $c = shift;
  my $invoked = 0;
  my $value = \"foo";
  Promise->new (sub {
    $_[0]->($value);
  })->then->then (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  }, sub {
    ok 0;
  });
} n => 2, name => 'then no args ok';

test {
  my $c = shift;
  my $invoked = 0;
  my $value = [];
  Promise->new (sub {
    $_[1]->($value);
  })->then->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'then no args not ok';

test {
  my $c = shift;
  my $invoked = 0;
  my $value = \"foo";
  Promise->new (sub {
    $_[0]->($value);
  })->then ('hoge', 'fuga')->then (sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  }, sub {
    ok 0;
  });
} n => 2, name => 'then bad args ok';

test {
  my $c = shift;
  my $invoked = 0;
  my $value = [];
  Promise->new (sub {
    $_[1]->($value);
  })->then ({}, [])->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      $invoked++;
      is $invoked, 1;
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'then bad args not ok';

test {
  my $c = shift;
  my $value = {};
  my $p = Promise->new (sub { $_[0]->($value) });
  my @value;
  $p->then (sub { push @value, $_[0] });
  $p->then (sub { push @value, $_[0] });
  AE::postpone {
    test {
      is scalar @value, 2;
      is $value[0], $value;
      is $value[1], $value;
      done $c;
      undef $c;
    } $c;
  };
} n => 3, name => 'then multiple ok';

test {
  my $c = shift;
  my $value = {};
  my $p = Promise->new (sub { $_[1]->($value) });
  my @value;
  $p->then (undef, sub { push @value, $_[0] });
  $p->then (undef, sub { push @value, $_[0] });
  AE::postpone {
    test {
      is scalar @value, 2;
      is $value[0], $value;
      is $value[1], $value;
      done $c;
      undef $c;
    } $c;
  };
} n => 3, name => 'then multiple ng';

test {
  my $c = shift;
  my $value = \"foo";
  Promise->new (sub {
    $_[0]->();
  })->then (sub {
    die $value;
  })->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then exception in resolve';

test {
  my $c = shift;
  my $value = \"foo";
  Promise->new (sub {
    $_[1]->();
  })->then (undef, sub {
    die $value;
  })->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then exception in reject';

test {
  my $c = shift;
  my $value = {};
  Promise->new (sub { $_[0]->() })->then (sub {
    return $value;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ok return value non promise';

test {
  my $c = shift;
  my $value = {};
  Promise->new (sub { $_[1]->() })->then (undef, sub {
    return $value;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ng return value non promise';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { });
  my $p2 = $p1->then;
  isa_ok $p2, 'Promise';
  done $c;
} n => 1, name => 'then class';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { $_[0]->('foo') });
  $p1->then (sub {
    my $p2 = Promise->new (sub { $_[0]->('fuga') });
    return $p2;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, 'fuga';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ok return promise ok';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { $_[0]->('foo') });
  $p1->then (sub {
    my $p2 = Promise->new (sub { $_[1]->('fuga') });
    return $p2;
  })->catch (sub {
    my $arg = shift;
    test {
      is $arg, 'fuga';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ok return promise ng';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { $_[0]->('foo') });
  $p1->then (sub {
    return Promise->new (sub { my $d = $_[1]; AE::postpone { $d->('fuga') } });
  })->catch (sub {
    my $arg = shift;
    test {
      is $arg, 'fuga';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ok return promise ng';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { $_[0]->('foo') });
  Promise->new (sub { $_[1]->() })->then (undef, sub {
    return $p1;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, 'foo';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ng return promise ok';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { $_[1]->('foo') });
  Promise->new (sub { $_[1]->() })->then (undef, sub {
    return $p1;
  })->catch (sub {
    my $arg = shift;
    test {
      is $arg, 'foo';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ng return promise ng';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { });
  Promise->new (sub { $_[1]->() })->then (undef, sub {
    die $p1;
  })->catch (sub {
    my $arg = shift;
    test {
      is $arg, $p1;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ng throw promise';

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[0]->('foo') });
  $p->then (sub {
    return $p;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, 'foo';
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'circular then';

test {
  my $c = shift;
  my $p; $p = Promise->new (sub { $_[0]->('foo') })->then (sub {
    return $p;
  });
  $p->then (sub { ok 0 }, sub {
    my $arg = shift;
    test {
      like $arg, qr{^TypeError};
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'circular then';

{
  package test::ThenPromise1;
  our @ISA = qw(Promise);
}
{
  package test::ThenPromise2;
  our @ISA = qw(Promise);
}

test {
  my $c = shift;
  my $p1 = test::ThenPromise1->new (sub { $_[0]->() });
  my $p2 = $p1->then (sub { return test::ThenPromise2->new (sub { $_[0]->(12) }) });
  isa_ok $p2, 'test::ThenPromise1';
  $p2->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'different subclasses';

test {
  my $c = shift;
  dies_ok {
    Promise->can ('then')->({promise_state => 'foo'}, sub {});
  };
  ok not ref $@;
  like $@, qr{^TypeError};
  like $@, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  done $c;
} n => 4, name => 'then not promise';

test {
  my $c = shift;
  eval {
    Promise->can ('then')->((bless {promise_state => 'foo'}, 'foo'), sub {});
  };
  ok not ref $@;
  like $@, qr{^Can't locate object method "new" via package "foo" at }; # location is within Promise.pm
  done $c;
} n => 2, name => 'then promise-like';

test {
  my $c = shift;
  Promise->new (sub { $_[1]->(2) })->then (undef, sub {
    return Promise->new (sub { $_[0]->(12) });
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'then ng promise';

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
