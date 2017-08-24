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

test {
  my $c = shift;
  {
    package Test::Hoge1;
    use Carp;
    sub foo {
      croak "abc";
    };
  }
  Promise->resolve->then (sub {
    Test::Hoge1::foo ();
  })->catch (sub {
    my $error = $_[0];
    test {
      like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak';

test {
  my $c = shift;
  {
    package Test::Hoge2;
    sub foo {
      Carp::croak "abc";
    };
  }
  package Test::Hoge3;
  Promise->resolve->then (sub {
    Test::Hoge2::foo ();
  })->catch (sub {
    my $error = $_[0];
    Test::X1::test {
      Test::More::like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__-4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak';

test {
  my $c = shift;
  {
    package Test::Hoge4;
    sub foo {
      Carp::croak "abc";
    };
  }
  package Test::Hoge5;
  our @CARP_NOT = qw(Test::Hoge4);
  Promise->resolve->then (sub {
    Test::Hoge4::foo ();
  })->catch (sub {
    my $error = $_[0];
    Test::X1::test {
      Test::More::like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
    } $c;
    done $c;
    undef $c;
  });
} n => 1, name => 'croak';

test {
  my $c = shift;
  {
    package Test::Hoge6;
    sub foo {
      Carp::croak "abc";
    };
  }
  {
    package Test::Hoge7;
    our @CARP_NOT = qw(Test::Hoge6 Promise);
    sub bar {
      return Promise->resolve->then (sub {
        Test::Hoge6::foo ();
      });
    }
  }
  Test::Hoge7::bar ()->catch (sub {
    my $error = $_[0];
    Test::X1::test {
      Test::More::like $error, qr{^abc at \Q@{[__FILE__]}\E line @{[__LINE__+4]}};
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
