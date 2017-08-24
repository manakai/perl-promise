use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise;
use Carp;

test {
  my $c = shift;
  Promise->resolve->then (sub {
    die "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'die in fulfilled callback';

test {
  my $c = shift;
  Promise->reject->catch (sub {
    die "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'die in rejected callback';

test {
  my $c = shift;
  Promise->reject->then (sub { }, sub {
    die "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'die in rejected callback';

test {
  my $c = shift;
  Promise->resolve->then (sub {
    croak "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak in fulfilled callback';

test {
  my $c = shift;
  Promise->reject->then (sub { }, sub {
    croak "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak in rejected callback';

test {
  my $c = shift;
  Promise->reject->catch (sub {
    croak "abc";
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak in rejected callback';

test {
  my $c = shift;
  my $foo = sub {
    croak "abc";
  };
  Promise->resolve->then (sub {
    $foo->();
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak';

test {
  my $c = shift;
  my $foo = sub {
    croak "abc";
  };
  my $bar = sub {
    return shift->then (sub {
      $foo->();
    });
  };
  $bar->(Promise->resolve)->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-5]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak';

run_tests;

=head1 LICENSE

Copyright 2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
