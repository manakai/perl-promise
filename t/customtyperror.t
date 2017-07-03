use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

{
  package test::Promise;
  our @ISA = qw(Promise);
  use Carp;

  $Promise::CreateTypeError = sub {
    return bless {message => $_[1], location => Carp::shortmess}, 'test::TypeError';
  };

  package test::TypeError;
  use overload '""' => sub { "test::TypeError: $_[0]->{message}" }, fallback => 1;
}

test {
  my $c = shift;
  dies_ok {
    test::Promise->new;
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The executor is not a code reference';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  done $c;
} n => 4, name => 'new with no args';

test {
  my $c = shift;
  my $p = test::Promise->new (sub { $_[0]->() });
  my $p2; $p2 = $p->then (sub { return $p2 });
  $p2->catch (sub {
    my $arg = shift;
    test {
      isa_ok $arg, 'test::TypeError';
      is $arg->{message}, 'SelfResolutionError';
      #$arg->{location}
      done $c;
      undef $c;
    } $c;
  });
} n => 2, name => 'SelfResolutionError';

{
  package test::PromiseWithNew1;
  our @ISA = qw(test::Promise);
  sub new {
    my ($class, $executor) = @_;
    my $self = $class->SUPER::new ($executor);
    $executor->(sub { }, sub { });
    return $self;
  }
}
test {
  my $c = shift;
  my $p = test::PromiseWithNew1->new (sub { $_[0]->() });
  my $invoked = 0;
  dies_ok {
    $p->then (sub { $invoked++ }, sub { $invoked++ });
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The resolver is already specified';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 5, name => 'subclass with _new';

{
  package test::PromiseWithNew2;
  our @ISA = qw(test::Promise);
  sub new {
    my ($class, $executor) = @_;
    $executor->(undef, sub { });
    $executor->(sub { }, sub { });
    my $self = $class->SUPER::new ($executor);
    return $self;
  }
}
test {
  my $c = shift;
  my $p = test::PromiseWithNew2->new (sub { $_[1]->() });
  my $invoked = 0;
  dies_ok {
    $p->then (sub { $invoked++ }, sub { $invoked++ });
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The reject handler is already specified';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 5, name => 'subclass with _new';

{
  package test::PromiseWithNew3;
  our @ISA = qw(test::Promise);
  sub new {
    my ($class, $executor) = @_;
    return $class->SUPER::new (sub { });
  }
}
test {
  my $c = shift;
  my $p = test::PromiseWithNew3->new (sub { $_[1]->() });
  my $invoked = 0;
  dies_ok {
    $p->then (sub { $invoked++ }, sub { $invoked++ });
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The executor is not invoked or the resolver is not specified';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  AE::postpone {
    test {
      is $invoked, 0;
      done $c;
      undef $c;
    } $c;
  };
} n => 5, name => 'subclass with _new';

{
  package test::PromiseWithNew4;
  our @ISA = qw(test::Promise);
  sub new {
    my ($class, $executor) = @_;
    return $class->SUPER::new (sub { $executor->(sub {}, undef) });
  }
}
test {
  my $c = shift;
  dies_ok {
    test::PromiseWithNew4->resolve;
  };
  isa_ok $@, 'test::TypeError';
  is $@->{message}, 'The executor is not invoked or the reject handler is not specified';
  like $@->{location}, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  done $c;
} n => 4, name => 'subclass with _new';

test {
  my $c = shift;
  eval {
    test::Promise->can ('then')->({}, sub {});
  };
  ok not ref $@;
  like $@, qr{Can't locate object method "new" via package "HASH"}; # location is within Promise.pm
  done $c;
} n => 2, name => 'then not promise';

run_tests;

=head1 LICENSE

Copyright 2014-2017 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
