use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;

test {
  my $c = shift;
  my ($d, $e);
  my $p = Promise->new (sub {
    ($d, $e) = @_;
  });
  my $value = undef;
  my $invoked = 0;
  $p->catch (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      $invoked++;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
  $e->($value);
  is $invoked, 0;
} n => 5, name => 'catch rejected';

test {
  my $c = shift;
  my ($d, $e);
  my $p = Promise->new (sub {
    ($d, $e) = @_;
  });
  my $value = undef;
  my $invoked = 0;
  $p->catch (sub {
    $invoked++;
  });
  $d->($value);
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 1, name => 'catch not rejected';

test {
  my $c = shift;
  my ($d, $e);
  my $p = Promise->new (sub {
    ($d, $e) = @_;
  });
  my $value = ['foo', 12];
  my $invoked = 0;
  $p->catch (sub {
    my @args = @_;
    test {
      is scalar @args, 1;
      is $args[0], $value;
      $invoked++;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
  $e->($value);
  is $invoked, 0;
} n => 5, name => 'catch rejected value';

test {
  my $c = shift;
  my $value = [];
  my $p = Promise->new (sub {
    $_[1]->($value);
  });
  my $invoked = 0;
  my @value;
  $p->catch (sub {
    $invoked++;
    push @value, $_[0];
  });
  $p->catch (sub {
    $invoked++;
    push @value, $_[0];
  });
  is $invoked, 0;
  AE::postpone {
    test {
      is $invoked, 2;
      is scalar @value, 2;
      is $value[0], $value;
      is $value[1], $value;
      done $c;
      undef $c;
    } $c;
  };
} n => 5, name => 'multiple catches';

test {
  my $c = shift;
  my $invoked = 0;
  my $value = [];
  Promise->new (sub {
    $_[1]->();
  })->catch (sub {
    die $value;
  })->then (sub {
    $invoked++;
    my $arg = shift;
    test {
      is $arg, $value;
      ok 0;
      done $c;
      undef $c;
    } $c;
  }, sub {
    $invoked++;
    my $arg = shift;
    test {
      is $arg, $value;
      is $invoked, 1;
      done $c;
      undef $c;
    } $c;
  });
  is $invoked, 0;
} n => 3, name => 'catch exception';

test {
  my $c = shift;
  my $value = {};
  Promise->new (sub { $_[1]->() })->catch (sub {
    return $value;
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'catch return value non promise';

test {
  my $c = shift;
  my $p1 = Promise->new (sub { });
  my $p2 = $p1->catch (sub { });
  isa_ok $p2, 'Promise';
  done $c;
} n => 1, name => 'catch object type';

test {
  my $c = shift;
  my $value = [];
  Promise->new (sub { $_[1]->($value) })->catch->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
    } $c;
  });
} n => 1, name => 'catch no arg';

test {
  my $c = shift;
  my $value = [];
  Promise->new (sub { $_[1]->($value) })->catch (124)->then (sub {
    ok 0;
  }, sub {
    my $arg = shift;
    test {
      is $arg, $value;
      done $c;
    } $c;
  });
} n => 1, name => 'catch bad arg';

test {
  my $c = shift;
  Promise->new (sub { $_[1]->(2) })->catch (sub {
    return Promise->new (sub { $_[0]->(12) });
  })->then (sub {
    my $arg = shift;
    test {
      is $arg, 12;
      done $c;
      undef $c;
    } $c;
  });
} n => 1, name => 'catch ng promise';

test {
  my $c = shift;
  Promise->new (sub { $_[1]->(45) })->catch->then (sub {
    test { ok 0 } $c;
  }, sub {
    my $r = $_[0];
    test {
      is $r, 45;
    } $c;
  })->then (sub { done $c; undef $c });
} n => 1, name => 'catch no arg';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
