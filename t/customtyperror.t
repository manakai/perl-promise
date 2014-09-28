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

  sub TypeError ($$) {
    return bless {message => $_[1], location => Carp::shortmess}, 'test::TypeError';
  } # TypeError

  package test::TypeError;
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
  sub _new {
    my ($self, $executor) = @_;
    $executor->(sub { }, sub { });
    return $self->SUPER::_new ($executor);
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
  sub _new {
    my ($self, $executor) = @_;
    $executor->(undef, sub { });
    return $self->SUPER::_new ($executor);
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
  sub _new {
    my ($self, $executor) = @_;
    return $self->SUPER::_new (sub { });
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
  sub _new {
    my ($self, $executor) = @_;
    return $self->SUPER::_new (sub { $executor->(sub {}, undef) });
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
  dies_ok {
    test::Promise->can ('then')->({}, sub {});
  };
  ok not ref $@;
  like $@, qr{^TypeError};
  like $@, qr{ at \Q@{[__FILE__]}\E line \Q@{[__LINE__-4]}\E};
  done $c;
} n => 4, name => 'then not promise';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
