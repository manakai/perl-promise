use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Time::HiRes qw(time);
use Test::X1;
use Test::More;
use Promised::Flow;

test {
  my $c = shift;
  my @x;
  (promised_cleanup {
    return Promise->resolve->then (sub { push @x, 4 });
  } Promise->resolve->then (sub {
    push @x, 7;
    return 9;
  }))->then (sub {
    my $return = $_[0];
    test {
      is $return, 9;
      is 0+@x, 2;
      is $x[0], 7;
      is $x[1], 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_cleanup resolved';

test {
  my $c = shift;
  my @x;
  (promised_cleanup {
    push @x, 4;
  } Promise->resolve->then (sub {
    push @x, 7;
    die \9;
  }))->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $$error, 9;
      is 0+@x, 2;
      is $x[0], 7;
      is $x[1], 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_cleanup rejected';

test {
  my $c = shift;
  my @x;
  (promised_cleanup {
    push @x, 4;
    die \6;
  } Promise->resolve->then (sub {
    push @x, 7;
    return 9;
  }))->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $$error, 6;
      is 0+@x, 2;
      is $x[0], 7;
      is $x[1], 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_cleanup resolved then rejected';

test {
  my $c = shift;
  my @x;
  (promised_cleanup {
    push @x, 4;
    die \6;
  } Promise->resolve->then (sub {
    push @x, 7;
    die \9;
  }))->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $$error, 9;
      is 0+@x, 2;
      is $x[0], 7;
      is $x[1], 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_cleanup rejected then rejected';

test {
  my $c = shift;
  my $t1 = time;
  promised_sleep (2)->then (sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 >= 2 - 0.1, "$t2 - $t1 = @{[$t2-$t1]} >= 2";
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_sleep';

test {
  my $c = shift;
  my $t1 = time;
  promised_sleep (0.5)->then (sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 >= 0.5 - 0.1, "$t2 - $t1 = @{[$t2-$t1]} >= 0.5";
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_sleep';

test {
  my $c = shift;
  my $t1 = time;
  promised_sleep (0)->then (sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 >= 0;
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_sleep';

test {
  my $c = shift;
  (promised_timeout {
    return promised_sleep (0.1)->then (sub {
      return 5;
    });
  } 0.2)->then (sub {
    my $result = $_[0];
    test {
      is $result, 5;
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_timeout (not timeout)';

test {
  my $c = shift;
  (promised_timeout {
    return promised_sleep (0.1)->then (sub {
      die \5;
    });
  } 0.2)->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $$error, 5;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_timeout (not timeout but rejected)';

test {
  my $c = shift;
  my $p;
  my $invoked = 0;
  (promised_timeout {
    return $p = promised_sleep (2)->then (sub {
      $invoked++;
    });
  } 1)->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $error, "Timeout (1 s)";
    } $c;
  })->then (sub {
    return $p;
  })->then (sub {
    test {
      is $invoked, 1;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'promised_timeout (timeout)';

test {
  my $c = shift;
  (promised_timeout {
    return promised_sleep (0.1)->then (sub {
      return 5;
    });
  } undef)->then (sub {
    my $result = $_[0];
    test {
      is $result, 5;
    } $c;
  }, sub {
    test { ok 0 } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_timeout (undef timeout)';

test {
  my $c = shift;
  my @item;
  (promised_for {
    my $item = $_[0];
    push @item, $item;
  } [1, 2, 3])->then (sub {
    test {
      is 0+@item, 3;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_for';

test {
  my $c = shift;
  my @item;
  (promised_for {
    my $item = $_[0];
    push @item, $item;
  } [])->then (sub {
    test {
      is 0+@item, 0;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'promised_for';

test {
  my $c = shift;
  my @in = (1, 2, 3);
  my @item;
  (promised_for {
    my $item = $_[0];
    push @item, $item;
    push @in, 4;
  } \@in)->then (sub {
    test {
      is 0+@item, 3;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_for input list modification';

test {
  my $c = shift;
  my @item;
  (promised_for {
    my $item = $_[0];
    push @item, $item;
    die \"Failure" if $item == 2;
  } [1, 2, 3])->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is 0+@item, 2;
      is $item[0], 1;
      is $item[1], 2;
      is $$error, 'Failure';
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_for rejection';

test {
  my $c = shift;
  my @item;
  (promised_for {
    my $item = $_[0];
    if ($item == 2) {
      return Promise->resolve->then (sub { push @item, $item });
    } else {
      push @item, $item;
    }
  } [1, 2, 3])->then (sub {
    test {
      is 0+@item, 3;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_for';

test {
  my $c = shift;
  my @item;
  my @wait;
  (promised_for {
    my $item = $_[0];
    if ($item == 2) {
      push @wait, promised_sleep (1)->then (sub { push @item, $item });
      return undef;
    } else {
      push @item, $item;
    }
  } [1, 2, 3])->then (sub {
    return Promise->all (\@wait);
  })->then (sub {
    test {
      is 0+@item, 3;
      is $item[0], 1;
      is $item[1], 3;
      is $item[2], 2;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 4, name => 'promised_for delayed';

test {
  my $c = shift;
  my $n = 0;
  my @item;
  my $t1 = time;
  (promised_wait_until {
    $n++;
    push @item, $n;
    return Promise->resolve ()->then (sub { return $n > 3 });
  })->then (sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 >= 1 * 3 - 0.1, "$t2 - $t1 = @{[$t2-$t1]} >= 3";
      is 0+@item, 4;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
      is $item[3], 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 6, name => 'promised_wait_until';

test {
  my $c = shift;
  my $n = 0;
  my @item;
  my $t1 = time;
  (promised_wait_until {
    $n++;
    push @item, $n;
    return Promise->resolve ()->then (sub { return $n > 5 });
  } interval => 0.1)->then (sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 >= 0.1 * 5 - 0.1, "$t2 - $t1 = @{[$t2-$t1]} >= 0.5";
      is 0+@item, 6;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
      is $item[3], 4;
      is $item[4], 5;
      is $item[5], 6;
    } $c;
    done $c;
    undef $c;
  });
} n => 8, name => 'promised_wait_until';

test {
  my $c = shift;
  my $n = 0;
  my @item;
  (promised_wait_until {
    $n++;
    push @item, $n;
    die \10 if $n > 3;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is 0+@item, 4;
      is $item[0], 1;
      is $item[1], 2;
      is $item[2], 3;
      is $item[3], 4;
      is $$error, 10;
    } $c;
    done $c;
    undef $c;
  });
} n => 6, name => 'promised_wait_until, rejected';

test {
  my $c = shift;
  my $n = 0;
  my @item;
  my $t1 = time;
  (promised_wait_until {
    $n++;
    push @item, $n;
    return Promise->resolve ()->then (sub { return $n > 10 });
  } timeout => 3)->then (sub {
    test { ok 0 } $c;
  }, sub {
    test {
      my $t2 = time;
      ok $t2 - $t1 < 3 + 2, "$t2 - $t1 = @{[$t2-$t1]} < 3";
      ok 0+@item < 3 + 2, 0+@item;
    } $c;
  })->then (sub {
    done $c;
    undef $c;
  });
} n => 2, name => 'promised_wait_until timeout';

test {
  my $c = shift;
  my $i = 1;
  (promised_map {
    return Promise->resolve ($_[0])->then (sub { return $_[0] * 10 + $i++ });
  } [1, 2, 3])->then (sub {
    my $items = $_[0];
    test {
      is 0+@$items, 3;
      is $items->[0], 11;
      is $items->[1], 22;
      is $items->[2], 33;
      is $i, 4;
    } $c;
    done $c;
    undef $c;
  });
} n => 5, name => 'promised_map';

test {
  my $c = shift;
  my $i = 1;
  (promised_map {
    die "error in map\n" if $_[0] == 3;
    return Promise->resolve ($_[0])->then (sub { return $_[0] * 10 + $i++ });
  } [1, 2, 3])->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $error = $_[0];
    test {
      is $error, "error in map\n";
      is $i, 3;
    } $c;
    done $c;
    undef $c;
  });
} n => 2, name => 'promised_map';

run_tests;

=head1 LICENSE

Copyright 2016 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
