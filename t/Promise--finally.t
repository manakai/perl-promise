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
  my $args;
  my $rv = {};
  my $p = Promise->resolve ($rv)->finally (sub {
    $args = [@_];
    $invoked++;
  });
  isa_ok $p, 'Promise';
  $p->then (sub {
    my $v = $_[0];
    test {
      is $invoked, 1;
      is 0+@$args, 0;
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 4, name => 'finally invoked after fulfilled';

test {
  my $c = shift;

  my $invoked = 0;
  my $args;
  my $rv = {};
  my $p = Promise->resolve ($rv)->finally (sub {
    $args = [@_];
    $invoked++;
    return Promise->resolve (rand);
  })->then (sub {
    my $v = $_[0];
    test {
      is $invoked, 1;
      is 0+@$args, 0;
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 3, name => 'finally invoked and fulfilled after fulfilled';

test {
  my $c = shift;

  my $args;
  my $invoked = 0;
  my $e = {};
  my $p = Promise->reject ($e)->finally (sub {
    $args = [@_];
    $invoked = 1;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $invoked, 1;
      is 0+@$args, 0;
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 3, name => 'finally invoked after rejected';

test {
  my $c = shift;

  my $args;
  my $invoked = 0;
  my $e = {};
  my $p = Promise->reject ($e)->finally (sub {
    $args = [@_];
    $invoked = 1;
    return Promise->resolve (rand);
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $invoked, 1;
      is 0+@$args, 0;
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 3, name => 'finally invoked and fulfilled after rejected';

test {
  my $c = shift;

  my $rv = {};
  my $e = {};
  my $p = Promise->resolve ($rv)->finally (sub {
    die $e;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'finally throwing after fulfilled';

test {
  my $c = shift;

  my $rv = {};
  my $e = {};
  my $p = Promise->resolve ($rv)->finally (sub {
    return Promise->reject ($e);
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'finally rejecting after fulfilled';

test {
  my $c = shift;

  my $rv = {};
  my $e = {};
  my $p = Promise->reject ($rv)->finally (sub {
    die $e;
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'finally throwing after rejected';

test {
  my $c = shift;

  my $rv = {};
  my $e = {};
  my $p = Promise->reject ($rv)->finally (sub {
    return Promise->reject ($e);
  })->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $f = $_[0];
    test {
      is $f, $e;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'finally rejecting after rejected';

test {
  my $c = shift;
  my $rv = {};
  Promise->resolve ($rv)->finally->then (sub {
    my $v = $_[0];
    test {
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'No args';

test {
  my $c = shift;
  my $rv = {};
  Promise->reject ($rv)->finally->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $v = $_[0];
    test {
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'No args (reject)';

test {
  my $c = shift;
  my $rv = {};
  Promise->resolve ($rv)->finally (undef)->then (sub {
    my $v = $_[0];
    test {
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'undef args';

test {
  my $c = shift;
  my $rv = {};
  Promise->resolve ($rv)->finally (rand)->then (sub {
    my $v = $_[0];
    test {
      is $v, $rv;
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'Bad args';

run_tests;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
