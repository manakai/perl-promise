use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
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

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
